import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'services/cloud_llm_service.dart';
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

  // Inisialisasi Cloud LLM (Ollama + Gemma 4) untuk chatbot.
  // Jika server tidak dikonfigurasi, chatbot tetap berjalan dengan NLP lokal saja.
  if (OllamaConfig.isConfigured) {
    CloudLlmService.init(
      baseUrl: OllamaConfig.baseUrl,
      modelName: OllamaConfig.modelName,
      apiKey: OllamaConfig.apiKey,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VolcanoProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
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
    
    if (state == AppLifecycleState.paused) {
      debugPrint('[AppLifecycle] ⏸️ App in Background -> Disabling Voice Assistant');
      assistantProvider.disable();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[AppLifecycle] ▶️ App Resumed -> Enabling Voice Assistant');
      // If language was set before, re-enable it. But we just call enable()
      // Note: enable() only works if model is loaded
      assistantProvider.enable();
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
