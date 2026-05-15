import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../config/theme_extensions.dart';
import '../../config/volcano_data.dart';
import '../../models/volcano_model.dart';
import '../../providers/volcano_provider.dart';
import '../../services/location_service.dart';
import '../visual/visual_merapi_screen.dart';

import 'widgets/blur_top_bar.dart';
import 'widgets/map_controls.dart';
import 'widgets/primary_info_card.dart';
import 'widgets/risk_bottom_sheet.dart';

/// Peta Risiko — Menampilkan lokasi real-time user, gunung berapi,
/// dan zona bahaya. Semua gunung bisa diklik untuk informasi dasar.
/// Gunung utama (Merapi, Agung, Rinjani) dipantau penuh oleh Sigumi.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _glowController;
  bool _isMapFocused = false;

  // State untuk GPS error feedback
  bool _hasShownInitialError = false;

  // State untuk all volcanoes dan selected volcano
  List<VolcanoModel> _allVolcanoes = [];
  VolcanoModel? _selectedVolcano;

  // Gunung yang dipantau aktif oleh Sigumi — mendapat fitur penuh
  final Set<String> _monitoredVolcanoes = {
    'merapi_001',
    'agung_001',
    'rinjani_001',
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Load semua volcanoes dari data lokal
    _allVolcanoes = VolcanoData.getAll();

    // Inisialisasi lokasi real-time dan mulai tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  /// Inisialisasi GPS dan mulai tracking lokasi real-time
  Future<void> _initLocation() async {
    final locationService = context.read<LocationService>();

    // Listen ke perubahan lokasi untuk auto-update peta
    locationService.addListener(_onLocationChanged);

    await locationService.initialize();
    locationService.startTracking(distanceFilterMeters: 30);

    // Tampilkan error awal jika ada, tapi hanya sekali sebagai snackbar
    if (locationService.locationError != null && !_hasShownInitialError) {
      _hasShownInitialError = true;
      _showLocationSnackbar(
        locationService.locationError!,
        isError: true,
        showRetry:
            locationService.gpsStatus == GpsStatus.error ||
            locationService.gpsStatus == GpsStatus.denied,
      );
    }
  }

  /// Callback saat lokasi berubah dari LocationService
  void _onLocationChanged() {
    if (!mounted) return;
    final locationService = context.read<LocationService>();

    // Jika ada error baru yang belum pernah ditampilkan
    if (locationService.locationError != null) {
      if (locationService.gpsStatus == GpsStatus.error &&
          !_hasShownInitialError) {
        _hasShownInitialError = true;
        _showLocationSnackbar(
          locationService.locationError!,
          isError: true,
          showRetry: true,
        );
      }
    } else {
      // Error cleared — reset flag
      _hasShownInitialError = false;
    }
  }

  /// Tampilkan snackbar sementara untuk status GPS
  void _showLocationSnackbar(
    String message, {
    bool isError = false,
    bool showRetry = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.gps_off_rounded : Icons.gps_fixed_rounded,
              color: context.bgPrimary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppFonts.plusJakartaSans(
                  color: context.bgPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? context.warningColor : context.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.22,
          left: 16,
          right: 16,
        ),
        duration: duration,
        action:
            showRetry
                ? SnackBarAction(
                  label: 'Coba Lagi',
                  textColor: context.bgPrimary,
                  onPressed: () {
                    final ls = context.read<LocationService>();
                    ls.retryTracking();
                    _hasShownInitialError = false;
                  },
                )
                : null,
      ),
    );
  }

  @override
  void dispose() {
    try {
      context.read<LocationService>().removeListener(_onLocationChanged);
    } catch (_) {
      // Service mungkin sudah dispose
    }
    _glowController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  double _kmToMeter(double km) => km * 1000;

  /// Recenter peta ke posisi user saat ini
  void _recenterToUser(LocationService locationService) {
    locationService.refreshLocation().then((_) {
      if (mounted) {
        final pos = LatLng(locationService.userLat, locationService.userLng);
        _mapController.move(pos, 13);
      }
    });
  }

  // ───────────────────────────────────────────────────────
  // MARKER BUILDER — semua gunung bisa diklik
  // ───────────────────────────────────────────────────────

  /// Ambil nama pendek gunung untuk label pada marker
  /// Contoh: "Gunung Tangkuban Parahu" → "Tangkuban"
  String _shortName(String fullName) {
    String name = fullName
        .replaceAll(RegExp(r'\s*\(.*?\)'), '') // hapus keterangan (...)
        .replaceAll('Gunung ', '')
        .replaceAll('Anak ', '')
        .trim();
    // Ambil kata pertama saja untuk label ringkas
    return name.split(' ').first;
  }

  /// Build daftar marker untuk semua gunung berapi
  List<Marker> _buildVolcanoMarkers() {
    return _allVolcanoes.map((volcano) {
      final pos = LatLng(volcano.latitude, volcano.longitude);
      final isMonitored = _monitoredVolcanoes.contains(volcano.id);
      final isSelected = _selectedVolcano?.id == volcano.id;

      // Dimensi marker:
      // - Primary    : 52×52 (lingkaran penuh, compact)
      // - Secondary  : lebih lebar & tinggi untuk label nama di bawah ikon
      double markerW, markerH;
      if (isMonitored) {
        // Beri ruang vertikal lebih untuk label nama
        markerW = 72;
        markerH = 75;
      } else if (isSelected) {
        markerW = 80;
        markerH = 58;
      } else {
        markerW = 72;
        markerH = 50;
      }

      return Marker(
        point: pos,
        width: markerW,
        height: markerH,
        child: GestureDetector(
          onTap: () => _onVolcanoTap(volcano),
          child: _buildVolcanoMarkerWidget(volcano, isMonitored, isSelected),
        ),
      );
    }).toList();
  }

  /// Build widget marker berdasarkan 3 tier visual:
  ///  Tier 1 — Primary SELECTED   : besar, glow kuat, badge dot, animasi scale
  ///  Tier 2 — Primary UNSELECTED : sedang, status color, badge dot
  ///  Tier 3 — Secondary (semua)  : label marker — ikon + nama gunung
  ///           ↳ Selected: lebih besar, warna solid, animasi scale
  ///           ↳ Aktif   : warna status, ikon volcano
  ///           ↳ Normal  : warna earthy sepia, ikon landscape
  Widget _buildVolcanoMarkerWidget(
    VolcanoModel volcano,
    bool isMonitored,
    bool isSelected,
  ) {
    final statusColor = _getStatusColor(volcano.statusLevel);

    if (isSelected && isMonitored) {
      // ── Tier 1: Primary SELECTED ──
      final shortName = _shortName(volcano.name);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withAlpha(40),
                  border: Border.all(
                    color: statusColor.withAlpha(70),
                    width: 1,
                  ),
                ),
              ),
              // Main marker body
              Container(
                margin: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withAlpha(180),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volcano_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              // Badge dot "Dipantau" — pojok kanan atas
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Label Nama Berwarna Solid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              shortName,
              style: AppFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      )
          .animate()
          .scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1.0, 1.0),
            duration: 320.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 200.ms);
    } else if (isMonitored) {
      // ── Tier 2: Primary UNSELECTED ──
      final shortName = _shortName(volcano.name);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withAlpha(110),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.volcano_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              // Badge dot "Dipantau"
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(28),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          // Label Nama Berwarna Putih (transparan glassmorphism)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: statusColor.withAlpha(80), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(
              shortName,
              style: AppFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      );
    } else {
      // ── Tier 3: Secondary — Label Marker Style ──
      // Semua gunung non-utama pakai gaya unified: ikon bulat + label nama
      // Warna: status color untuk gunung aktif, sepia hangat untuk normal/dormant
      final isActive = volcano.statusLevel >= 2;
      final markerColor = isActive ? statusColor : const Color(0xFFB07245);
      final shortName = _shortName(volcano.name);

      final circleSize = isSelected ? 30.0 : 25.0;
      final iconSize = isSelected ? 15.0 : 13.0;

      final Widget labelMarker = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Lingkaran Ikon ──
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: isSelected ? markerColor : markerColor.withAlpha(210),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withAlpha(220),
                width: isSelected ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withAlpha(isSelected ? 130 : 70),
                  blurRadius: isSelected ? 10 : 5,
                  spreadRadius: isSelected ? 2 : 0,
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(isSelected ? 50 : 28),
                  blurRadius: isSelected ? 6 : 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              isActive ? Icons.volcano_rounded : Icons.landscape_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),

          // ── Label Nama ──
          Container(
            constraints: const BoxConstraints(maxWidth: 68),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? markerColor
                  : Colors.white.withAlpha(238),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withAlpha(80)
                    : markerColor.withAlpha(60),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              shortName,
              style: AppFonts.plusJakartaSans(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : markerColor,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

      if (isSelected) {
        return labelMarker
            .animate()
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.0, 1.0),
              duration: 260.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: 180.ms);
      }
      return labelMarker;
    }
  }



  // ───────────────────────────────────────────────────────
  // TAP HANDLER
  // ───────────────────────────────────────────────────────

  /// Handle tap pada volcano — semua gunung bisa diklik
  void _onVolcanoTap(VolcanoModel volcano) {
    final isMonitored = _monitoredVolcanoes.contains(volcano.id);

    // Toggle selection
    setState(() {
      _selectedVolcano = _selectedVolcano?.id == volcano.id ? null : volcano;
    });

    if (_selectedVolcano != null) {
      // Pindah kamera ke gunung yang dipilih
      _mapController.move(LatLng(volcano.latitude, volcano.longitude), 12.0);

      // Tampilkan dialog sesuai tipe gunung
      if (isMonitored) {
        _showPrimaryVolcanoDetail(volcano);
      } else {
        _showSecondaryVolcanoDetail(volcano);
      }
    }
  }

  // ───────────────────────────────────────────────────────
  // DIALOG: GUNUNG UTAMA (DIPANTAU SIGUMI)
  // ───────────────────────────────────────────────────────

  /// Tampilkan detail lengkap gunung yang dipantau Sigumi
  void _showPrimaryVolcanoDetail(VolcanoModel volcano) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      barrierDismissible: true,
      builder: (dialogContext) {
        final statusColor = _getStatusColor(volcano.statusLevel);

        return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: dialogContext.bgSurface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: dialogContext.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                volcano.name,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: dialogContext.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                volcano.statusLabel,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Badge "Dipantau Sigumi"
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: dialogContext.accentPrimary.withAlpha(15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: dialogContext.accentPrimary.withAlpha(55),
                                    width: dialogContext.borderWidth,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 12,
                                      color: dialogContext.accentPrimary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Dipantau Sigumi',
                                      style: AppFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: dialogContext.accentPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        GestureDetector(
                          onTap: () => Navigator.pop(dialogContext),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dialogContext.bgSecondary,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: dialogContext.textTertiary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Info Cards (Ketinggian & Koordinat) ──
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            dialogContext,
                            icon: Icons.height_rounded,
                            label: 'Ketinggian',
                            value: '${volcano.elevation.toInt()} m',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            dialogContext,
                            icon: Icons.location_on_rounded,
                            label: 'Koordinat',
                            value:
                                '${volcano.latitude.toStringAsFixed(2)}°, '
                                '${volcano.longitude.toStringAsFixed(2)}°',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Action Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VisualMerapiScreen(
                                volcano: volcano,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: dialogContext.bgPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.visibility_rounded, size: 16),
                        label: Text(
                          'Lihat Detail Lengkap',
                          style: AppFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 250.ms)
            .scale(
              begin: const Offset(0.88, 0.88),
              end: const Offset(1.0, 1.0),
              duration: 280.ms,
              curve: Curves.easeOutCubic,
            );
      },
    ).then((_) {
      // Clear selection saat dialog ditutup
      if (mounted) setState(() => _selectedVolcano = null);
    });
  }

  // ───────────────────────────────────────────────────────
  // DIALOG: GUNUNG NON-UTAMA (BELUM DIPANTAU)
  // ───────────────────────────────────────────────────────

  /// Tampilkan info ringkas gunung yang belum dipantau Sigumi
  void _showSecondaryVolcanoDetail(VolcanoModel volcano) {
    final statusColor = _getStatusColor(volcano.statusLevel);

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 80,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: dialogContext.bgSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: dialogContext.cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header dengan background status color ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(14),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: statusColor.withAlpha(35),
                            width: dialogContext.borderWidth,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar ikon gunung
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withAlpha(120),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              volcano.statusLevel >= 2
                                  ? Icons.volcano_rounded
                                  : Icons.landscape_rounded,
                              color: dialogContext.bgPrimary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Nama & provinsi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  volcano.name,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: dialogContext.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (volcano.province.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.place_rounded,
                                        size: 11,
                                        color: dialogContext.textTertiary,
                                      ),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          volcano.province,
                                          style: AppFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: dialogContext.textTertiary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Close button
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dialogContext.bgSecondary,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: dialogContext.textTertiary,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        children: [
                          // Info cards — ketinggian & status level
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  dialogContext,
                                  icon: Icons.height_rounded,
                                  label: 'Ketinggian',
                                  value: '${volcano.elevation.toInt()} m dpl',
                                  color: Colors.blue.shade400,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatusCard(dialogContext, volcano, statusColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Notice: belum dipantau Sigumi
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: dialogContext.warningColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dialogContext.warningColor.withAlpha(50),
                                width: dialogContext.borderWidth,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 15,
                                    color: dialogContext.warningColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Gunung ini belum masuk dalam pemantauan aktif Sigumi.',
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: dialogContext.warningColor,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 220.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              duration: 280.ms,
              curve: Curves.easeOutCubic,
            );
      },
    ).then((_) {
      // Clear selection saat dialog ditutup
      if (mounted) setState(() => _selectedVolcano = null);
    });
  }

  // ───────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ───────────────────────────────────────────────────────

  /// Card status untuk popup secondary volcano
  Widget _buildStatusCard(BuildContext ctx, VolcanoModel volcano, Color statusColor) {
    // Ambil label pendek: "Normal", "Waspada", "Siaga", "Awas"
    final shortLabel =
        volcano.statusLabel.contains('•')
            ? volcano.statusLabel.split('•').last.trim()
            : volcano.statusLabel;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withAlpha(55), 
          width: ctx.borderWidth
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radio_button_checked_rounded,
                size: 15,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Status',
                style: AppFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ctx.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            shortLabel,
            style: AppFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build info card kecil dua kolom
  Widget _buildInfoCard(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(50), 
          width: ctx.borderWidth
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ctx.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ctx.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Get status color berdasarkan level
  Color _getStatusColor(int statusLevel) {
    switch (statusLevel) {
      case 1:
        return SigumiTheme.statusNormal;
      case 2:
        return SigumiTheme.statusWaspada;
      case 3:
        return SigumiTheme.statusSiaga;
      case 4:
        return SigumiTheme.statusAwas;
      default:
        return Colors.grey;
    }
  }

  // ───────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<VolcanoProvider, LocationService>(
      builder: (context, provider, locationService, _) {
        final distance = locationService.distanceFromVolcano;
        final zoneLevel = locationService.zoneLevel;
        final zoneLabel = locationService.zoneLabel;

        final userPos = LatLng(
          locationService.userLat,
          locationService.userLng,
        );

        final volcanoPos = LatLng(
          provider.volcano.latitude,
          provider.volcano.longitude,
        );

        return Scaffold(
          backgroundColor: context.bgPrimary,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // ── Layer 1: Fullscreen Map ──
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: volcanoPos,
                  initialZoom: 10.5,
                  minZoom: 8,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sigumi.app',
                    maxZoom: 19,
                    tileProvider: CancellableNetworkTileProvider(),
                  ),

                  // ── Risk Radius Circles ──
                  Builder(
                    builder: (context) {
                      final volcanoLevel = provider.volcano.statusLevel;
                      final isHighAlert = volcanoLevel >= 3;

                      if (isHighAlert) {
                        return CircleLayer(
                          circles: [
                            CircleMarker(
                              point: volcanoPos,
                              radius: _kmToMeter(20),
                              useRadiusInMeter: true,
                              color: SigumiTheme.statusNormal.withAlpha(20),
                              borderColor:
                                  SigumiTheme.statusNormal.withAlpha(70),
                              borderStrokeWidth: 1.5,
                            ),
                            CircleMarker(
                              point: volcanoPos,
                              radius: _kmToMeter(15),
                              useRadiusInMeter: true,
                              color: SigumiTheme.statusWaspada.withAlpha(30),
                              borderColor:
                                  SigumiTheme.statusWaspada.withAlpha(90),
                              borderStrokeWidth: 2,
                            ),
                            CircleMarker(
                              point: volcanoPos,
                              radius: _kmToMeter(10),
                              useRadiusInMeter: true,
                              color: SigumiTheme.statusSiaga.withAlpha(35),
                              borderColor:
                                  SigumiTheme.statusSiaga.withAlpha(110),
                              borderStrokeWidth: 2,
                            ),
                            CircleMarker(
                              point: volcanoPos,
                              radius: _kmToMeter(5),
                              useRadiusInMeter: true,
                              color: SigumiTheme.statusAwas.withAlpha(50),
                              borderColor:
                                  SigumiTheme.statusAwas.withAlpha(140),
                              borderStrokeWidth: 2.5,
                            ),
                          ],
                        ).animate().fadeIn(duration: 800.ms);
                      } else {
                        return CircleLayer(
                          circles: [
                            CircleMarker(
                              point: volcanoPos,
                              radius: _kmToMeter(20),
                              useRadiusInMeter: true,
                              color: Colors.grey.withAlpha(12),
                              borderColor: Colors.grey.withAlpha(45),
                              borderStrokeWidth: 1,
                            ),
                          ],
                        ).animate().fadeIn(duration: 800.ms);
                      }
                    },
                  ),

                  // ── Map Markers ──
                  MarkerLayer(
                    markers: [
                      // Semua volcano markers (primary + secondary, semua bisa diklik)
                      ..._buildVolcanoMarkers(),

                      // User Marker — posisi dari GPS real-time
                      Marker(
                        point: userPos,
                        width: 48,
                        height: 48,
                        child: _buildUserMarker(locationService),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Layer 2: Blur Top Bar ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BlurTopBar(
                  title: 'Peta Risiko',
                  isMapFocused: _isMapFocused,
                  onToggleFocus: () {
                    setState(() {
                      _isMapFocused = !_isMapFocused;
                    });
                  },
                ),
              ).animate().fadeIn(),

              // ── GPS Status Badge ──
              if (locationService.gpsStatus != GpsStatus.active &&
                  locationService.gpsStatus != GpsStatus.unknown)
                Positioned(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                  left: 16,
                  child: _buildGpsBadge(locationService),
                ),

              // ── UI Controls Overlay ──
              IgnorePointer(
                ignoring: _isMapFocused,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isMapFocused ? 0.0 : 1.0,
                  child: Stack(
                    children: [
                      // Floating Map Controls (kanan)
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            16,
                        right: 16,
                        child: MapControls(
                          onLocateMerapi:
                              () => _mapController.move(volcanoPos, 11),
                          onLocateUser: () => _recenterToUser(locationService),
                        ),
                      ).animate().fadeIn().slideX(begin: 0.2),

                      // Floating Posko & Faskes Button (kiri)
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            16 +
                            (locationService.gpsStatus != GpsStatus.active &&
                                    locationService.gpsStatus !=
                                        GpsStatus.unknown
                                ? 44
                                : 0),
                        left: 16,
                        child: ShadcnMapButton(
                          icon: Icons.health_and_safety_rounded,
                          tooltip: 'Posko & Faskes',
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.postDisaster,
                              ),
                        ),
                      ).animate().fadeIn().slideX(begin: -0.2),

                      // Primary Info Card (status & jarak)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: MediaQuery.of(context).size.height * 0.18 + 16,
                        child: Hero(
                          tag: 'primary_info_card',
                          child: PrimaryInfoCard(
                            distance: distance,
                            zoneLevel: zoneLevel,
                          ),
                        ),
                      ),

                      // Draggable Bottom Sheet
                      RiskBottomSheet(distance: distance, zoneLabel: zoneLabel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────
  // USER MARKER & GPS BADGE
  // ───────────────────────────────────────────────────────

  /// User marker — biru untuk real GPS, abu-abu untuk simulasi
  Widget _buildUserMarker(LocationService locationService) {
    final isRealGps = locationService.isUsingRealGps;
    final isActive = locationService.gpsStatus == GpsStatus.active;
    final color = isRealGps ? const Color(0xFF2563EB) : Colors.grey.shade500;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring — hanya saat GPS aktif & tracking
        if (isActive)
          Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(30),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.2, 1.2),
                duration: 2000.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(begin: 0.6, duration: 2000.ms),

        // Marker utama
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isRealGps ? Icons.my_location : Icons.location_searching,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }

  /// Badge GPS kecil — hanya tampil saat ada masalah GPS
  Widget _buildGpsBadge(LocationService locationService) {
    final status = locationService.gpsStatus;

    IconData icon;
    Color bgColor;
    Color iconColor;
    String label;
    bool showRetry = false;

    switch (status) {
      case GpsStatus.unstable:
        icon = Icons.gps_not_fixed_rounded;
        bgColor = context.warningColor.withAlpha(25);
        iconColor = context.warningColor;
        label = 'GPS Tidak Stabil';
        break;
      case GpsStatus.error:
        icon = Icons.gps_off_rounded;
        bgColor = context.errorColor.withAlpha(25);
        iconColor = context.errorColor;
        label = 'GPS Error';
        showRetry = true;
        break;
      case GpsStatus.disabled:
        icon = Icons.location_disabled_rounded;
        bgColor = context.bgSecondary;
        iconColor = context.textTertiary;
        label = 'GPS Nonaktif';
        break;
      case GpsStatus.denied:
        icon = Icons.block_rounded;
        bgColor = context.errorColor.withAlpha(25);
        iconColor = context.errorColor;
        label = 'Izin Ditolak';
        showRetry = true;
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap:
          showRetry
              ? () {
                locationService.retryTracking();
                _hasShownInitialError = false;
              }
              : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: iconColor.withAlpha(40),
            width: context.borderWidth,
          ),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locationService.isRetrying) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(iconColor),
                ),
              ),
            ] else ...[
              Icon(icon, size: 14, color: iconColor),
            ],
            const SizedBox(width: 6),
            Text(
              locationService.isRetrying ? 'Mencoba...' : label,
              style: AppFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
            if (showRetry && !locationService.isRetrying) ...[
              const SizedBox(width: 4),
              Icon(Icons.refresh_rounded, size: 12, color: iconColor),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }
}
