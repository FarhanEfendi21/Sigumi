import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/in_app_notification.dart';

// Top-level function untuk menangani pesan saat app di Background atau Terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM-BG] Menerima pesan latar belakang: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Function(String? volcanoId)? _onNotificationClick;

  FirebaseMessaging? _fcmInstance;
  FirebaseMessaging? get _fcm {
    try {
      _fcmInstance ??= FirebaseMessaging.instance;
      return _fcmInstance;
    } catch (e) {
      debugPrint('[FCM] Firebase Messaging belum siap atau tidak didukung: $e');
      return null;
    }
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'mitigation_alerts';
  static const String channelName = 'Peringatan Mitigasi Bencana';
  static const String channelDescription =
      'Notifikasi darurat peringatan dini perubahan level aktivitas gunung api.';

  // Channel khusus untuk foreground service tracking pendakian (ongoing, silent)
  static const String _hikingChannelId = 'hiking_tracking';
  static const String _hikingChannelName = 'Tracking Pendakian';
  static const String _hikingChannelDescription =
      'Notifikasi aktif saat SIGUMI sedang merekam jalur pendakian. GPS tetap aktif meski layar mati.';

  /// ID tetap untuk notifikasi sticky tracking pendakian
  static const int _hikingNotificationId = 9001;


  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inisialisasi awal notifikasi
  Future<void> initialize({Function(String? volcanoId)? onNotificationClick}) async {
    _onNotificationClick = onNotificationClick;
    if (_isInitialized) return;

    try {
      // 1. Setup Notification Channel khusus Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Channel khusus hiking tracking — silent, ongoing
      const AndroidNotificationChannel hikingChannel =
          AndroidNotificationChannel(
        _hikingChannelId,
        _hikingChannelName,
        description: _hikingChannelDescription,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.createNotificationChannel(hikingChannel);

      // Wajib untuk Android 13+ (API 33+) agar dialog izin notifikasi muncul
      await androidPlugin?.requestNotificationsPermission();

      // 2. Inisialisasi plugin notifikasi lokal (untuk pop-up saat aplikasi sedang dibuka)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && onNotificationClick != null) {
            onNotificationClick(response.payload);
          }
        },
      );

      // 3. Setup Firebase Cloud Messaging jika didukung di platform ini
      final messaging = _fcm;
      if (messaging != null) {
        // Minta izin ke pengguna (Android 13+ & iOS)
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          criticalAlert: true, // Prioritas tinggi untuk mitigasi bencana
        );
        debugPrint('[FCM] Status izin pengguna: ${settings.authorizationStatus}');

        // Registrasi background handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Listener saat app sedang Foreground (sedang aktif digunakan)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM-FG] Notifikasi masuk: ${message.notification?.title}');
          showLocalNotification(
            title: message.notification?.title ?? 'Peringatan Status Gunung',
            body: message.notification?.body ?? '',
            payload: message.data['volcano_id'],
          );
        });

        // Listener ketika notifikasi di-tap dari background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final volcanoId = message.data['volcano_id'];
          if (volcanoId != null && onNotificationClick != null) {
            onNotificationClick(volcanoId);
          }
        });

        // Pantau token refresh otomatis
        messaging.onTokenRefresh.listen((newToken) {
          debugPrint('[FCM] Token diperbarui: $newToken');
          saveTokenToSupabase(newToken);
        });
      }

      _isInitialized = true;
      debugPrint('[NotificationService] ✅ Inisialisasi notifikasi berhasil');
    } catch (e) {
      debugPrint('[NotificationService] ⚠️ Gagal inisialisasi notifikasi: $e');
    }
  }

  /// Menampilkan banner notifikasi dengan hierarki tipografi clean & minimalis
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int level = 2,
    String? volcanoName,
  }) async {
    // 1. Tampilkan In-App floating banner jika app sedang aktif di layar
    try {
      InAppNotification.show(
        title: title,
        body: body,
        level: level,
        volcanoName: volcanoName,
        onTap: () {
          if (payload != null && _onNotificationClick != null) {
            _onNotificationClick!(payload);
          }
        },
      );
    } catch (e) {
      debugPrint('[NotificationService] In-App banner skipped: $e');
    }

    // 2. Notifikasi sistem (Android Notification Drawer & Heads-up)
    try {
      final statusColor = _getStatusColor(level);

      final bigTextStyle = BigTextStyleInformation(
        body,
        contentTitle: '<b>$title</b>',
        summaryText: 'Peringatan Mitigasi • PVMBG',
        htmlFormatContentTitle: true,
        htmlFormatBigText: true,
      );

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        color: statusColor,
        styleInformation: bigTextStyle,
        playSound: true,
        enableVibration: true,
        ticker: title,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Gagal menampilkan notifikasi lokal: $e');
    }
  }

  /// Tampilkan notifikasi sticky foreground service saat tracking pendakian aktif.
  /// Notifikasi ini mencegah Android mematikan GPS saat layar HP dikunci.
  Future<void> showHikingForegroundNotification({
    String title = 'Tracking Pendakian Aktif',
    String body = 'Sigumi sedang merekam jalur pendakian',
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _hikingChannelId,
        _hikingChannelName,
        channelDescription: _hikingChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        icon: '@mipmap/launcher_icon',
        color: Color(0xFF16A34A),
        visibility: NotificationVisibility.public,
        showWhen: true,
        usesChronometer: true,
        chronometerCountDown: false,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      // flutter_local_notifications v22+ gunakan named parameters
      await _localNotifications.show(
        id: _hikingNotificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
      debugPrint('[NotificationService] ✅ Hiking foreground notification ditampilkan');
    } catch (e) {
      debugPrint('[NotificationService] ⚠️ Gagal tampilkan hiking notification: $e');
    }
  }

  /// Hapus notifikasi sticky tracking pendakian saat sesi selesai.
  Future<void> cancelHikingForegroundNotification() async {
    try {
      // flutter_local_notifications v22+ gunakan named parameters
      await _localNotifications.cancel(id: _hikingNotificationId);
      debugPrint('[NotificationService] ✅ Hiking foreground notification dihapus');
    } catch (e) {
      debugPrint('[NotificationService] ⚠️ Gagal hapus hiking notification: $e');
    }
  }

  Color _getStatusColor(int level) {
    switch (level) {
      case 4:
        return const Color(0xFFDC2626); // Awas
      case 3:
        return const Color(0xFFEA580C); // Siaga
      case 2:
        return const Color(0xFFD97706); // Waspada
      default:
        return const Color(0xFF059669); // Normal
    }
  }

  /// Ambil Token FCM unik dari perangkat ini
  Future<String?> getDeviceToken() async {
    try {
      return await _fcm?.getToken();
    } catch (e) {
      debugPrint('[FCM] Gagal mengambil token perangkat: $e');
      return null;
    }
  }

  /// Simpan atau perbarui token ke tabel `user_notification_preferences` Supabase
  Future<void> saveTokenToSupabase(String token, {String? userId}) async {
    try {
      final client = Supabase.instance.client;
      final currentUserId = userId ?? client.auth.currentUser?.id;

      await client.from('user_notification_preferences').upsert(
        {
          'fcm_token': token,
          if (currentUserId != null) 'user_id': currentUserId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
      debugPrint('[FCM] ✅ Token berhasil disinkronkan ke Supabase');
    } catch (e) {
      debugPrint('[FCM] ⚠️ Gagal sinkronisasi token ke Supabase: $e');
    }
  }
}
