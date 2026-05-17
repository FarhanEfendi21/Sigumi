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
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';

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

class SigumiApp extends StatelessWidget {
  const SigumiApp({super.key});

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
              child: child!,
            );
          },
        );
      },
    );
  }
}
