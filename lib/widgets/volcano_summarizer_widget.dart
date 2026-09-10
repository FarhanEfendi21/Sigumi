import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/fonts.dart';
import '../../models/volcano_summarizer.dart';
import '../../providers/volcano_provider.dart';

/// Widget untuk menampilkan ringkasan aktivitas gunung dari tabel volcano_summarizer
class VolcanoSummarizerCard extends StatelessWidget {
  final VolcanoSummarizer summary;

  const VolcanoSummarizerCard({super.key, required this.summary});

  /// Mendapatkan color berdasarkan level status
  Color _getLevelColor() {
    return Color(summary.levelColor);
  }

  /// Mendapatkan icon berdasarkan level status
  IconData _getLevelIcon() {
    switch (summary.levelCode) {
      case 1:
        return Icons.check_circle_rounded;
      case 2:
        return Icons.warning_rounded;
      case 3:
        return Icons.warning_amber_rounded;
      case 4:
        return Icons.emergency_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor();
    final isDarkLevel = summary.levelCode >= 3;

    return Container(
      decoration: BoxDecoration(
        color: Color(summary.levelColor).withValues(alpha: 0.1),
        border: Border.all(color: levelColor.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header dengan status level ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getLevelIcon(), color: levelColor, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.volcanoName,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1E2C),
                          ),
                        ),
                        Text(
                          summary.levelLabel,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: levelColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level ${summary.levelCode}',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: levelColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Tanggal laporan ──
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  '${summary.reportDate.day}/${summary.reportDate.month}/${summary.reportDate.year}',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  summary.periodStart ?? 'N/A',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Ringkasan aktivitas ──
            if (summary.summary != null) ...[
              Text(
                summary.summary!,
                style: AppFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.5,
                  color: const Color(0xFF1E1E2C),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // ── Weather Info Grid ──
            if (summary.weather != null ||
                summary.windDirection != null ||
                summary.tempMin != null ||
                summary.humidityMin != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summary.weather != null)
                      _buildWeatherItem(
                        icon: Icons.cloud_rounded,
                        label: 'Cuaca',
                        value: summary.weather!,
                      ),
                    if (summary.windDirection != null) ...[
                      const SizedBox(height: 6),
                      _buildWeatherItem(
                        icon: Icons.air_rounded,
                        label: 'Arah Angin',
                        value: summary.windDirection!,
                      ),
                    ],
                    if (summary.windSpeedText != null) ...[
                      const SizedBox(height: 6),
                      _buildWeatherItem(
                        icon: Icons.speed_rounded,
                        label: 'Kecepatan Angin',
                        value: summary.windSpeedText!,
                      ),
                    ],
                    if (summary.temperatureRange != null) ...[
                      const SizedBox(height: 6),
                      _buildWeatherItem(
                        icon: Icons.thermostat_rounded,
                        label: 'Suhu',
                        value: summary.temperatureRange!,
                      ),
                    ],
                    if (summary.humidityRange != null) ...[
                      const SizedBox(height: 6),
                      _buildWeatherItem(
                        icon: Icons.opacity_rounded,
                        label: 'Kelembaban',
                        value: summary.humidityRange!,
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── Footer dengan author ──
            if (summary.author != null || summary.detailUrl != null)
              Row(
                children: [
                  if (summary.author != null)
                    Expanded(
                      child: Text(
                        'Sumber: ${summary.author}',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (summary.detailUrl != null)
                    InkWell(
                      onTap: () {
                        // TODO: Implementasi buka URL
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Detail',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: levelColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildWeatherItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: AppFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey.shade900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Widget untuk menampilkan list ringkasan aktivitas gunung
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
                color: const Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 14),

            if (provider.isLoadingSummaries)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat data ringkasan...',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Belum ada data ringkasan aktivitas',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.amber.shade900,
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

/// Widget untuk menampilkan ringkasan terbaru saja
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.redAccent,
                ),
              ),
            ),
          );
        }

        if (latest == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada data ringkasan terbaru',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey.shade700,
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

/// Widget kombinasi Latest + Button untuk lihat riwayat
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

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final latest = provider.latestVolcanoSummary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title ?? 'Ringkasan Aktivitas Terbaru',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E2C),
                  ),
                ),
                // ── Button Lihat Riwayat ──
                InkWell(
                  onTap: () {
                    // Fetch data riwayat sebelum membuka bottom sheet
                    provider.fetchVolcanoSummaries(
                      widget.volcanoKey,
                      limit: widget.limit,
                    );
                    _showHistoryBottomSheet(context, provider);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Riwayat',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Latest Card ──
            if (provider.isLoadingSummaries)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat data ringkasan...',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (latest == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Belum ada data ringkasan terbaru',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              VolcanoSummarizerCard(summary: latest),
          ],
        );
      },
    );
  }

  /// Menampilkan bottom sheet dengan riwayat lengkap
  void _showHistoryBottomSheet(BuildContext context, VolcanoProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Aktivitas',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E2C),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ringkasan aktivitas gunung harian (30 hari terakhir)',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Content ──
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Consumer<VolcanoProvider>(
                          builder: (context, provider, _) {
                            if (provider.isLoadingSummaries) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Memuat riwayat...',
                                      style: AppFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (!provider.hasVolcanoSummaries) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_rounded,
                                        color: Colors.amber.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Belum ada data riwayat aktivitas',
                                          style: AppFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.volcanoSummaries.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final summary =
                                    provider.volcanoSummaries[index];
                                return VolcanoSummarizerCard(summary: summary);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
    ).then((_) {
      // Fetch ulang latest saat bottom sheet ditutup
      provider.fetchLatestVolcanoSummary(widget.volcanoKey);
    });
  }
}
