import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/in_app_notification.dart';

// Top-level function untuk menangani pesan saat app di Background atau Terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM-BG] Menerima pesan latar belakang: ${message.messageId}');
}

class NotificationService {
  static const String _prefKey = 'notifications_enabled';

  final ValueNotifier<bool> isEnabledNotifier = ValueNotifier<bool>(true);
  bool get isEnabled => isEnabledNotifier.value;

  NotificationService._() {
    _loadPreference();
  }
  static final NotificationService instance = NotificationService._();

  Function(String? volcanoId)? _onNotificationClick;

  /// Memuat status aktif notifikasi dari SharedPreferences
  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_prefKey);
      if (val != null) {
        isEnabledNotifier.value = val;
      }
    } catch (e) {
      debugPrint('[NotificationService] Error loading pref: $e');
    }
  }

  /// Mengaktifkan atau menonaktifkan notifikasi secara real-time
  Future<void> setEnabled(bool value) async {
    isEnabledNotifier.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (e) {
      debugPrint('[NotificationService] Error saving pref: $e');
    }

    if (value) {
      await requestPermission();
    } else {
      try {
        await _localNotifications.cancelAll();
      } catch (e) {
        debugPrint('[NotificationService] Error cancelling notifications: $e');
      }
    }
    debugPrint('[NotificationService] Notifikasi ${value ? "DIAKTIFKAN" : "DINONAKTIFKAN"} realtime.');
  }

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

      // 2. Inisialisasi plugin notifikasi lokal (untuk pop-up saat aplikasi sedang dibuka)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
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
        // Registrasi background handler
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Listener saat app sedang Foreground (sedang aktif digunakan)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (!isEnabled) {
            debugPrint('[FCM-FG] Notifikasi dilewati (user menonaktifkan notifikasi)');
            return;
          }
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

  bool _hasRequestedPermission = false;

  /// Meminta izin notifikasi ke pengguna (Android 13+ & iOS).
  /// Dipanggil dari HomeScreen setelah UI siap & Activity Android stabil,
  /// menghindari crash NullPointerException saat app baru di-install.
  Future<bool> requestPermission() async {
    // Guard: skip hanya jika sudah granted sebelumnya
    if (_hasRequestedPermission) return _hasRequestedPermission;

    try {
      bool granted = false;

      if (!_isInitialized) {
        await initialize();
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Step 1: Minta izin POST_NOTIFICATIONS via flutter_local_notifications (Android 13+)
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final bool? localGranted =
              await androidPlugin.requestNotificationsPermission();
          granted = localGranted ?? false;
        }

        // Step 2: Minta izin FCM agar Firebase dapat mengirim notifikasi
        // Wajib di Android — tanpa ini FCM tidak akan deliver pesan
        final messaging = _fcm;
        if (messaging != null) {
          final settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          final fcmGranted = settings.authorizationStatus ==
                  AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
          // Gunakan hasil FCM jika local plugin gagal deteksi
          granted = granted || fcmGranted;
        }
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        // Khusus iOS Push Notifications
        final messaging = _fcm;
        if (messaging != null) {
          final settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            criticalAlert: true,
          );
          granted = settings.authorizationStatus ==
                  AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
        }
      }

      // Tandai sudah request HANYA jika granted, agar bisa retry jika ditolak
      if (granted) _hasRequestedPermission = true;

      // Ambil dan simpan token FCM secara background tanpa memblokir alur UI izin lainnya
      unawaited(() async {
        try {
          final token = await getDeviceToken();
          if (token != null) {
            await saveTokenToSupabase(token);
          }
        } catch (e) {
          debugPrint('[FCM] Background token sync error: $e');
        }
      }());

      return granted;
    } catch (e) {
      debugPrint('[NotificationService] ⚠️ Gagal meminta izin notifikasi: $e');
      return false;
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
    if (!isEnabled) {
      debugPrint('[NotificationService] Notifikasi dilewati (user menonaktifkan notifikasi)');
      return;
    }

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
      final prefs = await SharedPreferences.getInstance();
      final colorBlindMode = prefs.getString('color_blind_mode') ?? 'normal';
      final statusColor = _getStatusColor(level, colorBlindMode: colorBlindMode);

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
      final prefs = await SharedPreferences.getInstance();
      final colorBlindMode = prefs.getString('color_blind_mode') ?? 'normal';
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _hikingChannelId,
        _hikingChannelName,
        channelDescription: _hikingChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        icon: '@mipmap/launcher_icon',
        color: colorBlindMode == 'deuteranopia'
            ? const Color(0xFF0077BB)
            : const Color(0xFF16A34A),
        visibility: NotificationVisibility.public,
        showWhen: true,
        usesChronometer: true,
        chronometerCountDown: false,
      );

      final NotificationDetails details = NotificationDetails(
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

  Color _getStatusColor(int level, {String colorBlindMode = 'normal'}) {
    switch (level) {
      case 4:
        return const Color(0xFFDC2626); // Awas
      case 3:
        return const Color(0xFFEA580C); // Siaga
      case 2:
        return const Color(0xFFD97706); // Waspada
      default:
        return colorBlindMode == 'deuteranopia'
            ? const Color(0xFF0077BB)
            : const Color(0xFF059669); // Normal
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

  /// Simpan atau perbarui token ke tabel `user_notification_preferences` Supabase.
  /// Jika user belum login, token disimpan tanpa user_id dan akan di-update
  /// via [syncTokenAfterLogin] setelah user berhasil login.
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
      debugPrint('[FCM] ✅ Token berhasil disinkronkan ke Supabase'
          '${currentUserId != null ? " (user: $currentUserId)" : " (guest)"}');
    } catch (e) {
      debugPrint('[FCM] ⚠️ Gagal sinkronisasi token ke Supabase: $e');
    }
  }

  /// Panggil setelah user login agar token FCM yang sudah ada
  /// di-link ke akun yang baru saja masuk.
  Future<void> syncTokenAfterLogin(String userId) async {
    try {
      final token = await getDeviceToken();
      if (token != null) {
        await saveTokenToSupabase(token, userId: userId);
        debugPrint('[FCM] ✅ Token di-link ke user $userId setelah login');
      }
    } catch (e) {
      debugPrint('[FCM] ⚠️ Gagal sync token setelah login: $e');
    }
  }
}
