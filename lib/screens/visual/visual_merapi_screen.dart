import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/fonts.dart';
import '../../config/theme_extensions.dart';
import '../../models/volcano_model.dart';
import '../../models/volcano_summarizer.dart';
import '../../providers/volcano_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/hiking_weather_card.dart';
import '../../widgets/volcano_monitoring_cards.dart';
import '../../widgets/volcano_summarizer_widget.dart';

class VisualMerapiScreen extends StatefulWidget {
  final VolcanoModel? volcano;
  final String? volcanoId;

  const VisualMerapiScreen({super.key, this.volcano, this.volcanoId});

  @override
  State<VisualMerapiScreen> createState() => _VisualMerapiScreenState();
}

class _VisualMerapiScreenState extends State<VisualMerapiScreen> {
  String? _fetchedVolcanoKey;
  int _weatherRefreshVersion = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleSummaryFetchIfNeeded();
  }

  @override
  void didUpdateWidget(covariant VisualMerapiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.volcano?.id != widget.volcano?.id ||
        oldWidget.volcano?.name != widget.volcano?.name) {
      _scheduleSummaryFetchIfNeeded();
    }
  }

  VolcanoModel _resolveVolcano(
    BuildContext context, {
    VolcanoProvider? provider,
  }) {
    if (widget.volcano != null) return widget.volcano!;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is VolcanoModel) return args;
    return (provider ?? context.read<VolcanoProvider>()).volcano;
  }

  String? _volcanoKeyFor(VolcanoModel volcano) {
    final identity = '${volcano.name} ${volcano.id}'.toLowerCase();
    if (identity.contains('merapi') || volcano.id == VolcanoModel.kMerapiUuid) {
      return 'merapi';
    }
    if (identity.contains('agung') || volcano.id == VolcanoModel.kAgungUuid) {
      return 'agung';
    }
    if (identity.contains('rinjani') ||
        volcano.id == VolcanoModel.kRinjaniUuid) {
      return 'rinjani';
    }
    return null;
  }

  String? _weatherRegionForVolcano(VolcanoModel volcano) {
    final identity = '${volcano.name} ${volcano.id}'.toLowerCase();
    if (identity.contains('merapi')) return 'merapi';
    if (identity.contains('agung')) return 'bali';
    if (identity.contains('rinjani')) return 'lombok';
    return null;
  }

  void _scheduleSummaryFetchIfNeeded() {
    final volcano = _resolveVolcano(context);
    final key = _volcanoKeyFor(volcano);
    if (key == null || key == _fetchedVolcanoKey) return;
    _fetchedVolcanoKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VolcanoProvider>().fetchLatestVolcanoSummary(key);
    });
  }

  Future<void> _refreshAll(String? volcanoKey) async {
    if (mounted) {
      setState(() => _weatherRefreshVersion++);
    }
    if (volcanoKey != null) {
      await context.read<VolcanoProvider>().fetchLatestVolcanoSummary(
        volcanoKey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VolcanoProvider>();
    final volcano = _resolveVolcano(context, provider: provider);
    final volcanoKey = _volcanoKeyFor(volcano);
    final weatherRegion = _weatherRegionForVolcano(volcano);
    final isHC = provider.highContrast;

    final VolcanoSummarizer? latestSummary =
        volcanoKey != null &&
                provider.latestVolcanoSummary?.volcanoKey.toLowerCase() ==
                    volcanoKey
            ? provider.latestVolcanoSummary
            : null;

    final pageBg = isHC ? context.bgPrimary : const Color(0xFFF6F7F9);
    final appBarBg = isHC ? context.bgPrimary : Colors.white;
    final appBarFg = isHC ? Colors.white : const Color(0xFF1E1E2C);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(
          context.trText('Pantauan Gunung'),
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: appBarFg,
          ),
        ),
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarFg),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed:
                provider.isLoadingSummaries
                    ? null
                    : () => _refreshAll(volcanoKey),
            tooltip: context.trText('Perbarui data pantauan'),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(volcanoKey),
        color: context.accentPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Visual VAR MAGMA (Foto + Level I–IV + Periode + VONA)
              MagmaVisualHeaderCard(
                volcano: volcano,
                summary: latestSummary,
                isLoading: provider.isLoadingSummaries,
              ),
              const SizedBox(height: 16),

              if (volcanoKey != null) ...[
                // 2. Kartu Pengamatan Visual (Visibilitas, Asap Kawah, Guguran/APG)
                MagmaVisualObservationCard(
                  summary: latestSummary,
                  isLoading: provider.isLoadingSummaries,
                ),
                const SizedBox(height: 16),

                // 3. Kartu Kegempaan Harian (Guguran, Hembusan, Vulkanik, Tektonik)
                MagmaDailySeismicityCard(
                  summary: latestSummary,
                  isLoading: provider.isLoadingSummaries,
                ),
                const SizedBox(height: 20),
              ],

              // 4. Prakiraan Cuaca BMKG
              if (weatherRegion != null)
                HikingWeatherCard(
                  latitude: volcano.latitude,
                  longitude: volcano.longitude,
                  cacheRegion: weatherRegion,
                  canFetch: true,
                  refreshVersion: _weatherRefreshVersion,
                )
              else
                _buildWeatherUnavailableCard(),

              // 5. Laporan Aktivitas PVMBG & Arsip 30 Hari (tanpa double fetch)
              if (volcanoKey != null) ...[
                const SizedBox(height: 24),
                VolcanoLatestSummaryWithHistoryButton(
                  volcanoKey: volcanoKey,
                  limit: 30,
                  title: context.tr('activity_report'),
                  autoFetch: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherUnavailableCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: context.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.trText('Prakiraan cuaca'),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.trText(
                    'Prakiraan BMKG belum tersedia untuk gunung ini.',
                  ),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
