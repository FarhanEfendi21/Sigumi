import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/theme_extensions.dart';
import '../../providers/volcano_provider.dart';
import '../../services/localization_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageCount = 3;
  final PageController _pageController = PageController();
  final ValueNotifier<double> _ambientProgress = ValueNotifier<double>(0.0);
  late final Ticker _ambientTicker;
  Duration _lastTickElapsed = Duration.zero;
  int _currentPage = 0;
  bool _isPrimaryCtaFocused = false;

  @override
  void initState() {
    super.initState();
    _ambientTicker = createTicker(_onAmbientTick);
    _pageController.addListener(_handlePageScroll);
  }

  double get _currentScrollPage {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
      return _currentPage.toDouble();
    }
    return _pageController.page ?? _currentPage.toDouble();
  }

  void _handlePageScroll() {
    final double target = _currentScrollPage;
    if (mounted && context.reduceMotion) {
      _stopAmbientTicker();
      if (_ambientProgress.value != _currentPage.toDouble()) {
        _ambientProgress.value = _currentPage.toDouble();
      }
      return;
    }

    if ((target - _ambientProgress.value).abs() > 0.0005 &&
        !_ambientTicker.isActive) {
      _lastTickElapsed = Duration.zero;
      _ambientTicker.start();
    }
  }

  void _onAmbientTick(Duration elapsed) {
    if (!mounted) return;
    final double dtSeconds = _lastTickElapsed == Duration.zero
        ? (1.0 / 60.0)
        : ((elapsed - _lastTickElapsed).inMicroseconds / 1000000.0)
              .clamp(0.001, 0.05);
    _lastTickElapsed = elapsed;

    final double target = _currentScrollPage;
    final double diff = target - _ambientProgress.value;
    final bool isScrolling = _pageController.hasClients &&
        _pageController.position.haveDimensions &&
        _pageController.position.isScrollingNotifier.value;

    if (diff.abs() < 0.0008 && !isScrolling) {
      _ambientProgress.value = target;
      _stopAmbientTicker();
      return;
    }

    // Critically-damped exponential smoothing untuk gerak orb yang halus
    final double smoothing = 1.0 - math.exp(-8.5 * dtSeconds);
    _ambientProgress.value += diff * smoothing;
  }

  void _stopAmbientTicker() {
    if (_ambientTicker.isActive) {
      _ambientTicker.stop();
    }
    _lastTickElapsed = Duration.zero;
  }

  List<OnboardingData> _pages(BuildContext pageContext) => [
    OnboardingData(
      title: pageContext.tr('welcome_to_sigumi'),
      description: pageContext.trText(
        'Sistem Informasi Gunung Berapi & Mitigasi Bencana yang membantu Anda tetap aman dan terinformasi.',
      ),
      icon: Icons.volcano_rounded,
      color: pageContext.accentPrimary,
      imagePath: 'assets/onboarding/onboarding 1.png',
      sectionLabel: pageContext.trText('MITIGASI BENCANA'),
    ),
    OnboardingData(
      title: pageContext.tr('realtime_status'),
      description: pageContext.trText(
        'Dapatkan pemantauan aktivitas gunung berapi secara langsung dan instan berkat integrasi data MAGMA.',
      ),
      icon: Icons.sensors_rounded,
      color: pageContext.accentPrimary,
      imagePath: 'assets/onboarding/onboarding 2.png',
      sectionLabel: pageContext.trText('DATA REAL-TIME'),
    ),
    OnboardingData(
      title: pageContext.tr('choose_your_language'),
      description: pageContext.trText(
        'SIGUMI mendukung berbagai bahasa daerah untuk memudahkan akses informasi bagi semua kalangan.',
      ),
      icon: Icons.translate_rounded,
      color: pageContext.accentPrimary,
      sectionLabel: pageContext.trText('BAHASA DAERAH'),
    ),
  ];

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _ambientTicker.dispose();
    _ambientProgress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pageCount - 1) {
      final t = context.tokens;
      if (context.reduceMotion) {
        _pageController.jumpToPage(_currentPage + 1);
      } else {
        _pageController.nextPage(
          duration: t.motionPage,
          curve: Curves.easeInOutCubic,
        );
      }
    } else {
      _finishOnboarding();
    }
  }

  void _onPrevious() {
    if (_currentPage <= 0) return;
    HapticFeedback.lightImpact();
    final t = context.tokens;
    if (context.reduceMotion) {
      _pageController.jumpToPage(_currentPage - 1);
    } else {
      _pageController.previousPage(
        duration: t.motionPage,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishOnboarding() {
    HapticFeedback.lightImpact();
    context.read<VolcanoProvider>().completeOnboarding();
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gutter = context.pageGutter;
    final isHC = context.isHighContrast;
    final reduceMotion = context.reduceMotion;
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      backgroundColor: t.canvasBg,
      body: Stack(
        children: [
          if (!isHC)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ValueListenableBuilder<double>(
                    valueListenable: _ambientProgress,
                    builder: (context, ambientValue, _) {
                      final double progress = reduceMotion
                          ? _currentPage.toDouble()
                          : ambientValue;
                      return CustomPaint(
                        painter: _OnboardingAmbientPainter(
                          pageProgress: progress,
                          blueColor: t.ambientHighlightBlue,
                          yellowColor: t.ambientHighlightYellow,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              if (_currentPage < _pageCount - 1)
                const SingleActivator(LogicalKeyboardKey.arrowRight): _onNext,
              if (_currentPage > 0)
                const SingleActivator(LogicalKeyboardKey.arrowLeft): _onPrevious,
            },
            child: Focus(
              skipTraversal: true,
              autofocus: true,
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: t.contentMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Top-Right Soft Skip Pill (matches reference) ──
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              gutter,
                              t.spaceMd,
                              gutter,
                              t.spaceXs,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: AnimatedSwitcher(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : t.motionFast,
                                child: isLastPage
                                    ? SizedBox(
                                        key: const ValueKey<String>(
                                          'skip-empty',
                                        ),
                                        height: t.minTouchTarget,
                                      )
                                    : TextButton(
                                        key: const ValueKey<String>(
                                          'skip-btn',
                                        ),
                                        onPressed: _finishOnboarding,
                                        style: context.swissTextButtonStyle,
                                        child: Text(context.trText('Lewati')),
                                      ),
                              ),
                            ),
                          ),

                          // ── Main Content Pager ──
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (index) =>
                                  setState(() => _currentPage = index),
                              itemCount: _pageCount,
                              itemBuilder: (context, index) => AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, _) {
                                  final double pageDelta =
                                      index - _currentScrollPage;
                                  return Builder(
                                    builder: (pageContext) {
                                      final localizedPages = _pages(pageContext);
                                      final dots = _PageDotsIndicator(
                                        pageCount: _pageCount,
                                        currentPage: _currentPage,
                                        scrollPage: reduceMotion
                                            ? _currentPage.toDouble()
                                            : _currentScrollPage,
                                      );
                                      if (index == 2) {
                                        return _LanguageSelectionPage(
                                          data: localizedPages[index],
                                          pageDelta: pageDelta,
                                          indicator: dots,
                                        );
                                      }
                                      return _OnboardingPage(
                                        data: localizedPages[index],
                                        pageDelta: pageDelta,
                                        indicator: dots,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          // ── Bottom Navigation Bar ([<] circle + Expanded [Continue >] pill) ──
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              gutter,
                              t.spaceSm,
                              gutter,
                              t.spaceXl,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AnimatedSize(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : t.motionMedium,
                                  curve: t.motionCurve,
                                  alignment: Alignment.centerLeft,
                                  child: _currentPage > 0
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            right: t.spaceMd,
                                          ),
                                          child: Semantics(
                                            button: true,
                                            label: context.tr('previous'),
                                            child: Tooltip(
                                              message: context.tr('previous'),
                                              child: OutlinedButton(
                                                onPressed: _onPrevious,
                                                style: context
                                                    .swissSecondaryButtonStyle
                                                    .copyWith(
                                                  shape:
                                                      const WidgetStatePropertyAll(
                                                    CircleBorder(),
                                                  ),
                                                  minimumSize:
                                                      WidgetStatePropertyAll(
                                                    Size(
                                                      t.ctaHeight,
                                                      t.ctaHeight,
                                                    ),
                                                  ),
                                                  padding:
                                                      const WidgetStatePropertyAll(
                                                    EdgeInsets.zero,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.chevron_left_rounded,
                                                  size: t.iconLg,
                                                  color: t.inkPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                Expanded(
                                  child: Focus(
                                    canRequestFocus: false,
                                    skipTraversal: true,
                                    onFocusChange: (hasFocus) {
                                      if (_isPrimaryCtaFocused != hasFocus) {
                                        setState(
                                          () => _isPrimaryCtaFocused = hasFocus,
                                        );
                                      }
                                    },
                                    child: _SwissFocusFrame(
                                      isFocused: _isPrimaryCtaFocused,
                                      tokens: t,
                                      radius: t.radiusPill,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            t.radiusPill,
                                          ),
                                          boxShadow: t.ctaShadow,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _onNext,
                                          style: context.swissPrimaryButtonStyle
                                              .copyWith(
                                            minimumSize: WidgetStatePropertyAll(
                                              Size(
                                                double.infinity,
                                                t.ctaHeight,
                                              ),
                                            ),
                                            padding: WidgetStatePropertyAll(
                                              EdgeInsets.symmetric(
                                                horizontal: t.spaceXl,
                                                vertical: t.spaceMd,
                                              ),
                                            ),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: reduceMotion
                                                ? Duration.zero
                                                : t.motionMedium,
                                            switchInCurve: t.motionCurve,
                                            switchOutCurve: t.motionCurve,
                                            transitionBuilder: (child, anim) =>
                                                FadeTransition(
                                                  opacity: anim,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(
                                                        0,
                                                        0.2,
                                                      ),
                                                      end: Offset.zero,
                                                    ).animate(anim),
                                                    child: child,
                                                  ),
                                                ),
                                            child: Row(
                                              key: ValueKey<bool>(isLastPage),
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    isLastPage
                                                        ? context.trText(
                                                            'Mulai Sekarang',
                                                          )
                                                        : context.tr(
                                                            'continue',
                                                          ),
                                                    maxLines: 1,
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(width: t.spaceXs),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: t.iconMd,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? imagePath;
  final String? sectionLabel;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.imagePath,
    this.sectionLabel,
  });
}

class _PageDotsIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final double scrollPage;

  const _PageDotsIndicator({
    required this.pageCount,
    required this.currentPage,
    required this.scrollPage,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: '${currentPage + 1} / $pageCount',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(pageCount, (index) {
            final double dist = (scrollPage - index).abs().clamp(0.0, 1.0);
            final double size = lerpDouble(9.0, 8.0, dist) ?? 8.0;
            final Color fillColor =
                Color.lerp(t.accentPrimary, Colors.transparent, dist) ??
                Colors.transparent;
            final Color borderColor =
                Color.lerp(t.accentPrimary, t.borderControl, dist) ??
                t.borderControl;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: t.spaceXs + 1),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fillColor,
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final double pageDelta;
  final Widget indicator;

  const _OnboardingPage({
    required this.data,
    required this.pageDelta,
    required this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gutter = context.pageGutter;
    final isHC = context.isHighContrast;
    final reduceMotion = context.reduceMotion;

    final double clampedDelta = reduceMotion ? 0.0 : pageDelta.clamp(-1.0, 1.0);
    final double absDelta = clampedDelta.abs();
    final double stageScale = (1.0 - (absDelta * 0.08)).clamp(0.92, 1.0);
    final double stageOpacity = (1.0 - (absDelta * 0.65)).clamp(0.35, 1.0);
    final double bodyOpacity = (1.0 - (absDelta * 0.90)).clamp(0.10, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideOrLandscape =
            constraints.maxWidth >= 600 ||
            (constraints.maxHeight < 460 && constraints.maxWidth >= 480);

        final double visualMaxHeight = isWideOrLandscape
            ? (constraints.maxHeight - t.space2xl).clamp(130.0, 290.0)
            : (constraints.maxHeight * 0.48).clamp(160.0, 310.0);

        final Widget rawVisualFrame = ExcludeSemantics(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: visualMaxHeight),
            decoration: isHC
                ? BoxDecoration(
                    color: t.artworkPlateBg,
                    borderRadius: BorderRadius.circular(t.radiusMd),
                    border: Border.all(
                      color: t.borderSubtle,
                      width: t.hairlineWidth,
                    ),
                  )
                : null,
            child: Padding(
              padding: isHC
                  ? EdgeInsets.all(t.spaceLg)
                  : EdgeInsets.symmetric(vertical: t.spaceSm),
              child: data.imagePath != null
                  ? Image.asset(
                      data.imagePath!,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Icon(
                        data.icon,
                        size: t.iconHero,
                        color: t.artworkPlateInk,
                      ),
                    ),
            ),
          ),
        );

        final Widget visualStage = Transform.translate(
          offset: Offset(clampedDelta * 36, 0),
          child: Transform.scale(
            scale: stageScale,
            child: Opacity(
              opacity: stageOpacity,
              child: reduceMotion
                  ? rawVisualFrame
                  : rawVisualFrame
                        .animate()
                        .fadeIn(
                          duration: t.motionMedium,
                          curve: t.motionCurve,
                        )
                        .moveY(
                          begin: 14,
                          end: 0,
                          duration: t.motionMedium,
                          curve: t.motionCurve,
                        ),
            ),
          ),
        );

        final Widget headlineWidget = Transform.translate(
          offset: Offset(clampedDelta * 10, 0),
          child: Text(
            data.title,
            textAlign: TextAlign.center,
            style: constraints.maxWidth < 360
                ? t.sectionTitle.copyWith(fontSize: t.spaceXl)
                : t.displayHeadline,
          ),
        );

        final Widget descriptionWidget = Transform.translate(
          offset: Offset(clampedDelta * 30, 0),
          child: Opacity(
            opacity: bodyOpacity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: t.bodyRegular,
              ),
            ),
          ),
        );

        final Widget copyBlock = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            indicator,
            SizedBox(height: t.spaceXl),
            reduceMotion
                ? headlineWidget
                : headlineWidget
                      .animate()
                      .fadeIn(delay: 90.ms, duration: t.motionMedium)
                      .moveY(
                        begin: 14,
                        end: 0,
                        duration: t.motionMedium,
                        curve: t.motionCurve,
                      ),
            SizedBox(height: t.spaceMd),
            reduceMotion
                ? descriptionWidget
                : descriptionWidget
                      .animate()
                      .fadeIn(delay: 150.ms, duration: t.motionMedium)
                      .moveY(
                        begin: 14,
                        end: 0,
                        duration: t.motionMedium,
                        curve: t.motionCurve,
                      ),
          ],
        );

        final Widget pageBody = isWideOrLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(flex: 5, child: visualStage),
                  SizedBox(width: t.space2xl),
                  Expanded(flex: 6, child: copyBlock),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  visualStage,
                  SizedBox(height: t.spaceXl),
                  copyBlock,
                ],
              );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: t.spaceLg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - t.spaceXl).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Center(child: pageBody),
          ),
        );
      },
    );
  }
}

class _LanguageSelectionPage extends StatelessWidget {
  final OnboardingData data;
  final double pageDelta;
  final Widget indicator;

  const _LanguageSelectionPage({
    required this.data,
    required this.pageDelta,
    required this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VolcanoProvider>();
    final t = context.tokens;
    final gutter = context.pageGutter;
    final reduceMotion = context.reduceMotion;

    final double clampedDelta = reduceMotion ? 0.0 : pageDelta.clamp(-1.0, 1.0);
    final double absDelta = clampedDelta.abs();
    final double contentOpacity = (1.0 - (absDelta * 0.75)).clamp(0.25, 1.0);

    final options = <({String code, String title})>[
      (code: 'id', title: context.tr('lang_id')),
      (code: 'en', title: context.tr('lang_en_us')),
      (code: 'jv', title: context.tr('lang_jv')),
      (code: 'ba', title: context.tr('lang_ba')),
      (code: 'sa', title: context.tr('lang_sa')),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool useTwoColumns = constraints.maxWidth >= 520;

        final Widget headerContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            indicator,
            SizedBox(height: t.spaceXl),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: constraints.maxWidth < 360
                  ? t.sectionTitle.copyWith(fontSize: t.spaceXl)
                  : t.displayHeadline,
            ),
            SizedBox(height: t.spaceSm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: t.bodyRegular,
              ),
            ),
          ],
        );

        final Widget headerBlock = Transform.translate(
          offset: Offset(clampedDelta * 26, 0),
          child: Opacity(
            opacity: contentOpacity,
            child: reduceMotion
                ? headerContent
                : headerContent
                      .animate()
                      .fadeIn(duration: t.motionMedium, curve: t.motionCurve)
                      .moveY(
                        begin: 12,
                        end: 0,
                        duration: t.motionMedium,
                        curve: t.motionCurve,
                      ),
          ),
        );

        final Widget languageGrid = useTwoColumns
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < options.length; i += 2) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LangCard(
                            title: options[i].title,
                            code: options[i].code,
                            isSelected: provider.language == options[i].code,
                          ),
                        ),
                        SizedBox(width: t.spaceMd),
                        Expanded(
                          child: i + 1 < options.length
                              ? _LangCard(
                                  title: options[i + 1].title,
                                  code: options[i + 1].code,
                                  isSelected:
                                      provider.language == options[i + 1].code,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    if (i + 2 < options.length) SizedBox(height: t.spaceSm),
                  ],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < options.length; i++) ...[
                    _LangCard(
                      title: options[i].title,
                      code: options[i].code,
                      isSelected: provider.language == options[i].code,
                    ),
                    if (i < options.length - 1) SizedBox(height: t.spaceSm),
                  ],
                ],
              );

        final Widget gridWithParallax = Transform.translate(
          offset: Offset(clampedDelta * 40, 0),
          child: Opacity(
            opacity: contentOpacity,
            child: reduceMotion
                ? languageGrid
                : languageGrid
                      .animate()
                      .fadeIn(
                        delay: 110.ms,
                        duration: t.motionMedium,
                        curve: t.motionCurve,
                      )
                      .moveY(
                        begin: 14,
                        end: 0,
                        duration: t.motionMedium,
                        curve: t.motionCurve,
                      ),
          ),
        );

        final Widget pageBody = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerBlock,
            SizedBox(height: t.spaceXl),
            gridWithParallax,
          ],
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: t.spaceLg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - t.spaceXl).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Center(child: pageBody),
          ),
        );
      },
    );
  }
}

class _LangCard extends StatefulWidget {
  final String title;
  final String code;
  final bool isSelected;

  const _LangCard({
    required this.title,
    required this.code,
    required this.isSelected,
  });

  @override
  State<_LangCard> createState() => _LangCardState();
}

class _LangCardState extends State<_LangCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isHC = context.isHighContrast;
    final reduceMotion = context.reduceMotion;

    final Color unselectedBg = isHC
        ? t.subtleSurface
        : t.canvasBg.withValues(alpha: 0.72);
    final Color bgColor = widget.isSelected
        ? (isHC ? t.selectedFill : t.canvasBg)
        : (_isHovered ? t.hoverFill : unselectedBg);
    final Color borderColor =
        widget.isSelected ? t.borderStrong : t.borderSubtle;
    final double borderWidth =
        widget.isSelected ? t.selectedBorderWidth : t.hairlineWidth;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      inMutuallyExclusiveGroup: true,
      label: '${widget.title}, ${widget.code.toUpperCase()}',
      child: _SwissFocusFrame(
        isFocused: _isFocused,
        tokens: t,
        radius: t.radiusPill,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<VolcanoProvider>().setLanguage(widget.code);
            },
            onFocusChange: (focused) {
              if (_isFocused != focused) {
                setState(() => _isFocused = focused);
              }
            },
            onHover: (hovered) {
              if (_isHovered != hovered) {
                setState(() => _isHovered = hovered);
              }
            },
            borderRadius: BorderRadius.circular(t.radiusPill),
            hoverColor: t.hoverFill,
            splashColor: t.pressedFill,
            highlightColor: t.pressedFill,
            focusColor: Colors.transparent,
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : t.motionFast,
              curve: t.motionCurve,
              width: double.infinity,
              constraints: BoxConstraints(minHeight: t.minTouchTarget),
              padding: EdgeInsets.symmetric(
                horizontal: t.spaceXl - t.spaceXs,
                vertical: t.spaceMd,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(t.radiusPill),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: widget.isSelected ? t.subtleShadow : t.flatShadow,
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : t.motionFast,
                      curve: t.motionCurve,
                      width: widget.isSelected ? t.spaceXs : 0,
                      height: widget.isSelected ? t.spaceLg : 0,
                      margin: EdgeInsets.only(
                        right: widget.isSelected ? t.spaceMd : 0,
                      ),
                      decoration: BoxDecoration(
                        color: t.accentPrimary,
                        borderRadius: BorderRadius.circular(t.radiusPill),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: t.cardTitle.copyWith(
                        fontWeight:
                            widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: widget.isSelected
                            ? t.accentPrimary
                            : t.inkPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: t.spaceSm),
                  ExcludeSemantics(
                    child: AnimatedContainer(
                      duration: reduceMotion ? Duration.zero : t.motionFast,
                      curve: t.motionCurve,
                      padding: EdgeInsets.symmetric(
                        horizontal: t.spaceMd,
                        vertical: t.spaceXs + t.radiusXs,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? t.accentPrimary
                            : t.subtleSurface,
                        borderRadius: BorderRadius.circular(t.radiusPill),
                        border: isHC && !widget.isSelected
                            ? Border.all(
                                color: t.borderSubtle,
                                width: t.hairlineWidth,
                              )
                            : null,
                      ),
                      child: Text(
                        widget.code.toUpperCase(),
                        style: t.overlineIndex.copyWith(
                          letterSpacing: 1.0,
                          color: widget.isSelected ? t.onAccent : t.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bingkai fokus dua lapis yang konsisten dan bebas pergeseran tata letak.
class _SwissFocusFrame extends StatelessWidget {
  final bool isFocused;
  final SigumiTokens tokens;
  final double? radius;
  final Widget child;

  const _SwissFocusFrame({
    required this.isFocused,
    required this.tokens,
    this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? tokens.radiusSm;
    return Container(
      padding: EdgeInsets.all(tokens.radiusXs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius + tokens.radiusXs),
        border: Border.all(
          color: isFocused ? tokens.focusRing : Colors.transparent,
          width: tokens.focusRingWidth,
        ),
      ),
      child: child,
    );
  }
}

/// Highlight ambient biru & kuning transparan ala HomeScreen yang mengorbit
/// simetris dan halus untuk bertukar posisi saat slide berpindah.
class _OnboardingAmbientPainter extends CustomPainter {
  final double pageProgress;
  final Color blueColor;
  final Color yellowColor;

  const _OnboardingAmbientPainter({
    required this.pageProgress,
    required this.blueColor,
    required this.yellowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final double clamped = pageProgress.clamp(0.0, 2.0);
    // Orbit elips kontinu C-infinity: setiap pindah slide berotasi 180° searah
    // jarum jam sehingga biru dan kuning bertukar posisi dengan mulus & rapi.
    final double theta = -math.pi / 4.0 + (math.pi * clamped);
    final double rx = size.width * 0.44;
    final double ry = size.height * 0.36;
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);

    final Offset bluePos = Offset(
      center.dx + rx * math.cos(theta),
      center.dy + ry * math.sin(theta),
    );
    final Offset yellowPos = Offset(
      center.dx - rx * math.cos(theta),
      center.dy - ry * math.sin(theta),
    );

    // Denyut radius halus hanya di tengah perpindahan slide (sinusoidal mulus)
    final double transitionPulse = math.sin(math.pi * clamped).abs();
    final double baseDim = math.min(size.width, size.height);
    final double radiusBoost = 1.0 + (0.06 * transitionPulse);
    final double alphaBoost = 0.02 * transitionPulse;

    _drawSoftOrb(
      canvas,
      center: bluePos,
      radius: baseDim * 0.88 * radiusBoost,
      color: blueColor,
      opacity: 0.13 + alphaBoost,
    );
    _drawSoftOrb(
      canvas,
      center: yellowPos,
      radius: baseDim * 0.84 * radiusBoost,
      color: yellowColor,
      opacity: 0.125 + alphaBoost,
    );
  }

  void _drawSoftOrb(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.42),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingAmbientPainter oldDelegate) {
    return oldDelegate.pageProgress != pageProgress ||
        oldDelegate.blueColor != blueColor ||
        oldDelegate.yellowColor != yellowColor;
  }
}

