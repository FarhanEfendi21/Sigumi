import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hiking_weather.dart';

/// Penyebab gagal memuat prakiraan cuaca terbaru.
enum HikingWeatherFailure {
  /// Koordinat di luar radius area prakiraan pendakian (backend HTTP 404).
  outsideArea,

  /// Jaringan, server, atau format respons bermasalah.
  unavailable,
}

/// Dilempar [HikingWeatherService.load] saat data terbaru gagal dimuat.
/// [fallback] berisi data tersimpan (ditandai stale) bila tersedia.
class HikingWeatherException implements Exception {
  const HikingWeatherException(this.failure, {this.fallback, this.cause});

  final HikingWeatherFailure failure;
  final HikingWeatherForecast? fallback;
  final Object? cause;

  @override
  String toString() => 'HikingWeatherException($failure, cause: $cause)';
}

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
    } catch (error) {
      throw HikingWeatherException(
        _classifyFailure(error),
        fallback: cached?.withStale(true),
        cause: error,
      );
    }
  }

  HikingWeatherFailure _classifyFailure(Object error) {
    if (error is FunctionException && error.status == 404) {
      // Bedakan dari 404 gateway (function belum dideploy) lewat pesan backend.
      final details = error.details;
      final message =
          details is Map ? details['error']?.toString() : details?.toString();
      if (message != null && message.toLowerCase().contains('outside')) {
        return HikingWeatherFailure.outsideArea;
      }
    }
    return HikingWeatherFailure.unavailable;
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
