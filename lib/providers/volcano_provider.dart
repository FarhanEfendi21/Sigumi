import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../models/user_model.dart';
import '../models/volcano_model.dart';
import '../services/location_service.dart';

class VolcanoProvider extends ChangeNotifier {
  VolcanoModel _volcano = VolcanoModel.mockMerapi();
  final List<NewsItem> _newsItems = NewsItem.mockNews();
  UserModel? _currentUser;
  String _language = 'id';
  double _fontSize = 1.0;
  bool _highContrast = false;
  bool _audioGuidance = false;
  bool _isOffline = false;

  VolcanoModel get volcano => _volcano;
  List<NewsItem> get newsItems => _newsItems;
  UserModel? get currentUser => _currentUser;
  String get language => _language;
  double get fontSize => _fontSize;
  bool get highContrast => _highContrast;
  bool get audioGuidance => _audioGuidance;
  bool get isOffline => _isOffline;

  double get distanceFromMerapi => LocationService.getDistanceFromMerapi();
  String get distanceLabel => LocationService.getDistanceLabel();
  String get zoneLabel => LocationService.getZoneLabel();
  int get zoneLevel => LocationService.getZoneLevel();

  void setUser(UserModel user) {
    _currentUser = user;
    _language = user.language;
    _fontSize = user.fontSize;
    _highContrast = user.highContrast;
    _audioGuidance = user.audioGuidance;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  void setAudioGuidance(bool value) {
    _audioGuidance = value;
    notifyListeners();
  }

  void toggleOffline() {
    _isOffline = !_isOffline;
    notifyListeners();
  }

  void updateVolcanoStatus(int level, String description) {
    _volcano = VolcanoModel(
      id: _volcano.id,
      name: _volcano.name,
      latitude: _volcano.latitude,
      longitude: _volcano.longitude,
      elevation: _volcano.elevation,
      statusLevel: level,
      statusDescription: description,
      lastUpdate: DateTime.now(),
      lastEruption: _volcano.lastEruption,
      recentActivities: _volcano.recentActivities,
      temperature: _volcano.temperature,
      windDirection: _volcano.windDirection,
      windSpeed: _volcano.windSpeed,
    );
    notifyListeners();
  }
}
