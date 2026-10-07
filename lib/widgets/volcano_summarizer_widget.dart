import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/fonts.dart';
import '../../config/theme_extensions.dart';
import '../../models/volcano_summarizer.dart';
import '../../providers/volcano_provider.dart';

// ── Helpers Format ────────────────────────────────────────────────────────────

String _formatDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

Color _getStatusColor(int levelCode) {
  switch (levelCode) {
    case 1:
      return const Color(0xFF34C759); // iOS Green (Normal)
    case 2:
      return const Color(0xFFFF9500); // iOS Amber (Waspada)
    case 3:
      return const Color(0xFFFF6A00); // iOS Orange (Siaga)
    case 4:
      return const Color(0xFFFF3B30); // iOS Red (Awas)
    default:
      return const Color(0xFF8E8E93); // iOS Neutral Gray
  }
}

Future<void> _openExternalUrl(String urlString) async {
  try {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('[VolcanoSummarizer] Gagal buka URL $urlString: $e');
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. KARTU RINGKASAN AKTIVITAS (Apple HIG Minimalist Card)
// ══════════════════════════════════════════════════════════════════════════════

/// Kartu ringkasan aktivitas gunung dengan hierarki visual Apple HIG:
/// - Status level pill dengan visual dot indicator
/// - Tipografi berjenjang jelas (Title → Periode → Narasi → Metrik)
/// - Grid cuaca & parameter pengamatan bergaya iOS glance widget
/// - Footer atribusi resmi PVMBG
class VolcanoSummarizerCard extends StatefulWidget {
  final VolcanoSummarizer summary;
  final bool isCompact;
  final bool initiallyExpanded;

  const VolcanoSummarizerCard({
    super.key,
    required this.summary,
    this.isCompact = false,
    this.initiallyExpanded = false,
  });

  @override
  State<VolcanoSummarizerCard> createState() => _VolcanoSummarizerCardState();
}

class _VolcanoSummarizerCardState extends State<VolcanoSummarizerCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant VolcanoSummarizerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary.id != widget.summary.id) {
      _isExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final statusColor = context.adaptUiColor(_getStatusColor(summary.levelCode));

    // Kumpulkan metrik observasi yang tersedia
    final metrics = <_ObservationMetric>[];
    if (summary.weather != null && summary.weather!.trim().isNotEmpty) {
      metrics.add(
        _ObservationMetric(
          icon: CupertinoIcons.cloud_sun_fill,
          iconColor: const Color(0xFF007AFF),
          label: 'Cuaca',
          value: summary.weather!,
        ),
      );
    }
    if (summary.temperatureRange != null) {
      metrics.add(
        _ObservationMetric(
          icon: CupertinoIcons.thermometer,
          iconColor: const Color(0xFFFF9500),
          label: 'Suhu',
          value: summary.temperatureRange!,
        ),
      );
    }
    if (summary.windDirection != null &&
        summary.windDirection!.trim().isNotEmpty) {
      final speedInfo =
          (summary.windSpeedText != null &&
                  summary.windSpeedText!.trim().isNotEmpty)
              ? ' (${summary.windSpeedText})'
              : '';
      metrics.add(
        _ObservationMetric(
          icon: CupertinoIcons.wind,
          iconColor: const Color(0xFF5856D6),
          label: 'Arah Angin',
          value: '${summary.windDirection}$speedInfo',
        ),
      );
    }
    if (summary.humidityRange != null) {
      metrics.add(
        _ObservationMetric(
          icon: CupertinoIcons.drop_fill,
          iconColor: context.adaptUiColor(const Color(0xFF34C759)),
          label: 'Kelembaban',
          value: summary.humidityRange!,
        ),
      );
    }
    if (summary.pressureRange != null) {
      metrics.add(
        _ObservationMetric(
          icon: CupertinoIcons.gauge,
          iconColor: const Color(0xFF8E8E93),
          label: 'Tekanan',
          value: '${summary.pressureRange} mmHg',
        ),
      );
    }



    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Card ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Nama Gunung + Pill Status Level
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        summary.volcanoName,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // iOS Pill Badge Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Level ${summary.levelCode} • ${summary.levelLabel.toUpperCase()}',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Baris Tanggal & Jam Pengamatan
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 13,
                      color: context.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(summary.reportDate),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textTertiary,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.clock,
                      size: 13,
                      color: context.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '00.00',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Parameter Cuaca & Lingkungan (iOS Glance Grid) ──
          if (metrics.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        metrics.map((m) {
                          return SizedBox(
                            width: itemWidth,
                            child: _ObservationMetricTile(metric: m),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Narasi Ringkasan Aktivitas (Dropdown / Collapsible) ──
          if (summary.summary != null &&
              summary.summary!.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: 0.6),
                    width: 0.6,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tombol Dropdown Header
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: context.accentPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  CupertinoIcons.text_alignleft,
                                  size: 13,
                                  color: context.accentPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Catatan Aktivitas PVMBG',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.bgSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: context.borderColor.withValues(
                                      alpha: 0.6,
                                    ),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isExpanded ? 'Tutup' : 'Buka',
                                      style: AppFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: context.accentPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AnimatedRotation(
                                      turns: _isExpanded ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeInOut,
                                      child: Icon(
                                        CupertinoIcons.chevron_down,
                                        size: 11,
                                        color: context.accentPrimary,
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

                    // Konten Teks Dropdown
                    AnimatedCrossFade(
                      firstChild: const SizedBox(
                        width: double.infinity,
                        height: 0,
                      ),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: context.borderColor.withValues(alpha: 0.6),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Text(
                              summary.summary!.trim(),
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12.5,
                                height: 1.55,
                                color: context.textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      crossFadeState:
                          _isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 220),
                      sizeCurve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Divider Halus Apple ──
          Divider(
            height: 1,
            thickness: context.borderWidth,
            color: context.borderColor,
          ),

          // ── Footer Metadata Sumber & Detail ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 13,
                  color: context.accentPrimary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    summary.author != null && summary.author!.trim().isNotEmpty
                        ? 'Penyusun: ${summary.author}'
                        : 'Pusat Vulkanologi & Mitigasi Bencana Geologi (PVMBG)',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (summary.detailUrl != null &&
                    summary.detailUrl!.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openExternalUrl(summary.detailUrl!);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MAGMA',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.accentPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          CupertinoIcons.arrow_up_right,
                          size: 11,
                          color: context.accentPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── Model internal metrik observasi ──
class _ObservationMetric {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _ObservationMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
}

// ── Micro Tile Glance Metrik (iOS Apple Style) ──
class _ObservationMetricTile extends StatelessWidget {
  final _ObservationMetric metric;

  const _ObservationMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.5),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: metric.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(metric.icon, size: 15, color: metric.iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  metric.label.toUpperCase(),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: context.textTertiary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  metric.value,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. KOMPONEN UTAMA BERIKUT TOMBOL RIWAYAT (Apple HIG Section)
// ══════════════════════════════════════════════════════════════════════════════

/// Komponen Laporan Aktivitas dengan Card Terkini + Aksi Riwayat Terstruktur
class VolcanoLatestSummaryWithHistoryButton extends StatefulWidget {
  final String volcanoKey;
  final int limit;
  final String? title;

  const VolcanoLatestSummaryWithHistoryButton({
    super.key,
    required this.volcanoKey,
    this.limit = 30,
    this.title,
  });

  @override
  State<VolcanoLatestSummaryWithHistoryButton> createState() =>
      _VolcanoLatestSummaryWithHistoryButtonState();
}

class _VolcanoLatestSummaryWithHistoryButtonState
    extends State<VolcanoLatestSummaryWithHistoryButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolcanoProvider>().fetchLatestVolcanoSummary(
        widget.volcanoKey,
      );
    });
  }

  void _openHistory(BuildContext context, VolcanoProvider provider) {
    HapticFeedback.lightImpact();
    provider.fetchVolcanoSummaries(widget.volcanoKey, limit: widget.limit);
    _showHistoryBottomSheet(context, provider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final latest = provider.latestVolcanoSummary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Header ala Apple HIG ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'Laporan Aktivitas',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ringkasan pengamatan harian dari pos PVMBG',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Pill Riwayat Header
                GestureDetector(
                  onTap: () => _openHistory(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.accentPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.accentPrimary.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.time,
                          size: 13,
                          color: context.accentPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Riwayat',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Card Laporan Terkini ──
            if (provider.isLoadingSummaries)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: context.borderColor,
                    width: context.borderWidth,
                  ),
                ),
                child: Column(
                  children: [
                    const CupertinoActivityIndicator(radius: 12),
                    const SizedBox(height: 12),
                    Text(
                      'Memperbarui laporan terkini...',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else if (latest == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: context.borderColor,
                    width: context.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.textTertiary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.doc_text_search,
                        color: context.textTertiary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Belum ada laporan pengamatan yang dipublikasikan hari ini.',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 1.4,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              VolcanoSummarizerCard(summary: latest),

            // ── Aksi Riwayat Lengkap (Apple HIG Cell) ──
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _openHistory(context, provider),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.borderColor,
                    width: context.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: context.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        CupertinoIcons.calendar_badge_plus,
                        size: 16,
                        color: context.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arsip Laporan 30 Hari',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Telusuri rekaman visual & cuaca sebelumnya',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 11,
                              color: context.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 15,
                      color: context.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Menampilkan bottom sheet dengan riwayat lengkap bergaya iOS
  void _showHistoryBottomSheet(BuildContext context, VolcanoProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                // ── Drag Handle iOS ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header Modal ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat Laporan Aktivitas',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Catatan arsip 30 hari terakhir',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: context.bgSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 14,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: context.borderWidth,
                  color: context.borderColor,
                ),

                // ── Daftar Riwayat ──
                Expanded(
                  child: Consumer<VolcanoProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoadingSummaries) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CupertinoActivityIndicator(radius: 12),
                                const SizedBox(height: 12),
                                Text(
                                  'Memuat riwayat arsip...',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!provider.hasVolcanoSummaries) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: context.bgSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.doc_text_search,
                                    size: 28,
                                    color: context.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum Ada Riwayat',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Belum ditemukan data laporan aktivitas sebelumnya.',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: provider.volcanoSummaries.length,
                        separatorBuilder:
                            (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final summary = provider.volcanoSummaries[index];
                          return VolcanoSummarizerCard(summary: summary);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    ).then((_) {
      provider.fetchLatestVolcanoSummary(widget.volcanoKey);
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. WIDGET STANDALONE LAINNYA
// ══════════════════════════════════════════════════════════════════════════════

/// Widget untuk menampilkan list ringkasan aktivitas gunung (standalone)
class VolcanoSummarizerListSection extends StatefulWidget {
  final String volcanoKey;
  final int limit;
  final String? title;

  const VolcanoSummarizerListSection({
    super.key,
    required this.volcanoKey,
    this.limit = 30,
    this.title,
  });

  @override
  State<VolcanoSummarizerListSection> createState() =>
      _VolcanoSummarizerListSectionState();
}

class _VolcanoSummarizerListSectionState
    extends State<VolcanoSummarizerListSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolcanoProvider>().fetchVolcanoSummaries(
        widget.volcanoKey,
        limit: widget.limit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title ?? 'Ringkasan Aktivitas Harian',
              style: AppFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            if (provider.isLoadingSummaries)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const CupertinoActivityIndicator(radius: 12),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat data ringkasan...',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (!provider.hasVolcanoSummaries)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.borderColor,
                    width: context.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: context.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Belum ada data ringkasan aktivitas.',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.volcanoSummaries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final summary = provider.volcanoSummaries[index];
                  return VolcanoSummarizerCard(summary: summary);
                },
              ),
          ],
        );
      },
    );
  }
}

/// Widget untuk menampilkan ringkasan terbaru saja (standalone)
class VolcanoLatestSummaryCard extends StatefulWidget {
  final String volcanoKey;
  final bool autoRefresh;

  const VolcanoLatestSummaryCard({
    super.key,
    required this.volcanoKey,
    this.autoRefresh = true,
  });

  @override
  State<VolcanoLatestSummaryCard> createState() =>
      _VolcanoLatestSummaryCardState();
}

class _VolcanoLatestSummaryCardState extends State<VolcanoLatestSummaryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VolcanoProvider>().fetchLatestVolcanoSummary(
        widget.volcanoKey,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final latest = provider.latestVolcanoSummary;

        if (provider.isLoadingSummaries) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CupertinoActivityIndicator(radius: 12),
            ),
          );
        }

        if (latest == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.borderColor,
                width: context.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  color: context.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada data ringkasan terbaru.',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return VolcanoSummarizerCard(summary: latest);
      },
    );
  }
}
