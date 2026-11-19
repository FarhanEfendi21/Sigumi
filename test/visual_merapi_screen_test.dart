import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/config/theme.dart';
import 'package:sigumi/models/volcano_model.dart';
import 'package:sigumi/models/volcano_summarizer.dart';
import 'package:sigumi/providers/volcano_provider.dart';
import 'package:sigumi/screens/visual/visual_merapi_screen.dart';
import 'package:sigumi/widgets/hiking_weather_card.dart';
import 'package:sigumi/widgets/volcano_monitoring_cards.dart';
import 'package:sigumi/widgets/volcano_summarizer_widget.dart';

class _TestVolcanoProvider extends ChangeNotifier implements VolcanoProvider {
  _TestVolcanoProvider({
    VolcanoModel? volcano,
    VolcanoSummarizer? latestSummary,
    String language = 'id',
  }) : _volcano = volcano ?? VolcanoModel.mockMerapi(),
       _latestSummary = latestSummary,
       _language = language;

  final VolcanoModel _volcano;
  final VolcanoSummarizer? _latestSummary;
  final String _language;
  final List<String> fetchedSummaryKeys = [];

  @override
  VolcanoModel get volcano => _volcano;

  @override
  String get language => _language;

  @override
  bool get highContrast => false;

  @override
  String get colorBlindMode => 'normal';

  @override
  VolcanoSummarizer? get latestVolcanoSummary => _latestSummary;

  @override
  bool get isLoadingSummaries => false;

  @override
  Future<void> fetchLatestVolcanoSummary(String volcanoKey) async {
    fetchedSummaryKeys.add(volcanoKey);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildScreen({
  required VolcanoModel volcano,
  required _TestVolcanoProvider provider,
}) {
  return ChangeNotifierProvider<VolcanoProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: SigumiTheme.lightTheme,
      home: VisualMerapiScreen(volcano: volcano),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'renders MAGMA visual header, visual observation, daily seismicity without duplicate fetch or hardcoded 00.00',
    (tester) async {
      final merapi = VolcanoModel.mockMerapi().copyWith(statusLevel: 3);
      final summary = VolcanoSummarizer(
        id: 'merapi-var-1',
        reportDate: DateTime(2026, 11, 19),
        volcanoName: 'Gunung Merapi',
        volcanoKey: 'merapi',
        levelCode: 3,
        levelName: 'Siaga',
        periodStart: '00:00',
        periodEnd: '24:00',
        timezone: 'WIB',
        vonaColorCode: 'ORANGE',
        visibility: 'Gunung api terlihat jelas hingga tertutup kabut 0-I.',
        craterSmoke: 'Asap kawah putih tipis tinggi 50 meter dari puncak.',
        avalancheNotes:
            'Teramati 7 kali guguran lava ke Kali Bebeng sejauh 1.500 m.',
        seismicity: const VolcanoSeismicitySummary(
          guguran: VolcanoSeismicMetric(
            count: 45,
            detail: 'Amp 3-25 mm · Dur 18-120 dtk',
          ),
          hembusan: VolcanoSeismicMetric(count: 3),
          vulkanik: VolcanoSeismicMetric(count: 6),
          tektonik: VolcanoSeismicMetric(count: 2),
        ),
        summary: 'Aktivitas vulkanik masih pada Level III (Siaga).',
      );
      final provider = _TestVolcanoProvider(
        volcano: merapi,
        latestSummary: summary,
      );

      await tester.pumpWidget(_buildScreen(volcano: merapi, provider: provider));
      await tester.pump(const Duration(milliseconds: 600));

      // Header Visual
      expect(find.byType(MagmaVisualHeaderCard), findsOneWidget);
      expect(find.text('LEVEL III · SIAGA'), findsOneWidget);
      expect(find.text('VONA · ORANGE'), findsOneWidget);
      expect(
        find.text('19 November 2026  ·  00:00–24:00 WIB'),
        findsOneWidget,
      );

      // Kartu Pengamatan Visual
      expect(find.byType(MagmaVisualObservationCard), findsOneWidget);
      expect(
        find.text('Gunung api terlihat jelas hingga tertutup kabut 0-I.'),
        findsOneWidget,
      );
      expect(
        find.text('Asap kawah putih tipis tinggi 50 meter dari puncak.'),
        findsOneWidget,
      );
      expect(
        find.text('Teramati 7 kali guguran lava ke Kali Bebeng sejauh 1.500 m.'),
        findsOneWidget,
      );

      // Kartu Kegempaan Harian
      expect(find.byType(MagmaDailySeismicityCard), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('56 kejadian'), findsOneWidget);

      // Weather & Summary Card (tidak ada hardcoded 00.00 dan tidak double fetch)
      expect(find.byType(HikingWeatherCard), findsOneWidget);
      expect(
        find.byType(VolcanoLatestSummaryWithHistoryButton),
        findsOneWidget,
      );
      expect(find.text('00.00'), findsNothing);
      expect(find.text('00:00–24:00 WIB'), findsOneWidget);
      expect(provider.fetchedSummaryKeys, equals(['merapi']));
    },
  );

  testWidgets(
    'ignores stale summary from another volcano and renders safe placeholders',
    (tester) async {
      final rinjani = VolcanoModel.mockRinjani();
      final merapiSummary = VolcanoSummarizer(
        id: 'merapi-stale',
        reportDate: DateTime(2026, 11, 19),
        volcanoName: 'Gunung Merapi',
        volcanoKey: 'merapi',
        levelCode: 3,
        levelName: 'Siaga',
        vonaColorCode: 'RED',
        visibility: 'Stale Merapi Visibility',
      );
      final provider = _TestVolcanoProvider(
        volcano: rinjani,
        latestSummary: merapiSummary,
      );

      await tester.pumpWidget(
        _buildScreen(volcano: rinjani, provider: provider),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Stale Merapi Visibility'), findsNothing);
      expect(find.text('VONA · RED'), findsNothing);
      expect(find.text('VONA · —'), findsOneWidget);
      expect(find.text('LEVEL II · WASPADA'), findsOneWidget);
      expect(provider.fetchedSummaryKeys, equals(['rinjani']));
    },
  );

  testWidgets('translates MAGMA monitoring cards to English', (tester) async {
    final agung = VolcanoModel.mockAgung();
    final provider = _TestVolcanoProvider(volcano: agung, language: 'en');

    await tester.pumpWidget(_buildScreen(volcano: agung, provider: provider));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Volcano Monitoring'), findsOneWidget);
    expect(find.text('Visual Observation'), findsOneWidget);
    expect(find.text('Daily Seismicity'), findsOneWidget);
    expect(find.text('Avalanche'), findsOneWidget);
    expect(find.text('Emission'), findsOneWidget);
    expect(find.text('Volcanic'), findsOneWidget);
    expect(find.text('Tectonic'), findsOneWidget);
  });
}
