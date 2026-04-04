import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/volcano_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
