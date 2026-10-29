import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hiking_weather.dart';

class HikingWeatherService {
  static const _cachePrefix = 'hiking_weather_cache_v1_';

  Future<HikingWeatherForecast?> loadCached(String region) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix${_normalizeRegion(region)}');
    if (raw == null) return null;
    try {
      return HikingWeatherForecast.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      ).withStale(true);
    } catch (_) {
      await prefs.remove('$_cachePrefix${_normalizeRegion(region)}');
      return null;
    }
  }

  Future<HikingWeatherForecast> load({
    required double latitude,
    required double longitude,
    required String cacheRegion,
  }) async {
    final normalizedRegion = _normalizeRegion(cacheRegion);
    final key = '$_cachePrefix$normalizedRegion';
    final prefs = await SharedPreferences.getInstance();
    HikingWeatherForecast? cached;
    final rawCache = prefs.getString(key);
    if (rawCache != null) {
      try {
        cached = HikingWeatherForecast.fromJson(
          jsonDecode(rawCache) as Map<String, dynamic>,
        );
      } catch (_) {
        await prefs.remove(key);
      }
    }

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'hiking-weather',
        body: {
          'action': 'weather',
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response.status < 200 ||
          response.status >= 300 ||
          response.data is! Map) {
        throw const FormatException('Respons cuaca tidak valid.');
      }
      final result = HikingWeatherForecast.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      await prefs.setString(key, jsonEncode(result.toJson()));
      return result;
    } catch (_) {
      if (cached != null) return cached.withStale(true);
      rethrow;
    }
  }

  String _normalizeRegion(String region) {
    final normalized = region.trim().toLowerCase();
    if (normalized.contains('merapi')) return 'merapi';
    if (normalized.contains('lombok') || normalized.contains('rinjani')) {
      return 'lombok';
    }
    if (normalized.contains('bali') || normalized.contains('agung')) {
      return 'bali';
    }
    return normalized;
  }
}
