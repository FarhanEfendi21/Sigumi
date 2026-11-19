import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sigumi/config/routes.dart';
import 'package:sigumi/config/theme.dart';
import 'package:sigumi/providers/volcano_provider.dart';
import 'package:sigumi/screens/onboarding/onboarding_screen.dart';

class _TestVolcanoProvider extends ChangeNotifier implements VolcanoProvider {
  String _language = 'id';
  bool _highContrast = false;
  bool _isFirstTime = true;
  double _fontSize = 1.0;
  String _colorBlindMode = 'normal';

  @override
  String get language => _language;

  @override
  bool get highContrast => _highContrast;

  @override
  bool get isFirstTime => _isFirstTime;

  @override
  double get fontSize => _fontSize;

  @override
  String get colorBlindMode => _colorBlindMode;

  @override
  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  @override
  void setHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  @override
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  @override
  void setColorBlindMode(String mode) {
    _colorBlindMode = mode;
    notifyListeners();
  }

  @override
  void completeOnboarding() {
    _isFirstTime = false;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

double _relativeLuminance(Color color) {
  double linearize(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

Widget _buildOnboardingHarness({
  required _TestVolcanoProvider provider,
  Size viewportSize = const Size(390, 844),
  double textScale = 1.0,
  bool disableAnimations = false,
}) {
  return ChangeNotifierProvider<VolcanoProvider>.value(
    value: provider,
    child: MediaQuery(
      data: MediaQueryData(
        size: viewportSize,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        theme: provider.highContrast
            ? SigumiTheme.highContrastTheme
            : SigumiTheme.lightTheme,
        home: const OnboardingScreen(),
        routes: {
          AppRoutes.main: (_) => const Scaffold(body: Text('Main Screen')),
        },
      ),
    ),
  );
}

void main() {
  group('SigumiTokens contrast verification', () {
    test('Light and high-contrast tokens satisfy WCAG AA/non-text contrast', () {
      for (final tokens in const [
        SigumiTokens.light,
        SigumiTokens.highContrast,
      ]) {
        expect(
          _contrastRatio(tokens.inkPrimary, tokens.canvasBg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(tokens.inkSecondary, tokens.canvasBg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(tokens.inkMuted, tokens.canvasBg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(tokens.inkMuted, tokens.subtleSurface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(tokens.accentPrimary, tokens.canvasBg),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(tokens.onAccent, tokens.accentPrimary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(tokens.borderControl, tokens.canvasBg),
          greaterThanOrEqualTo(3.0),
        );
        expect(
          _contrastRatio(tokens.focusRing, tokens.canvasBg),
          greaterThanOrEqualTo(3.0),
        );
      }

      // Verify contrast over peak 15.5% ambient blue & yellow orb washes
      for (final wash in [
        Color.alphaBlend(
          SigumiTokens.light.ambientHighlightBlue.withValues(alpha: 0.155),
          SigumiTokens.light.canvasBg,
        ),
        Color.alphaBlend(
          SigumiTokens.light.ambientHighlightYellow.withValues(alpha: 0.155),
          SigumiTokens.light.canvasBg,
        ),
      ]) {
        expect(
          _contrastRatio(SigumiTokens.light.inkPrimary, wash),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(SigumiTokens.light.inkSecondary, wash),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(SigumiTokens.light.inkMuted, wash),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(SigumiTokens.light.accentPrimary, wash),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(SigumiTokens.light.borderControl, wash),
          greaterThanOrEqualTo(3.0),
        );
      }
    });
  });

  group('OnboardingScreen behavior, accessibility & layout', () {
    testWidgets(
      'preserves page flow, back navigation, language switching & finish action',
      (tester) async {
        final provider = _TestVolcanoProvider();
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_buildOnboardingHarness(provider: provider));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('1 / 3'), findsOneWidget);
        expect(find.text('Selamat datang di SIGUMI'), findsOneWidget);
        expect(find.text('Lewati'), findsOneWidget);
        expect(find.text('Lanjutkan'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);

        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('2 / 3'), findsOneWidget);
        expect(find.text('Status waktu nyata'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.chevron_left_rounded));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('1 / 3'), findsOneWidget);
        expect(find.text('Selamat datang di SIGUMI'), findsOneWidget);

        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lanjutkan'));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('3 / 3'), findsOneWidget);
        expect(find.text('Pilih bahasa Anda'), findsOneWidget);
        expect(find.text('Lewati'), findsNothing);
        expect(find.text('Mulai Sekarang'), findsOneWidget);

        await tester.tap(find.text('Bahasa Inggris (AS)'));
        await tester.pumpAndSettle();

        expect(provider.language, equals('en'));
        expect(find.text('Choose your language'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);

        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        expect(provider.isFirstTime, isFalse);
        expect(find.text('Main Screen'), findsOneWidget);
      },
    );

    testWidgets('skip action completes onboarding and navigates to main', (
      tester,
    ) async {
      final provider = _TestVolcanoProvider();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildOnboardingHarness(provider: provider));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(provider.isFirstTime, isFalse);
      expect(find.text('Main Screen'), findsOneWidget);
    });

    testWidgets('interactive swipe drives slide parallax and advances page', (
      tester,
    ) async {
      final provider = _TestVolcanoProvider();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildOnboardingHarness(provider: provider));
      await tester.pumpAndSettle();

      // Drag left mid-slide to exercise scroll-linked parallax & ambient orb swap
      expect(
        find.descendant(
          of: find.byType(OnboardingScreen),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
      final gesture = await tester.startGesture(const Offset(340, 350));
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();
      expect(find.byType(Transform), findsWidgets);

      // Complete swipe to page 2
      await gesture.moveBy(const Offset(-160, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('2 / 3'), findsOneWidget);
      expect(find.text('Status waktu nyata'), findsOneWidget);
    });

    testWidgets('supports keyboard navigation, Tab focus & Enter activation', (
      tester,
    ) async {
      final provider = _TestVolcanoProvider();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildOnboardingHarness(provider: provider));
      await tester.pumpAndSettle();

      // Tab to first control ("Lewati") then to primary CTA ("Lanjutkan")
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('2 / 3'), findsOneWidget);

      // Arrow keys navigate between pages
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('3 / 3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('2 / 3'), findsOneWidget);
    });

    testWidgets(
      'responsive viewports, 1.5x text scale, reduced motion & touch targets',
      (tester) async {
        final configs = <({Size size, double scale, bool hc, bool reduced})>[
          (size: const Size(375, 667), scale: 1.0, hc: false, reduced: false),
          (size: const Size(375, 667), scale: 1.5, hc: false, reduced: true),
          (size: const Size(667, 375), scale: 1.0, hc: false, reduced: false),
          (size: const Size(800, 1280), scale: 1.0, hc: true, reduced: false),
        ];

        for (final cfg in configs) {
          final provider = _TestVolcanoProvider()..setHighContrast(cfg.hc);
          await tester.binding.setSurfaceSize(cfg.size);

          await tester.pumpWidget(
            _buildOnboardingHarness(
              provider: provider,
              viewportSize: cfg.size,
              textScale: cfg.scale,
              disableAnimations: cfg.reduced,
            ),
          );
          await tester.pumpAndSettle();

          // Check touch target sizes on Page 1
          final skipSize = tester.getSize(find.byType(TextButton));
          expect(skipSize.height, greaterThanOrEqualTo(48.0));
          expect(skipSize.width, greaterThanOrEqualTo(48.0));

          final ctaSize = tester.getSize(find.byType(ElevatedButton));
          expect(ctaSize.height, greaterThanOrEqualTo(48.0));

          // Advance to Page 2 and Page 3 without any layout overflow
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();

          final backSize = tester.getSize(find.byType(OutlinedButton));
          expect(backSize.height, greaterThanOrEqualTo(48.0));
          expect(backSize.width, greaterThanOrEqualTo(48.0));

          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();

          expect(find.bySemanticsLabel('3 / 3'), findsOneWidget);
          final langInkWells = find.descendant(
            of: find.byType(PageView),
            matching: find.byType(InkWell),
          );
          expect(langInkWells, findsNWidgets(5));
          for (var i = 0; i < 5; i++) {
            final cardSize = tester.getSize(langInkWells.at(i));
            expect(cardSize.height, greaterThanOrEqualTo(48.0));
          }
        }

        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
