import 'package:flutter_test/flutter_test.dart';
import 'package:sigumi/models/hiking_weather.dart';

void main() {
  group('HikingWeatherForecast timezone metadata', () {
    test('preserves WIB metadata for Merapi forecasts and cache', () {
      final forecast = HikingWeatherForecast.fromJson({
        'area': {
          'adm4': '34.04.17.2005',
          'name': 'Umbulharjo, Cangkringan, Sleman',
          'timezone': 'WIB',
          'utc_offset_hours': 7,
        },
        'analysis_date': '2026-10-28T18:00:00Z',
        'fetched_at': '2026-10-28T18:10:00Z',
        'forecast': const [],
        'warnings': const [],
      });

      expect(forecast.areaName, 'Umbulharjo, Cangkringan, Sleman');
      expect(forecast.timezoneLabel, 'WIB');
      expect(forecast.utcOffsetHours, 7);

      final cachedArea = forecast.toJson()['area'] as Map<String, dynamic>;
      expect(cachedArea['timezone'], 'WIB');
      expect(cachedArea['utc_offset_hours'], 7);
    });

    test('keeps legacy weather cache compatible as WITA', () {
      final forecast = HikingWeatherForecast.fromJson({
        'area': 'Sebudi, Selat, Karangasem',
        'analysis_date': '2026-10-28T18:00:00Z',
        'fetched_at': '2026-10-28T18:10:00Z',
        'forecast': const [],
        'warnings': const [],
      });

      expect(forecast.areaName, 'Sebudi, Selat, Karangasem');
      expect(forecast.timezoneLabel, 'WITA');
      expect(forecast.utcOffsetHours, 8);
    });
  });
}
