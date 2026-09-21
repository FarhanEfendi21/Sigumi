import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/globals.dart';
import 'providers/volcano_provider.dart';
import 'providers/tourism_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/news_provider.dart';
import 'providers/assistant_provider.dart';
import 'services/location_service.dart';
import 'services/hiking_tracking_service.dart';
import 'services/cloud_llm_service.dart';
import 'services/vibration_alert_service.dart';
import 'config/ollama_config.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/assistant_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Izinkan Google Fonts mengambil font fallback (Noto Sans) saat runtime
  // agar karakter emoji dan aksara daerah tampil dengan benar di Flutter Web.
  // Font utama (Plus Jakarta Sans) tetap menggunakan aset lokal.
  GoogleFonts.config.allowRuntimeFetching = true;

  // Inisialisasi Supabase (skip jika config belum diisi)
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Inisialisasi Firebase & Layanan Notifikasi Mitigasi Real-Time
  try {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await NotificationService.instance.initialize(
        onNotificationClick: (volcanoId) {
          debugPrint('[Notification] Tap notifikasi gunung ID: $volcanoId');
        },
      );
    }
  } catch (e) {
    debugPrint('[Firebase] Inisialisasi notifikasi error: $e');
  }

  // Inisialisasi Cloud LLM (Ollama + Gemma 4) untuk chatbot.
  // Jika server tidak dikonfigurasi, chatbot tetap berjalan dengan NLP lokal saja.
  if (OllamaConfig.isConfigured) {
    CloudLlmService.init(
      baseUrl: OllamaConfig.baseUrl,
      modelName: OllamaConfig.modelName,
      user: OllamaConfig.ollamaUser,
      pass: OllamaConfig.ollamaPass,
    );
  }

  // Inisialisasi Vibration Alert Service (getar saat radius 5 km dari puncak)
  await VibrationAlertService().initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VolcanoProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(
          create: (_) => HikingTrackingService(locationService: LocationService()),
        ),
        ChangeNotifierProvider(create: (_) => TourismProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => GlobalAssistantProvider()),
      ],
      child: const SigumiApp(),
    ),
  );
}

class SigumiApp extends StatefulWidget {
  const SigumiApp({super.key});

  @override
  State<SigumiApp> createState() => _SigumiAppState();
}

class _SigumiAppState extends State<SigumiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final assistantProvider = Provider.of<GlobalAssistantProvider>(context, listen: false);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('[AppLifecycle] ⏸️ App Inactive/Background -> Pausing Voice Assistant');
      assistantProvider.pauseForBackground();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[AppLifecycle] ▶️ App Resumed -> Resuming Voice Assistant (if enabled)');
      assistantProvider.resumeFromBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        return ShadApp(
          navigatorKey: globalNavigatorKey,
          title: 'SIGUMI',
          debugShowCheckedModeBanner: false,
          materialThemeBuilder: (context, theme) {
            return SigumiTheme.lightTheme;
          },
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(provider.fontSize)),
              child: Stack(
                textDirection: TextDirection.ltr,
                children: [
                  if (child != null) child,
                  // Tampilkan overlay voice assistant secara global
                  const Directionality(
                    textDirection: TextDirection.ltr,
                    child: SigumiAssistantOverlay(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
