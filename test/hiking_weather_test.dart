import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/models/hiking_weather.dart';
import 'package:sigumi/providers/volcano_provider.dart';
import 'package:sigumi/widgets/hiking_weather_card.dart';

class _FakeWeatherVolcanoProvider extends ChangeNotifier
    implements VolcanoProvider {
  @override
  String get language => 'id';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

    test('synthesizes Severe warning when forecast slot has Hujan Lebat or Hujan Petir and CAP warnings are empty', () {
      final forecast = HikingWeatherForecast.fromJson({
        'area': {
          'adm4': '52.03.15.2002',
          'name': 'Sembalun Lawang, Lombok Timur',
          'timezone': 'WITA',
          'utc_offset_hours': 8,
        },
        'analysis_date': '2026-11-18T06:00:00Z',
        'fetched_at': '2026-11-18T06:10:00Z',
        'forecast': const [
          {
            'utc_datetime': '2026-11-18T06:00:00Z',
            'local_datetime': '2026-11-18T14:00:00',
            'temperature_c': 19,
            'humidity_percent': 92,
            'condition': 'Hujan Lebat',
            'wind_kmh': 28,
            'wind_direction': 'W',
          },
        ],
        'warnings': const [],
      });

      expect(forecast.forecasts.first.isSevereWeather, isTrue);
      expect(forecast.effectiveWarnings, hasLength(1));
      expect(forecast.effectiveWarnings.first.severity, 'Severe');
      expect(forecast.effectiveWarnings.first.headline, contains('Hujan Lebat'));
      expect(forecast.effectiveWarnings.first.description, contains('Sembalun Lawang'));
    });

    test('synthesizes Moderate warning for Hujan Sedang and returns empty for normal weather', () {
      final moderateForecast = HikingWeatherForecast.fromJson({
        'area': 'Sebudi, Selat, Karangasem',
        'fetched_at': '2026-11-18T06:10:00Z',
        'forecast': const [
          {
            'utc_datetime': '2026-11-18T06:00:00Z',
            'local_datetime': '2026-11-18T14:00:00',
            'temperature_c': 21,
            'humidity_percent': 88,
            'condition': 'Hujan Sedang',
            'wind_kmh': 15,
            'wind_direction': 'SW',
          },
        ],
        'warnings': const [],
      });

      expect(moderateForecast.forecasts.first.isModerateHazardWeather, isTrue);
      expect(moderateForecast.effectiveWarnings, hasLength(1));
      expect(moderateForecast.effectiveWarnings.first.severity, 'Moderate');

      final calmForecast = HikingWeatherForecast.fromJson({
        'area': 'Sebudi, Selat, Karangasem',
        'fetched_at': '2026-11-18T06:10:00Z',
        'forecast': const [
          {
            'utc_datetime': '2026-11-18T06:00:00Z',
            'local_datetime': '2026-11-18T14:00:00',
            'temperature_c': 24,
            'humidity_percent': 75,
            'condition': 'Cerah Berawan',
            'wind_kmh': 10,
            'wind_direction': 'E',
          },
        ],
        'warnings': const [],
      });

      expect(calmForecast.effectiveWarnings, isEmpty);
    });

    test('does not duplicate warnings when official CAP warnings are already present', () {
      final forecast = HikingWeatherForecast.fromJson({
        'area': 'Sembalun Lawang, Lombok Timur',
        'fetched_at': '2026-11-18T06:10:00Z',
        'forecast': const [
          {
            'utc_datetime': '2026-11-18T06:00:00Z',
            'local_datetime': '2026-11-18T14:00:00',
            'temperature_c': 18,
            'humidity_percent': 95,
            'condition': 'Hujan Petir',
            'wind_kmh': 40,
            'wind_direction': 'NW',
          },
        ],
        'warnings': const [
          {
            'identifier': 'cap-bmkg-ntb-001',
            'headline': 'Peringatan Dini Cuaca NTB: Hujan Lebat disertai Petir',
            'description': 'Berpotensi terjadi di wilayah Sembalun.',
            'severity': 'Severe',
            'urgency': 'Immediate',
          },
        ],
      });

      expect(forecast.effectiveWarnings, hasLength(1));
      expect(forecast.effectiveWarnings.first.identifier, 'cap-bmkg-ntb-001');
    });
  });

  group('HikingWeatherCard dropdown interactions', () {
    testWidgets(
      'top dropdown hides/shows info card while bottom dropdown expands/collapses full weather history',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'hiking_weather_cache_v1_lombok': jsonEncode({
            'area': {
              'name': 'Sembalun Lawang, Lombok Timur',
              'timezone': 'WITA',
              'utc_offset_hours': 8,
            },
            'analysis_date': '2026-11-18T06:00:00Z',
            'fetched_at': '2026-11-18T06:10:00Z',
            'forecast': [
              {
                'utc_datetime': '2026-11-18T06:00:00Z',
                'local_datetime': '2026-11-18T14:00:00',
                'temperature_c': 21,
                'humidity_percent': 88,
                'condition': 'Hujan Sedang',
                'wind_kmh': 18,
                'wind_direction': 'W',
              },
              {
                'utc_datetime': '2026-11-18T09:00:00Z',
                'local_datetime': '2026-11-18T17:00:00',
                'temperature_c': 18,
                'humidity_percent': 91,
                'condition': 'Berawan Tebal',
                'wind_kmh': 14,
                'wind_direction': 'SW',
              },
              {
                'utc_datetime': '2026-11-18T12:00:00Z',
                'local_datetime': '2026-11-18T20:00:00',
                'temperature_c': 16,
                'humidity_percent': 94,
                'condition': 'Kabut',
                'wind_kmh': 10,
                'wind_direction': 'S',
              },
              {
                'utc_datetime': '2026-11-18T15:00:00Z',
                'local_datetime': '2026-11-18T23:00:00',
                'temperature_c': 14,
                'humidity_percent': 96,
                'condition': 'Hujan Ringan Malam',
                'wind_kmh': 12,
                'wind_direction': 'SE',
              },
            ],
            'warnings': const [],
          }),
        });

        await tester.pumpWidget(
          ChangeNotifierProvider<VolcanoProvider>(
            create: (_) => _FakeWeatherVolcanoProvider(),
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HikingWeatherCard(
                    latitude: -8.4111,
                    longitude: 116.4573,
                    cacheRegion: 'lombok',
                    canFetch: false,
                    showRefreshButton: false,
                    clock: () => DateTime.utc(2026, 11, 18, 6, 30),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Awal: isi kartu tampil ringkas (hanya 3 slot pertama, slot ke-4 belum tampil)
        expect(find.text('Hujan Sedang'), findsOneWidget);
        expect(find.text('Hujan Ringan Malam'), findsNothing);
        expect(
          find.textContaining('Lihat seluruh riwayat cuaca'),
          findsOneWidget,
        );

        final historyToggleFinder = find.byKey(
          const Key('weather_history_dropdown_toggle'),
        );
        final topBeforeExpand = tester.getTopLeft(historyToggleFinder).dy;

        // Tap dropdown riwayat -> tampilkan seluruh riwayat & jadwal cuaca di bawah tombol
        await tester.tap(historyToggleFinder);
        await tester.pumpAndSettle();

        final topAfterExpand = tester.getTopLeft(historyToggleFinder).dy;
        final firstCardTop = tester.getTopLeft(find.text('Hujan Ringan Malam')).dy;
        // Tombol tutup tetap berada di atas daftar riwayat (tidak ikut terdorong ke bawah)
        expect(topAfterExpand, topBeforeExpand);
        expect(firstCardTop, greaterThan(topAfterExpand));

        expect(find.text('Hujan Ringan Malam'), findsOneWidget);
        expect(find.text('Terkini'), findsOneWidget);
        expect(
          find.textContaining('Sembunyikan riwayat cuaca'),
          findsOneWidget,
        );

        // Tap dropdown atas -> sembunyikan seluruh kartu informasi di bawah header
        await tester.tap(
          find.byKey(const Key('weather_card_visibility_toggle')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Prakiraan cuaca'), findsOneWidget);
        expect(find.text('Hujan Ringan Malam'), findsNothing);
        expect(find.textContaining('Sembunyikan riwayat cuaca'), findsNothing);
        expect(find.text('Sumber: BMKG'), findsNothing);

        // Tap dropdown atas lagi -> tampilkan kembali dan state riwayat tetap terjaga
        await tester.tap(
          find.byKey(const Key('weather_card_visibility_toggle')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hujan Ringan Malam'), findsOneWidget);
        expect(find.text('Sumber: BMKG'), findsOneWidget);

        // Unmount agar Timer.periodic dibersihkan rapi di akhir test
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });

  group('HikingWeatherForecast time handling', () {
    Map<String, dynamic> slot(String utc, String local, String condition) => {
      'utc_datetime': utc,
      'local_datetime': local,
      'temperature_c': 20,
      'humidity_percent': 90,
      'condition': condition,
      'wind_kmh': 10,
      'wind_direction': 'W',
    };

    HikingWeatherForecast lombok({
      required List<Map<String, dynamic>> forecast,
      List<Map<String, dynamic>> warnings = const [],
    }) => HikingWeatherForecast.fromJson({
      'area': {
        'name': 'Sembalun Lawang, Lombok Timur',
        'timezone': 'WITA',
        'utc_offset_hours': 8,
      },
      'fetched_at': '2026-11-18T06:10:00Z',
      'forecast': forecast,
      'warnings': warnings,
    });

    test('treats BMKG utc_datetime without zone marker as UTC', () {
      final forecast = lombok(
        forecast: [slot('2026-11-18 06:00:00', '2026-11-18 14:00:00', 'Cerah')],
      );
      final utc = forecast.forecasts.first.utcDateTime!;
      expect(utc.isUtc, isTrue);
      expect(utc.hour, 6);
      // Jam dinding lokal tetap apa adanya.
      expect(forecast.forecasts.first.localDateTime!.hour, 14);
      // Round-trip cache mempertahankan UTC.
      final restored = HikingWeatherForecast.fromJson(forecast.toJson());
      expect(restored.forecasts.first.utcDateTime, utc);
    });

    test('drops slots whose 3-hour window has ended', () {
      final forecast = lombok(
        forecast: [
          slot('2026-11-18T06:00:00Z', '2026-11-18 14:00:00', 'Hujan Lebat'),
          slot('2026-11-18T09:00:00Z', '2026-11-18 17:00:00', 'Berawan'),
          slot('2026-11-18T12:00:00Z', '2026-11-18 20:00:00', 'Kabut'),
        ],
      );

      // 10:00Z: slot 06:00Z habis (09:00Z), slot 09:00Z masih berjalan.
      final active = forecast.activeForecasts(DateTime.utc(2026, 11, 18, 10));
      expect(active.map((s) => s.condition), ['Berawan', 'Kabut']);

      // Semua slot lampau -> kosong, bukan menampilkan slot basi.
      expect(forecast.activeForecasts(DateTime.utc(2026, 11, 19)), isEmpty);
    });

    test('derives slot start from local time when utc_datetime is missing', () {
      final forecast = lombok(
        forecast: [
          {
            'local_datetime': '2026-11-18 14:00:00',
            'condition': 'Cerah',
          },
        ],
      );
      expect(
        forecast.forecasts.first.startUtc(forecast.utcOffsetHours),
        DateTime.utc(2026, 11, 18, 6),
      );
      expect(forecast.activeForecasts(DateTime.utc(2026, 11, 18, 8, 59)), hasLength(1));
      expect(forecast.activeForecasts(DateTime.utc(2026, 11, 18, 9)), isEmpty);
    });

    test('active warnings ignore past hazard slots and expired CAP alerts', () {
      final forecast = lombok(
        forecast: [
          slot('2026-11-18T06:00:00Z', '2026-11-18 14:00:00', 'Hujan Petir'),
          slot('2026-11-18T09:00:00Z', '2026-11-18 17:00:00', 'Cerah Berawan'),
          slot('2026-11-18T12:00:00Z', '2026-11-18 20:00:00', 'Cerah'),
        ],
        warnings: [
          {
            'identifier': 'cap-expired',
            'headline': 'Peringatan lama',
            'description': '',
            'severity': 'Severe',
            'urgency': 'Immediate',
            'expires_at': '2026-11-18T08:00:00+08:00',
          },
        ],
      );

      final early = forecast.activeWarnings(DateTime.utc(2026, 11, 17, 23));
      expect(early.single.identifier, 'cap-expired');

      // Setelah CAP kedaluwarsa & slot petir lewat: tidak ada peringatan.
      expect(forecast.activeWarnings(DateTime.utc(2026, 11, 18, 10)), isEmpty);
    });

    test('synthesized warning expiry is UTC end of slot window', () {
      final forecast = lombok(
        forecast: [
          slot('2026-11-18 06:00:00', '2026-11-18 14:00:00', 'Hujan Lebat'),
        ],
      );
      final warning =
          forecast.activeWarnings(DateTime.utc(2026, 11, 18, 7)).single;
      expect(warning.expiresAt, DateTime.utc(2026, 11, 18, 9));
      expect(warning.expiresAt!.isUtc, isTrue);
    });
  });

  group('HikingWeatherCard time-aware rendering', () {
    Future<void> pumpCard(
      WidgetTester tester,
      Map<String, dynamic> cache,
      DateTime now,
    ) async {
      SharedPreferences.setMockInitialValues({
        'hiking_weather_cache_v1_lombok': jsonEncode(cache),
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<VolcanoProvider>(
          create: (_) => _FakeWeatherVolcanoProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HikingWeatherCard(
                  latitude: -8.4111,
                  longitude: 116.4573,
                  cacheRegion: 'lombok',
                  canFetch: false,
                  showRefreshButton: false,
                  clock: () => now,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }

    final baseCache = <String, dynamic>{
      'area': {
        'name': 'Sembalun Lawang, Lombok Timur',
        'timezone': 'WITA',
        'utc_offset_hours': 8,
      },
      'analysis_date': '2026-11-18T06:00:00Z',
      'fetched_at': '2026-11-18T06:10:00Z',
      'forecast': [
        {
          'utc_datetime': '2026-11-18T06:00:00Z',
          'local_datetime': '2026-11-18T14:00:00',
          'temperature_c': 21,
          'condition': 'Hujan Sedang',
        },
        {
          'utc_datetime': '2026-11-18T09:00:00Z',
          'local_datetime': '2026-11-18T17:00:00',
          'temperature_c': 18,
          'condition': 'Berawan Tebal',
        },
      ],
      'warnings': const [],
    };

    testWidgets('stale cache does not show past slot as current', (
      tester,
    ) async {
      await pumpCard(tester, baseCache, DateTime.utc(2026, 11, 18, 10));

      expect(find.text('Hujan Sedang'), findsNothing);
      expect(find.text('Berawan Tebal'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('fully expired cache shows expired notice', (tester) async {
      await pumpCard(tester, baseCache, DateTime.utc(2026, 11, 19));

      expect(find.text('Hujan Sedang'), findsNothing);
      expect(find.text('Berawan Tebal'), findsNothing);
      expect(
        find.textContaining('Prakiraan tersimpan sudah kedaluwarsa'),
        findsOneWidget,
      );

      await unmount(tester);
    });

    testWidgets('warning expiry is shown in region timezone, not device', (
      tester,
    ) async {
      await pumpCard(tester, {
        ...baseCache,
        'warnings': [
          {
            'identifier': 'cap-ntb-1',
            'headline': 'Peringatan Dini Cuaca NTB',
            'description': 'Hujan lebat disertai petir.',
            'severity': 'Severe',
            'urgency': 'Immediate',
            'expires_at': '2026-11-18T09:00:00Z',
          },
        ],
      }, DateTime.utc(2026, 11, 18, 6, 30));

      // 09:00 UTC = 17:00 WITA, apa pun zona waktu perangkat.
      expect(find.textContaining('17:00 WITA'), findsOneWidget);

      await unmount(tester);
    });
  });
}
