import 'package:flutter_test/flutter_test.dart';
import 'package:sigumi/models/volcano_summarizer.dart';
import 'package:sigumi/repositories/volcano_repository.dart';

void main() {
  group('VolcanoSummarizer.periodDisplay', () {
    test('formats start and end period with timezone', () {
      final summary = VolcanoSummarizer(
        id: '1',
        reportDate: DateTime(2026, 11, 19),
        volcanoName: 'Gunung Merapi',
        volcanoKey: 'merapi',
        levelCode: 3,
        levelName: 'Siaga',
        periodStart: '00:00:00',
        periodEnd: '24:00:00',
        timezone: 'WIB',
      );

      expect(summary.periodDisplay, equals('00:00–24:00 WIB'));
      expect(summary.levelRoman, equals('III'));
    });

    test('handles start-only and missing period cleanly without hardcoded 00.00', () {
      final startOnly = VolcanoSummarizer(
        id: '2',
        reportDate: DateTime(2026, 11, 19),
        volcanoName: 'Gunung Agung',
        volcanoKey: 'agung',
        levelCode: 1,
        levelName: 'Normal',
        periodStart: '06.00',
        timezone: 'WITA',
      );
      expect(startOnly.periodDisplay, equals('06:00 WITA'));

      final noPeriod = VolcanoSummarizer(
        id: '3',
        reportDate: DateTime(2026, 11, 19),
        volcanoName: 'Gunung Rinjani',
        volcanoKey: 'rinjani',
        levelCode: 2,
        levelName: 'Waspada',
        timezone: 'WITA',
      );
      expect(noPeriod.periodDisplay, equals('Harian · WITA'));
      expect(noPeriod.periodDisplay, isNot(contains('00.00')));
    });
  });

  group('VolcanoSummarizer.fromJson structured MAGMA VAR & VONA', () {
    test('parses structured photo, VONA, visual, and seismicity JSONB', () {
      final model = VolcanoSummarizer.fromJson({
        'id': 'var-001',
        'report_date': '2026-11-19',
        'volcano_name': 'Gunung Merapi',
        'volcano_key': 'merapi',
        'level_code': 3,
        'level_name': 'Siaga',
        'period_start': '00:00',
        'period_end': '24:00',
        'timezone': 'WIB',
        'visual_photo_url': 'https://magma.esdm.go.id/img/merapi-latest.jpg',
        'vona_color_code': 'orange',
        'visibility': 'Gunung api terlihat jelas hingga kabut 0-I.',
        'crater_smoke': 'Asap kawah putih tipis tinggi 50 m dari puncak.',
        'avalanche_notes': 'Teramati 8 kali guguran lava ke Kali Bebeng maks 1.500 m.',
        'seismicity': {
          'guguran': {
            'count': 45,
            'amplitude': '3-25 mm',
            'duration': '18-120 detik',
          },
          'hembusan': 3,
          'vulkanik_dangkal': 2,
          'vulkanik_dalam': 4,
          'tektonik_lokal': 1,
          'tektonik_jauh': 2,
        },
      });

      expect(
        model.visualPhotoUrl,
        equals('https://magma.esdm.go.id/img/merapi-latest.jpg'),
      );
      expect(model.normalizedVonaCode, equals('ORANGE'));
      expect(
        model.resolvedVisualObservation.visibility,
        equals('Gunung api terlihat jelas hingga kabut 0-I.'),
      );
      expect(
        model.resolvedVisualObservation.craterSmoke,
        equals('Asap kawah putih tipis tinggi 50 m dari puncak.'),
      );
      expect(
        model.resolvedVisualObservation.avalancheNotes,
        contains('Kali Bebeng'),
      );

      final seismic = model.resolvedSeismicity;
      expect(seismic.guguran?.count, equals(45));
      expect(seismic.guguran?.detail, equals('Amp 3-25 mm · Dur 18-120 detik'));
      expect(seismic.hembusan?.count, equals(3));
      expect(seismic.vulkanik?.count, equals(6));
      expect(seismic.tektonik?.count, equals(3));
      expect(seismic.totalEvents, equals(57));
    });

    test('falls back cleanly to parsing legacy summary narrative text', () {
      final legacy = VolcanoSummarizer.fromJson({
        'id': 'legacy-001',
        'report_date': '2026-11-19',
        'volcano_name': 'Gunung Merapi',
        'volcano_key': 'merapi',
        'level_code': 3,
        'level_name': 'Siaga',
        'period_start': '00:00',
        'period_end': '12:00',
        'timezone': 'WIB',
        'summary':
            'Gunung api terlihat jelas hingga tertutup kabut 0-II. '
            'Asap kawah utama berwarna putih dengan intensitas tipis tinggi sekitar 75 meter dari puncak. '
            'Teramati 6 kali guguran lava ke arah Kali Bebeng dengan jarak luncur maksimum 1400 meter. '
            '42 kali gempa Guguran dengan amplitudo 3-28 mm dan lama gempa 20-115 detik. '
            '2 kali gempa Hembusan. '
            '1 kali gempa Vulkanik Dangkal dan 3 kali gempa Vulkanik Dalam. '
            '2 kali gempa Tektonik Jauh. Status VONA YELLOW.',
      });

      expect(legacy.normalizedVonaCode, equals('YELLOW'));

      final visual = legacy.resolvedVisualObservation;
      expect(visual.visibility, contains('kabut 0-II'));
      expect(visual.craterSmoke, contains('Asap kawah utama'));
      expect(visual.avalancheNotes, contains('6 kali guguran lava'));

      final seismic = legacy.resolvedSeismicity;
      expect(seismic.guguran?.count, equals(42));
      expect(seismic.guguran?.detail, equals('Amp 3-28 mm · Dur 20-115 detik'));
      expect(seismic.hembusan?.count, equals(2));
      expect(seismic.vulkanik?.count, equals(4));
      expect(seismic.tektonik?.count, equals(2));
      expect(seismic.totalEvents, equals(50));
    });
  });

  group('VolcanoRepository.selectBestLatestSummary', () {
    test(
      'prefers enriched MAGMA VAR row over newer legacy summary-only row',
      () {
        final legacySummaryOnlyRow = VolcanoSummarizer(
          id: 'legacy-summary-only',
          reportDate: DateTime(2026, 11, 19),
          volcanoName: 'Gunung Agung',
          volcanoKey: 'agung',
          levelCode: 1,
          levelName: 'Normal',
          periodStart: '00:00:00',
          periodEnd: '24:00:00',
          summary:
              'Berdasarkan pengamatan visual, asap kawah tidak teramati. Tercatat 3 kali aktivitas gempa vulkanik dalam.',
        );
        final magmaVarRow = VolcanoSummarizer(
          id: 'magma-var',
          reportDate: DateTime(2026, 11, 18),
          volcanoName: 'Gunung Agung',
          volcanoKey: 'agung',
          levelCode: 1,
          levelName: 'Normal',
          periodStart: '00:00:00',
          periodEnd: '24:00:00',
          timezone: 'WITA',
          vonaColorCode: 'GREEN',
          visualPhotoUrl:
              'https://magma.vsi.esdm.go.id/img/ga/AGU/AGU202611182400.png',
          visibility: 'Gunung api terlihat jelas hingga tertutup Kabut 0-III.',
        );

        expect(legacySummaryOnlyRow.resolvedSeismicity.vulkanik?.count, equals(3));

        final picked = VolcanoRepository.selectBestLatestSummary([
          legacySummaryOnlyRow,
          magmaVarRow,
        ]);

        expect(picked?.id, equals('magma-var'));
        expect(picked?.vonaColorCode, equals('GREEN'));
        expect(picked?.visualPhotoUrl, contains('AGU202611182400.png'));
      },
    );
  });
}
