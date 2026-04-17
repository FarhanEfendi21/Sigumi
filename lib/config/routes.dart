import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/language_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/report/report_screen.dart';
import '../screens/emergency/emergency_contacts_screen.dart';
import '../screens/evacuation/evacuation_screen.dart';
import '../screens/chatbot/chatbot_screen.dart';
import '../screens/education/education_screen.dart';
import '../screens/visual/visual_merapi_screen.dart';
import '../screens/post_disaster/post_disaster_screen.dart';
import '../screens/accessibility/accessibility_screen.dart';
import '../screens/tourism/tourism_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/news/news_detail_screen.dart';
import '../screens/home/zone_detail_screen.dart';
import 'package:sigumi/screens/settings/language_settings_screen.dart';
import '../screens/main_navigation.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String language = '/language';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String map = '/map';
  static const String report = '/report';
  static const String emergency = '/emergency';
  static const String evacuation = '/evacuation';
  static const String chatbot = '/chatbot';
  static const String education = '/education';
  static const String visualMerapi = '/visual-merapi';
  static const String postDisaster = '/post-disaster';
  static const String accessibility = '/accessibility';
  static const String tourism = '/tourism';
  static const String settings = '/settings';
  static const String languageSettings = '/settings/language';
  static const String newsDetail = '/news-detail';
  static const String zoneDetail = '/zone-detail';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    language: (_) => const LanguageScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    main: (_) => const MainNavigation(),
    home: (_) => const HomeScreen(),
    map: (_) => const MapScreen(),
    report: (_) => const ReportScreen(),
    emergency: (_) => const EmergencyContactsScreen(),
    evacuation: (_) => const EvacuationScreen(),
    chatbot: (_) => const ChatbotScreen(),
    education: (_) => const EducationScreen(),
    visualMerapi: (_) => const VisualMerapiScreen(),
    postDisaster: (_) => const PostDisasterScreen(),
    accessibility: (_) => const AccessibilityScreen(),
    tourism: (_) => const TourismScreen(),
    settings: (_) => const SettingsScreen(),
    languageSettings: (_) => const LanguageSettingsScreen(),
    newsDetail: (_) => const NewsDetailScreen(),
    zoneDetail: (_) => const ZoneDetailScreen(),
  };
}
