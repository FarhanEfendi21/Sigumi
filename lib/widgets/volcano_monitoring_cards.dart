import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/fonts.dart';
import '../config/theme_extensions.dart';
import '../models/volcano_model.dart';
import '../models/volcano_summarizer.dart';
import '../services/localization_service.dart';

const String kDefaultMagmaActivityUrl =
    'https://magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas';

/// Format tanggal laporan MAGMA Indonesia secara konsisten (mis. `19 November 2026`).
String formatMagmaReportDate(DateTime date) {
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

String _romanLevel(int levelCode) {
  switch (levelCode) {
    case 1:
      return 'I';
    case 2:
      return 'II';
    case 3:
      return 'III';
    case 4:
      return 'IV';
    default:
      return '$levelCode';
  }
}

String _levelName(int levelCode) {
  switch (levelCode) {
    case 1:
      return 'Normal';
    case 2:
      return 'Waspada';
    case 3:
      return 'Siaga';
    case 4:
      return 'Awas';
    default:
      return 'Tidak Diketahui';
  }
}

Future<void> openMagmaExternalUrl(String? urlString) async {
  final target =
      (urlString != null && urlString.trim().isNotEmpty)
          ? urlString.trim()
          : kDefaultMagmaActivityUrl;
  try {
    final uri = Uri.tryParse(target);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('[MagmaMonitoring] Gagal buka URL $target: $e');
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 1. HEADER VISUAL VAR MAGMA (Foto + Level Status I–IV + Periode + Pill VONA)
// ══════════════════════════════════════════════════════════════════════════════

class MagmaVisualHeaderCard extends StatelessWidget {
  final VolcanoModel volcano;
  final VolcanoSummarizer? summary;
  final bool isLoading;

  const MagmaVisualHeaderCard({
    super.key,
    required this.volcano,
    required this.summary,
    this.isLoading = false,
  });

  String? get _validNetworkPhotoUrl {
    final raw = summary?.visualPhotoUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAbsolutePath) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    return raw;
  }

  String? get _fallbackAssetPath {
    final name = volcano.name.toLowerCase();
    if (name.contains('merapi')) return 'assets/images/merapi.jpg';
    if (name.contains('agung')) return 'assets/images/agung.jpg';
    if (name.contains('rinjani')) return 'assets/images/rinjani.jpg';
    return null;
  }

  Color _vonaColor(BuildContext context, String? code) {
    switch (code) {
      case 'GREEN':
        return context.adaptUiColor(const Color(0xFF16A34A));
      case 'YELLOW':
        return const Color(0xFFEAB308);
      case 'ORANGE':
        return const Color(0xFFF97316);
      case 'RED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _showPhotoLightbox(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _buildGradientBackdrop(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildGradientBackdrop() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172554), Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.volcano_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    final asset = _fallbackAssetPath;
    if (asset == null) return _buildGradientBackdrop();
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildGradientBackdrop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSummary = summary;
    final levelCode = activeSummary?.levelCode ?? volcano.statusLevel;
    final statusColor = context.statusColor(levelCode);
    final statusShape = context.statusShape(levelCode);
    final levelRoman = activeSummary?.levelRoman ?? _romanLevel(levelCode);
    final levelLabel = activeSummary?.levelLabel ?? _levelName(levelCode);
    final vonaCode = activeSummary?.normalizedVonaCode;
    final vonaColor = _vonaColor(context, vonaCode);
    final photoUrl = _validNetworkPhotoUrl;
    final isHC = context.isHighContrast;

    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: context.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Area Foto Visual + Overlay Status, VONA & Periode ──
          GestureDetector(
            onTap:
                photoUrl != null
                    ? () => _showPhotoLightbox(context, photoUrl)
                    : null,
            child: SizedBox(
              height: 238,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl != null)
                    Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildFallbackImage(),
                            Container(
                              color: Colors.black.withValues(alpha: 0.28),
                              child: const Center(
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      errorBuilder: (_, __, ___) => _buildFallbackImage(),
                    )
                  else
                    _buildFallbackImage(),

                  // Scrim gelap agar teks & badge di atas foto selalu kontras
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0x99080B10),
                            const Color(0x2E080B10),
                            const Color(0xE8080B10),
                          ],
                          stops: const [0.0, 0.42, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Baris Atas: Badge Level Status (I–IV) + Pill VONA Color Code
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _OverlayPill(
                          backgroundColor: const Color(0xD90B1018),
                          borderColor: statusColor.withValues(alpha: 0.72),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusShape, size: 12, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                'LEVEL $levelRoman · ${levelLabel.toUpperCase()}',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.35,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label:
                              vonaCode != null
                                  ? 'VONA $vonaCode'
                                  : context.trText('VONA belum dirilis'),
                          child: _OverlayPill(
                            backgroundColor:
                                vonaCode != null
                                    ? vonaColor.withValues(alpha: 0.24)
                                    : const Color(0xCC0B1018),
                            borderColor: vonaColor.withValues(alpha: 0.8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flight_rounded,
                                  size: 12,
                                  color:
                                      vonaCode != null
                                          ? vonaColor
                                          : const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  vonaCode != null
                                      ? 'VONA · $vonaCode'
                                      : 'VONA · —',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.35,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bagian Bawah: Tag Foto + Nama Gunung + Periode Pengamatan Asli
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              photoUrl != null
                                  ? Icons.photo_camera_rounded
                                  : Icons.photo_library_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                photoUrl != null
                                    ? context.trText(
                                      'Foto visual VAR MAGMA · Ketuk untuk perbesar',
                                    )
                                    : context.trText(
                                      'Foto referensi · Menunggu foto VAR MAGMA',
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                volcano.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${volcano.elevation.toInt()} mdpl',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (activeSummary != null)
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 12.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${formatMagmaReportDate(activeSummary.reportDate)}  ·  ${activeSummary.periodDisplay}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (isLoading)
                          Row(
                            children: [
                              const SizedBox(
                                width: 11,
                                height: 11,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                context.trText(
                                  'Memuat periode pengamatan MAGMA...',
                                ),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.clock,
                                size: 12.5,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  context.trText(
                                    'Menunggu pembaruan laporan VAR MAGMA',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.86),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Footer Atribusi Resmi MAGMA Indonesia ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            color: context.bgSurface,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 14,
                  color: context.accentPrimary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.trText('Sumber resmi MAGMA Indonesia · PVMBG'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    openMagmaExternalUrl(activeSummary?.detailUrl);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isHC
                              ? context.accentPrimary
                              : context.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MAGMA',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isHC
                                    ? context.onAccentPrimary
                                    : context.accentPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          CupertinoIcons.arrow_up_right,
                          size: 11,
                          color:
                              isHC
                                  ? context.onAccentPrimary
                                  : context.accentPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms, curve: Curves.easeOut);
  }
}

class _OverlayPill extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  const _OverlayPill({
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. KARTU PENGAMATAN VISUAL (Visibilitas, Asap Kawah, Guguran/Awan Panas)
// ══════════════════════════════════════════════════════════════════════════════

class MagmaVisualObservationCard extends StatelessWidget {
  final VolcanoSummarizer? summary;
  final bool isLoading;

  const MagmaVisualObservationCard({
    super.key,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final observation =
        summary?.resolvedVisualObservation ?? const VolcanoVisualObservation();
    final hasAvalanche =
        observation.avalancheNotes != null &&
        observation.avalancheNotes!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  size: 18,
                  color: context.accentPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trText('Pengamatan Visual'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      context.trText(
                        'Kondisi puncak, asap kawah, dan aktivitas permukaan',
                      ),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading && summary == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const CupertinoActivityIndicator(radius: 10),
                  const SizedBox(width: 10),
                  Text(
                    context.trText('Memuat pengamatan visual PVMBG...'),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _VisualObservationTile(
              icon: Icons.landscape_rounded,
              iconColor: const Color(0xFF0284C7),
              label: context.trText('Visibilitas'),
              value:
                  observation.visibility ??
                  context.trText('Belum tercatat pada laporan terbaru.'),
              isPlaceholder: observation.visibility == null,
            ),
            const SizedBox(height: 9),
            _VisualObservationTile(
              icon: Icons.cloud_outlined,
              iconColor: context.adaptUiColor(const Color(0xFF0D9488)),
              label: context.trText('Kondisi Asap Kawah'),
              value:
                  observation.craterSmoke ??
                  context.trText('Tidak teramati atau belum tercatat.'),
              isPlaceholder: observation.craterSmoke == null,
            ),
            const SizedBox(height: 9),
            _VisualObservationTile(
              icon: Icons.warning_amber_rounded,
              iconColor:
                  hasAvalanche ? const Color(0xFFEA580C) : context.textTertiary,
              label: context.trText('Catatan Guguran / Awan Panas'),
              value:
                  observation.avalancheNotes ??
                  context.trText(
                    'Tidak teramati guguran lava atau awan panas.',
                  ),
              isPlaceholder: !hasAvalanche,
              highlight: hasAvalanche,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 340.ms, curve: Curves.easeOut);
  }
}

class _VisualObservationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isPlaceholder;
  final bool highlight;

  const _VisualObservationTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isPlaceholder = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final tileBg =
        highlight && !isHC
            ? iconColor.withValues(alpha: 0.07)
            : context.bgSecondary;
    final tileBorder =
        highlight && !isHC
            ? iconColor.withValues(alpha: 0.28)
            : context.borderColor.withValues(alpha: 0.6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tileBorder,
          width: isHC ? context.borderWidth : 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: highlight ? iconColor : context.textTertiary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight:
                        isPlaceholder ? FontWeight.w400 : FontWeight.w600,
                    color:
                        isPlaceholder
                            ? context.textSecondary
                            : context.textPrimary,
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

// ══════════════════════════════════════════════════════════════════════════════
// 3. KARTU KEGEMPAAN HARIAN (Guguran, Hembusan, Vulkanik, Tektonik)
// ══════════════════════════════════════════════════════════════════════════════

class MagmaDailySeismicityCard extends StatelessWidget {
  final VolcanoSummarizer? summary;
  final bool isLoading;

  const MagmaDailySeismicityCard({
    super.key,
    required this.summary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final seismicity =
        summary?.resolvedSeismicity ?? const VolcanoSeismicitySummary();

    final items = [
      _SeismicTileData(
        label: context.trText('Guguran'),
        icon: Icons.terrain_rounded,
        accent: const Color(0xFFEA580C),
        metric: seismicity.guguran,
      ),
      _SeismicTileData(
        label: context.trText('Hembusan'),
        icon: Icons.air_rounded,
        accent: const Color(0xFF0284C7),
        metric: seismicity.hembusan,
      ),
      _SeismicTileData(
        label: context.trText('Vulkanik'),
        icon: Icons.volcano_rounded,
        accent: const Color(0xFFDC2626),
        metric: seismicity.vulkanik,
      ),
      _SeismicTileData(
        label: context.trText('Tektonik'),
        icon: Icons.waves_rounded,
        accent: const Color(0xFF4F46E5),
        metric: seismicity.tektonik,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  size: 18,
                  color: Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trText('Kegempaan Harian'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      context.trText('Jumlah kejadian terekam seismograf'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (seismicity.hasAnyData)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${seismicity.totalEvents} ${context.trText('kejadian')}',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.accentPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading && summary == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const CupertinoActivityIndicator(radius: 10),
                  const SizedBox(width: 10),
                  Text(
                    context.trText('Memuat data kegempaan PVMBG...'),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      items
                          .map(
                            (item) => SizedBox(
                              width: tileWidth,
                              child: _SeismicMetricTile(data: item),
                            ),
                          )
                          .toList(),
                );
              },
            ),
            if (!seismicity.hasAnyData) ...[
              const SizedBox(height: 11),
              Text(
                context.trText(
                  'Rincian jumlah gempa belum tercantum pada laporan terbaru.',
                ),
                style: AppFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: context.textSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(duration: 360.ms, curve: Curves.easeOut);
  }
}

class _SeismicTileData {
  final String label;
  final IconData icon;
  final Color accent;
  final VolcanoSeismicMetric? metric;

  const _SeismicTileData({
    required this.label,
    required this.icon,
    required this.accent,
    required this.metric,
  });
}

class _SeismicMetricTile extends StatelessWidget {
  final _SeismicTileData data;

  const _SeismicMetricTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final metric = data.metric;
    final hasCount = metric != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.65),
          width: context.isHighContrast ? context.borderWidth : 0.7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(data.icon, size: 14, color: data.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hasCount ? '${metric.count}' : '—',
                style: AppFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: hasCount ? context.textPrimary : context.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (hasCount) ...[
                const SizedBox(width: 5),
                Text(
                  context.trText('kali'),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (metric?.detail != null && metric!.detail!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              metric.detail!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakartaSans(
                fontSize: 10.5,
                height: 1.35,
                color: context.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
