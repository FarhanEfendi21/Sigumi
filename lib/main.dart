import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/volcano_provider.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dzjannijekjtmfakbals.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR6amFubmlqZWtqdG1mYWtiYWxzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NDY2MzIsImV4cCI6MjA4OTQyMjYzMn0.x3yEI_PNCT0aX7r8YQrGg5nID6URfsP3wqHuFnYO9Ww',
  );

  await LocationService.fetchUserLocation();

  runApp(
    ChangeNotifierProvider(
      create: (_) => VolcanoProvider(),
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
        return MaterialApp(
          title: 'SIGUMI',
          debugShowCheckedModeBanner: false,
          theme: SigumiTheme.lightTheme,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(provider.fontSize),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}