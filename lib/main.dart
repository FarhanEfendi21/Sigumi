import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/volcano_provider.dart';
import 'providers/tourism_provider.dart';
import 'services/location_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Matikan pengambilan font runtime untuk memaksa penggunaan aset lokal
  GoogleFonts.config.allowRuntimeFetching = false;

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
        ChangeNotifierProvider(create: (_) => VolcanoProvider()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => TourismProvider()),
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
