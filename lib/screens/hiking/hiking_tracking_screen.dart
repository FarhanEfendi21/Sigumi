import 'dart:async';
import 'dart:math' as math;
import '../../services/localization_service.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../config/theme_extensions.dart';
import '../../models/hiking_trail.dart';
import '../../providers/volcano_provider.dart';
import '../../services/hiking_tracking_service.dart';
import '../../services/hiking_trail_repository.dart';
import '../../services/location_service.dart';
import '../../widgets/hiking_map_markers.dart';
import '../../widgets/hiking_point_detail_sheet.dart';
import '../../widgets/hiking_weather_card.dart';
import '../../widgets/hiking_sos_panel.dart';

class HikingTrackingScreen extends StatelessWidget {
  const HikingTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HikingTrackingDispatcher();
  }
}

/// Dispatcher: cek auth dan apakah GPS berada di area pendakian yang didukung.
class _HikingTrackingDispatcher extends StatelessWidget {
  const _HikingTrackingDispatcher();

  @override
  Widget build(BuildContext context) {
    final volcanoProvider = context.watch<VolcanoProvider>();
    final tracking = context.watch<HikingTrackingService>();

    // Jangan ganti subtree halaman ketika sesi lama masih dipulihkan dari disk.
    // Status sesi yang belum siap sebelumnya sempat menampilkan gate lokasi lalu
    // menggantinya dengan peta di tengah animasi pembukaan route.
    return FutureBuilder<void>(
      future: tracking.ensureRestored(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: context.bgPrimary,
            body: Center(
              child: CircularProgressIndicator(color: context.successColor),
            ),
          );
        }

        final location = tracking.locationService;

        // ── Gate 1: Belum login ──
        if (volcanoProvider.isGuest) {
          return const _HikingLoginGate();
        }

        return ListenableBuilder(
          listenable: location,
          builder: (context, _) {
            // Sesi aktif/terjeda harus bisa dibuka kembali dari riwayat sesi
            // tersimpan, walaupun GPS sedang belum mendapat fix baru.
            final profileRegion =
                volcanoProvider.selectedRegion.trim().toLowerCase();
            final profileAllowsAgung =
                profileRegion == 'bali' &&
                location.isWithinHikingRegion('bali');
            final profileAllowsRinjani =
                profileRegion == 'lombok' &&
                location.isWithinHikingRegion('lombok');
            final activeSessionCanOpen =
                (tracking.isActive || tracking.hasHistory) &&
                const {'bali', 'lombok'}.contains(tracking.trackingRegion);
            if (!profileAllowsAgung &&
                !profileAllowsRinjani &&
                !activeSessionCanOpen) {
              return _HikingUnavailableView(
                currentRegion: volcanoProvider.selectedRegion,
                locationService: location,
              );
            }

            return const _HikingTrackingView();
          },
        );
      },
    );
  }
}

/// Painter siluet gunung minimalis
class _MountainSilhouettePainter extends CustomPainter {
  final Color peakColor;
  final Color fogColor;

  const _MountainSilhouettePainter({
    required this.peakColor,
    required this.fogColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gunung belakang (lebih rendah, pudar)
    final bgPaint =
        Paint()
          ..shader = ui.Gradient.linear(Offset(w / 2, 0), Offset(w / 2, h), [
            peakColor.withAlpha(60),
            peakColor.withAlpha(30),
          ]);

    final bgPath =
        ui.Path()
          ..moveTo(0, h)
          ..lineTo(w * 0.12, h * 0.55)
          ..lineTo(w * 0.30, h * 0.72)
          ..lineTo(w * 0.50, h * 0.28)
          ..lineTo(w * 0.68, h * 0.60)
          ..lineTo(w * 0.88, h * 0.42)
          ..lineTo(w, h * 0.58)
          ..lineTo(w, h)
          ..close();
    canvas.drawPath(bgPath, bgPaint);

    // Gunung utama (depan, lebih gelap)
    final fgPaint =
        Paint()
          ..shader = ui.Gradient.linear(Offset(w / 2, 0), Offset(w / 2, h), [
            peakColor.withAlpha(160),
            peakColor.withAlpha(220),
          ]);

    final fgPath =
        ui.Path()
          ..moveTo(0, h)
          ..lineTo(w * 0.05, h * 0.75)
          ..lineTo(w * 0.22, h * 0.88)
          ..lineTo(w * 0.40, h * 0.48)
          ..lineTo(w * 0.52, h * 0.12) // puncak utama
          ..lineTo(w * 0.64, h * 0.44)
          ..lineTo(w * 0.78, h * 0.82)
          ..lineTo(w * 0.92, h * 0.65)
          ..lineTo(w, h * 0.78)
          ..lineTo(w, h)
          ..close();
    canvas.drawPath(fgPath, fgPaint);

    // Kabut bawah
    final fogPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(w / 2, h * 0.6),
            Offset(w / 2, h),
            [fogColor.withAlpha(0), fogColor.withAlpha(200)],
          );

    canvas.drawRect(Rect.fromLTWH(0, h * 0.6, w, h * 0.4), fogPaint);
  }

  @override
  bool shouldRepaint(_MountainSilhouettePainter old) =>
      old.peakColor != peakColor || old.fogColor != fogColor;
}

/// Tampilan saat wilayah profil dan posisi GPS belum cocok dengan jalur dukungan.
/// Tidak ada tombol redirect wilayah — user cukup diberi informasi & tombol refresh GPS.
class _HikingUnavailableView extends StatefulWidget {
  final String currentRegion;
  final LocationService locationService;

  const _HikingUnavailableView({
    required this.currentRegion,
    required this.locationService,
  });

  @override
  State<_HikingUnavailableView> createState() => _HikingUnavailableViewState();
}

class _HikingUnavailableViewState extends State<_HikingUnavailableView> {
  bool _isRefreshing = false;

  Future<void> _refreshGps(BuildContext context) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await widget.locationService.retryTracking();
      if (!context.mounted) return;
      final loc = widget.locationService;
      final hasFix = loc.hasFreshRealPosition;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasFix
                ? context.trText(
                  'Lokasi GPS diperbarui (${loc.userLat.toStringAsFixed(4)}, ${loc.userLng.toStringAsFixed(4)})',
                )
                : context.trText(
                  'Masih mencari sinyal GPS. Pastikan lokasi perangkat aktif.',
                ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgTop = context.bgPrimary;
    final bgBottom = context.bgSecondary;
    final peakColor =
        context.isHighContrast
            ? context.accentSecondary
            : const Color(0xFFE2E8F0);
    final accentColor = context.successColor;
    final textDark = context.textPrimary;
    final textMuted = context.textSecondary;
    final currentRegion = widget.currentRegion;
    final isBusy = _isRefreshing || widget.locationService.isRetrying;

    return Scaffold(
      backgroundColor: bgTop,
      body: Stack(
        children: [
          // Clean gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    context.isHighContrast
                        ? [bgTop, bgTop, bgBottom]
                        : [bgTop, const Color(0xFFF8FAFC), bgBottom],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // Siluet gunung halus di bagian bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.38,
            child: CustomPaint(
              painter: _MountainSilhouettePainter(
                peakColor: peakColor,
                fogColor: bgBottom,
              ),
            ),
          ),

          // Konten utama
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App bar minimal
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textDark, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          context.trText('Tracking Pendakian'),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.trText('Refresh Sinyal GPS'),
                        onPressed: isBusy ? null : () => _refreshGps(context),
                        icon:
                            isBusy
                                ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accentColor,
                                  ),
                                )
                                : Icon(
                                  Icons.refresh_rounded,
                                  color: textDark,
                                  size: 22,
                                ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Ikon
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color:
                          context.isHighContrast
                              ? context.bgSurface
                              : const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.borderColor,
                        width: context.borderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_searching_rounded,
                      color: accentColor,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Label wilayah saat ini
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: bgTop,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.borderColor,
                        width: context.borderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      currentRegion.toUpperCase(),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: textMuted,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Heading
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    context.trText('Anda Tidak Berada di\nWilayah Pendakian'),
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Keterangan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    context.trText(
                      currentRegion.trim().toLowerCase() == 'bali'
                          ? 'Profil Bali hanya dapat tracking saat GPS terdeteksi di area pendakian Gunung Agung.'
                          : currentRegion.trim().toLowerCase() == 'lombok'
                          ? 'Profil Lombok hanya dapat tracking saat GPS terdeteksi di area pendakian Gunung Rinjani.'
                          : 'Tracking tersedia jika wilayah profil Bali atau Lombok sesuai dengan lokasi GPS pendakian.',
                    ),
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 13.5,
                      height: 1.55,
                      color: textMuted,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Tombol Refresh Sinyal GPS
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : () => _refreshGps(context),
                    icon:
                        isBusy
                            ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    context.isHighContrast
                                        ? context.bgPrimary
                                        : Colors.white,
                              ),
                            )
                            : const Icon(Icons.my_location_rounded, size: 19),
                    label: Text(
                      context.trText(
                        isBusy ? 'Mencari Sinyal GPS...' : 'Refresh Sinyal GPS',
                      ),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            context.isHighContrast
                                ? context.bgPrimary
                                : Colors.white,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor:
                          context.isHighContrast
                              ? context.bgPrimary
                              : Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      elevation: 2,
                      shadowColor: accentColor.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                // Tombol kembali saja — tanpa redirect wilayah
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(
                        color: context.borderColor,
                        width: context.borderWidth,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.trText('Kembali'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
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

/// Gate login — ditampilkan saat pengguna belum masuk akun.
class _HikingLoginGate extends StatelessWidget {
  const _HikingLoginGate();

  @override
  Widget build(BuildContext context) {
    final bgTop = context.bgPrimary;
    final bgBottom = context.bgSecondary;
    final peakColor =
        context.isHighContrast
            ? context.accentSecondary
            : const Color(0xFFE2E8F0);
    final accentColor = context.accentPrimary;
    final textDark = context.textPrimary;
    final textMuted = context.textSecondary;

    return Scaffold(
      backgroundColor: bgTop,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    context.isHighContrast
                        ? [bgTop, bgTop, bgBottom]
                        : [bgTop, const Color(0xFFF8FAFC), bgBottom],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.38,
            child: CustomPaint(
              painter: _MountainSilhouettePainter(
                peakColor: peakColor,
                fogColor: bgBottom,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textDark, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        context.trText('Tracking Pendakian'),
                        style: AppFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Ikon kunci
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color:
                          context.isHighContrast
                              ? context.bgSurface
                              : const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.borderColor,
                        width: context.borderWidth,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(20),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: accentColor,
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    context.trText('Masuk untuk Mulai\nTracking Pendakian'),
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    context.trText(
                      'Fitur tracking pendakian memerlukan akun\nuntuk menyimpan dan memantau jalur Anda.',
                    ),
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 13.5,
                      height: 1.55,
                      color: textMuted,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: FilledButton(
                    onPressed:
                        () => Navigator.pushNamed(context, AppRoutes.login),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor:
                          context.isHighContrast
                              ? context.bgPrimary
                              : Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      elevation: 2,
                      shadowColor: accentColor.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      context.trText('Masuk Akun'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            context.isHighContrast
                                ? context.bgPrimary
                                : Colors.white,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(
                        color: context.borderColor,
                        width: context.borderWidth,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.trText('Kembali'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
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

/// Tampilan tracking aktif untuk Gunung Rinjani dan Gunung Agung.
class _HikingTrackingView extends StatefulWidget {
  const _HikingTrackingView();

  @override
  State<_HikingTrackingView> createState() => _HikingTrackingViewState();
}

class _HikingTrackingViewState extends State<_HikingTrackingView> {
  final MapController _mapController = MapController();
  final GlobalKey<HikingWeatherCardState> _weatherCardKey =
      GlobalKey<HikingWeatherCardState>();
  bool _isMapReady = false;
  bool _isMapExpanded = false;
  LatLng? _lastFollowedPoint;
  bool _isRefreshingPage = false;
  final Map<String, HikingTrailDataset> _trailDatasets = {};
  final Map<String, String> _selectedRouteIds = {};
  final Set<String> _loadingTrailRegions = {};

  // Titik tengah default jalur pendakian sebelum aset dimuat
  static const LatLng _rinjaniCenter = LatLng(-8.3785, 116.4650);
  static const LatLng _agungCenter = LatLng(-8.3550, 115.5032);

  void _ensureTrailLoaded(String region) {
    final key = HikingTrailRepository.normalizeRegion(region);
    if (_trailDatasets.containsKey(key) || _loadingTrailRegions.contains(key)) {
      return;
    }
    final cached = HikingTrailRepository.instance.cachedForRegion(key);
    if (cached != null) {
      _trailDatasets[key] = cached;
      return;
    }
    _loadingTrailRegions.add(key);
    unawaited(
      HikingTrailRepository.instance.loadForRegion(key).then((dataset) {
        _loadingTrailRegions.remove(key);
        if (!mounted) return;
        setState(() {
          _trailDatasets[key] = dataset;
        });
      }),
    );
  }

  Future<void> _pickTrailRoute(
    HikingTrailDataset dataset,
    String regionKey,
    String currentRouteId,
  ) async {
    final picked = await showHikingTrailRoutePicker(
      context,
      dataset: dataset,
      selectedRouteId: currentRouteId,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedRouteIds[regionKey] = picked.id;
    });
    if (_isMapReady) {
      try {
        _mapController.move(picked.center, picked.defaultZoom);
      } catch (_) {}
    }
  }

  Widget _buildMapOverlayPill({
    Key? tapKey,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required String label,
    bool showChevron = false,
    bool flexibleLabel = false,
    VoidCallback? onTap,
  }) {
    final textWidget = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: _textDark,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow:
            context.isHighContrast
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: tapKey,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 13),
                const SizedBox(width: 5),
                if (flexibleLabel) Flexible(child: textWidget) else textWidget,
                if (showChevron) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _textMuted,
                    size: 15,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _bg => context.bgPrimary;
  Color get _cardBg => context.bgSurface;
  Color get _cardBorder => context.borderColor;
  Color get _accentColor => context.successColor;
  Color get _textDark => context.textPrimary;
  Color get _textMuted => context.textSecondary;

  /// Menghasilkan titik-titik garis batas lingkaran geofence menggunakan
  /// formula Haversine bola bumi (R = 6371 km) yang identik dengan
  /// perhitungan radius 15 km di LocationService & HikingTrackingService.
  List<LatLng> _buildGeofenceBoundaryPoints(
    LatLng center,
    double radiusKm, {
    int segments = 180,
  }) {
    const earthRadiusKm = 6371.0;
    final angularDistance = radiusKm / earthRadiusKm;
    final lat1 = center.latitudeInRad;
    final lng1 = center.longitudeInRad;
    final sinLat1 = math.sin(lat1);
    final cosLat1 = math.cos(lat1);
    final sinAngular = math.sin(angularDistance);
    final cosAngular = math.cos(angularDistance);

    final points = <LatLng>[];
    for (var i = 0; i <= segments; i++) {
      final bearing = (2 * math.pi * i) / segments;
      final sinLat2 =
          sinLat1 * cosAngular + cosLat1 * sinAngular * math.cos(bearing);
      final lat2 = math.asin(sinLat2.clamp(-1.0, 1.0));
      final y = math.sin(bearing) * sinAngular * cosLat1;
      final x = cosAngular - sinLat1 * math.sin(lat2);
      final lng2 = lng1 + math.atan2(y, x);
      points.add(LatLng(lat2 * 180 / math.pi, lng2 * 180 / math.pi));
    }
    return points;
  }

  void _syncMapFollow({
    required HikingTrackingService tracking,
    required LocationService location,
    required LatLng userPoint,
  }) {
    if (!tracking.isActive ||
        tracking.isPaused ||
        !location.hasFreshRealPosition) {
      return;
    }
    if (!_isMapReady) return;
    final previous = _lastFollowedPoint;
    if (previous != null &&
        const Distance().as(LengthUnit.Meter, previous, userPoint) < 1.0) {
      return;
    }
    _lastFollowedPoint = userPoint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isMapReady) return;
      try {
        _mapController.move(userPoint, _mapController.camera.zoom);
      } catch (_) {}
    });
  }

  Future<void> _refreshTrackingPage(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    if (_isRefreshingPage) return;
    final location = tracking.locationService;
    setState(() {
      _isRefreshingPage = true;
    });

    try {
      await location.retryTracking();
      if (mounted) {
        // Tunggu frame agar kartu menerima koordinat GPS terbaru, lalu muat
        // ulang sekali. Pemicu bersamaan (mis. canFetch false→true) digabung
        // oleh kartu menjadi satu request.
        await WidgetsBinding.instance.endOfFrame;
        await _weatherCardKey.currentState?.refresh();
      }
      if (tracking.hasActiveSos) {
        unawaited(tracking.refreshSosStatus());
      }
      if (!context.mounted) return;
      final refreshedPoint = LatLng(location.userLat, location.userLng);
      if (_isMapReady) {
        try {
          _mapController.move(refreshedPoint, _mapController.camera.zoom);
        } catch (_) {}
      }
      final hasFix = location.hasFreshRealPosition;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasFix
                ? context.trText(
                  'Sinyal GPS & cuaca diperbarui (${location.userLat.toStringAsFixed(5)}, ${location.userLng.toStringAsFixed(5)})',
                )
                : context.trText(
                  'Masih mencari sinyal GPS. Pastikan lokasi perangkat aktif.',
                ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshingPage = false);
      }
    }
  }

  void _openPointDetailSheet({
    HikingWaypoint? waypoint,
    required List<HikingWaypoint> waypoints,
    required LatLng userPoint,
    required LocationService location,
    required HikingTrackingService tracking,
    required bool isOutsideWarning,
    HikingTrailSourceMetadata? sourceMetadata,
  }) {
    unawaited(
      showHikingPointDetailSheet(
        context,
        initialWaypoint: waypoint,
        waypoints: waypoints,
        userPoint: userPoint,
        hasRealGps: location.hasFreshRealPosition,
        isTrackingActive: tracking.isActive && !tracking.isPaused,
        isTrackingPaused: tracking.isActive && tracking.isPaused,
        isOutsideWarning: isOutsideWarning,
        gpsAccuracyMeters: location.accuracyMeters,
        recordedDistanceKm: tracking.distanceKm,
        sourceMetadata: sourceMetadata,
        onFocusPoint: (point) {
          if (!_isMapReady) return;
          try {
            _mapController.move(
              point,
              math.max(_mapController.camera.zoom, 14.0),
            );
          } catch (_) {}
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HikingTrackingService>(
      builder: (context, tracking, _) {
        final location = tracking.locationService;
        return ListenableBuilder(
          listenable: location,
          builder: (context, _) {
            final userPoint = LatLng(location.userLat, location.userLng);
            final liveMovementLine = tracking.liveMovementSegment;
            _syncMapFollow(
              tracking: tracking,
              location: location,
              userPoint: userPoint,
            );

        final isUserInAgung =
            location.userLat >= -8.55 &&
            location.userLat <= -8.15 &&
            location.userLng >= 115.30 &&
            location.userLng <= 115.72;
        final isUserInLombok =
            location.userLat <= -8.1 &&
            location.userLat >= -8.9 &&
            location.userLng >= 115.9 &&
            location.userLng <= 116.9;
        final weatherRegion =
            tracking.trackingRegion ??
            (location.isCoordinateWithinHikingRegion(
                  'bali',
                  location.userLat,
                  location.userLng,
                )
                ? 'bali'
                : location.isCoordinateWithinHikingRegion(
                  'lombok',
                  location.userLat,
                  location.userLng,
                )
                ? 'lombok'
                : null);

        final activeGeofenceRegion =
            tracking.trackingRegion ??
            weatherRegion ??
            (isUserInAgung ? 'bali' : 'lombok');
        final trailRegionKey =
            activeGeofenceRegion == 'bali' ? 'bali' : 'lombok';
        _ensureTrailLoaded(trailRegionKey);
        final trailDataset =
            _trailDatasets[trailRegionKey] ??
            HikingTrailRepository.instance.cachedForRegion(trailRegionKey) ??
            HikingTrailRepository.instance.fallbackForRegion(trailRegionKey);
        final activeRoute = trailDataset.routeById(
          _selectedRouteIds[trailRegionKey],
        );
        final waypoints = activeRoute?.waypoints ?? const <HikingWaypoint>[];
        final trailPolyline = activeRoute?.polyline ?? const <LatLng>[];
        final mountainCenter =
            activeRoute?.center ??
            (isUserInAgung ? _agungCenter : _rinjaniCenter);
        final mountainZoom = activeRoute?.defaultZoom ?? 12.5;
        final defaultCenter =
            (isUserInAgung || isUserInLombok) ? userPoint : mountainCenter;
        final geofenceCenterCoords =
            LocationService.regionCenters[activeGeofenceRegion == 'bali'
                ? 'Bali'
                : 'Lombok']!;
        final geofenceCenter = LatLng(
          geofenceCenterCoords['lat']!,
          geofenceCenterCoords['lng']!,
        );
        const geofenceRadiusKm = LocationService.hikingTrackingRadiusKm;
        final geofenceBoundaryPoints = _buildGeofenceBoundaryPoints(
          geofenceCenter,
          geofenceRadiusKm,
        );
        final isInsideGeofence = location.isCoordinateWithinHikingRegion(
          activeGeofenceRegion,
          location.userLat,
          location.userLng,
        );
        final isOutsideWarning =
            (tracking.isActive &&
                tracking.trackingStatus == HikingTrackingStatus.outsideGrace) ||
            (location.hasFreshRealPosition && !isInsideGeofence);
        final boundaryLineColor =
            context.isHighContrast
                ? context.accentSecondary
                : isOutsideWarning
                ? context.errorColor
                : const Color(0xFFD97706);

        return Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              // Siluet gunung halus di header atas
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 180,
                child: CustomPaint(
                  painter: _MountainSilhouettePainter(
                    peakColor:
                        context.isHighContrast
                            ? context.accentSecondary.withAlpha(80)
                            : const Color(0xFFDCFCE7).withAlpha(140),
                    fogColor: _bg,
                  ),
                ),
              ),

              // Konten utama
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App bar minimal
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: _textDark,
                              size: 24,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.trText('Tracking Pendakian'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: _textDark,
                                    height: 1.15,
                                  ),
                                ),
                                Text(
                                  context.trText(
                                    isUserInAgung
                                        ? 'GUNUNG AGUNG · 3.142 MDPL'
                                        : 'GUNUNG RINJANI · 3.726 MDPL',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.9,
                                    color: context.accentPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: context.trText('Refresh Sinyal GPS'),
                            onPressed:
                                (_isRefreshingPage || location.isRetrying)
                                    ? null
                                    : () => _refreshTrackingPage(
                                      context,
                                      tracking,
                                    ),
                            icon:
                                (_isRefreshingPage || location.isRetrying)
                                    ? SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _accentColor,
                                      ),
                                    )
                                    : Icon(
                                      Icons.refresh_rounded,
                                      color: _textDark,
                                      size: 20,
                                    ),
                          ),
                          IconButton(
                            tooltip: context.trText(
                              isUserInAgung
                                  ? 'Pusatkan ke Agung'
                                  : 'Pusatkan ke Rinjani',
                            ),
                            onPressed:
                                () => _mapController.move(
                                  mountainCenter,
                                  mountainZoom,
                                ),
                            icon: Icon(
                              Icons.terrain_rounded,
                              color: _textDark,
                              size: 20,
                            ),
                          ),
                          IconButton(
                            tooltip: context.trText('Lokasi saya'),
                            onPressed: () => _mapController.move(userPoint, 15),
                            icon: Icon(
                              Icons.my_location_rounded,
                              color: _textDark,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Konten scrollable dengan Pull-to-Refresh
                    Expanded(
                      child: RefreshIndicator(
                        color: _accentColor,
                        onRefresh:
                            () => _refreshTrackingPage(context, tracking),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            tracking.isActive ? 108 : 24,
                          ),
                          children: [
                            _HikingStatusBanner(
                              tracking: tracking,
                              onTap:
                                  () => _openPointDetailSheet(
                                    waypoints: waypoints,
                                    userPoint: userPoint,
                                    location: location,
                                    tracking: tracking,
                                    isOutsideWarning: isOutsideWarning,
                                    sourceMetadata: trailDataset.metadata,
                                  ),
                            ),

                            const SizedBox(height: 10),

                            HikingWeatherCard(
                              key: _weatherCardKey,
                              latitude: location.userLat,
                              longitude: location.userLng,
                              cacheRegion: weatherRegion,
                              canFetch: location.hasFreshRealPosition,
                              showRefreshButton: false,
                            ),

                          const SizedBox(height: 12),

                          // Peta dengan dropdown perluasan halus ke bawah
                          Container(
                            decoration: BoxDecoration(
                              color: _cardBg,
                              border: Border.all(
                                color: _cardBorder,
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow:
                                  context.isHighContrast
                                      ? null
                                      : [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(8),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        context.reduceMotion
                                            ? Duration.zero
                                            : const Duration(milliseconds: 360),
                                    curve: Curves.easeOutCubic,
                                    height:
                                        _isMapExpanded
                                            ? (MediaQuery.sizeOf(
                                                      context,
                                                    ).height *
                                                    0.62)
                                                .clamp(400.0, 560.0)
                                            : 260.0,
                                    child: Stack(
                                children: [
                                  FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: defaultCenter,
                                      initialZoom:
                                          (isUserInLombok || isUserInAgung)
                                              ? 13.5
                                              : 12.0,
                                      onMapReady: () {
                                        _isMapReady = true;
                                      },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.sigumi.app',
                                      ),
                                      CircleLayer(
                                        circles: [
                                          CircleMarker(
                                            point: geofenceCenter,
                                            radius: geofenceRadiusKm * 1000,
                                            useRadiusInMeter: true,
                                            color:
                                                context.isHighContrast
                                                    ? Colors.transparent
                                                    : (isOutsideWarning
                                                            ? context.errorColor
                                                            : _accentColor)
                                                        .withAlpha(18),
                                            borderColor: Colors.transparent,
                                            borderStrokeWidth: 0,
                                          ),
                                        ],
                                      ),
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: geofenceBoundaryPoints,
                                            strokeWidth: 2.5,
                                            pattern: StrokePattern.dashed(
                                              segments: const [10, 6],
                                            ),
                                            color: boundaryLineColor,
                                          ),
                                          if (trailPolyline.length >= 2)
                                            Polyline(
                                              points: trailPolyline,
                                              strokeWidth: 4.0,
                                              borderStrokeWidth: 1.8,
                                              borderColor:
                                                  context.isHighContrast
                                                      ? context.bgPrimary
                                                      : Colors.white.withAlpha(
                                                        220,
                                                      ),
                                              color: _accentColor,
                                            ),
                                          if (liveMovementLine.length >= 2)
                                            Polyline(
                                              points: liveMovementLine,
                                              strokeWidth: 5.5,
                                              borderStrokeWidth: 1.5,
                                              borderColor:
                                                  context.isHighContrast
                                                      ? context.bgPrimary
                                                      : Colors.white,
                                              color: context.isHighContrast
                                                  ? context.accentSecondary
                                                  : Colors.redAccent,
                                            ),
                                        ],
                                      ),
                                      MarkerLayer(
                                        rotate: true,
                                        markers: [
                                          ...waypoints.map((w) {
                                            final isSummit =
                                                w.kind ==
                                                HikingWaypointKind.summit;
                                            return Marker(
                                              point: w.point,
                                              width: isSummit ? 114 : 98,
                                              height: isSummit ? 80 : 74,
                                              alignment: Alignment.topCenter,
                                              child: HikingWaypointMarker(
                                                waypoint: w,
                                                onTap:
                                                    () => _openPointDetailSheet(
                                                      waypoint: w,
                                                      waypoints: waypoints,
                                                      userPoint: userPoint,
                                                      location: location,
                                                      tracking: tracking,
                                                      isOutsideWarning:
                                                          isOutsideWarning,
                                                      sourceMetadata:
                                                          trailDataset.metadata,
                                                    ),
                                              ),
                                            );
                                          }),
                                          Marker(
                                            point: userPoint,
                                            width: 66,
                                            height: 66,
                                            alignment: Alignment.center,
                                            child: HikingUserRealtimeMarker(
                                              isActive:
                                                  tracking.isActive &&
                                                  !tracking.isPaused,
                                              isPaused:
                                                  tracking.isActive &&
                                                  tracking.isPaused,
                                              isWarning: isOutsideWarning,
                                              onTap:
                                                  () => _openPointDetailSheet(
                                                    waypoints: waypoints,
                                                    userPoint: userPoint,
                                                    location: location,
                                                    tracking: tracking,
                                                    isOutsideWarning:
                                                        isOutsideWarning,
                                                    sourceMetadata:
                                                        trailDataset.metadata,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Bar badge atas responsif: jalur (kiri) & batas radius (kanan) tanpa tumpang tindih
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    child: Builder(
                                      builder: (context) {
                                        final isCompactWidth =
                                            MediaQuery.sizeOf(context).width <
                                            380;
                                        final canPickRoute =
                                            trailDataset.routes.length > 1 &&
                                            activeRoute != null;
                                        final routeLabel = context.trText(
                                          activeRoute?.name ?? 'Jalur Sembalun',
                                        );
                                        final radiusLabel =
                                            isCompactWidth
                                                ? '${context.trText('Radius')} ${geofenceRadiusKm.toStringAsFixed(0)} km'
                                                : context.trText(
                                                  'Batas Radius ${geofenceRadiusKm.toStringAsFixed(0)} km',
                                                );

                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: AnimatedSize(
                                                duration:
                                                    context.reduceMotion
                                                        ? Duration.zero
                                                        : const Duration(
                                                          milliseconds: 200,
                                                        ),
                                                curve: Curves.easeOutCubic,
                                                alignment: Alignment.centerLeft,
                                                child: _buildMapOverlayPill(
                                                  tapKey: const Key(
                                                    'hiking_trail_route_badge',
                                                  ),
                                                  icon: Icons.route_rounded,
                                                  iconColor: _accentColor,
                                                  borderColor: _cardBorder,
                                                  label: routeLabel,
                                                  showChevron: canPickRoute,
                                                  flexibleLabel: true,
                                                  onTap:
                                                      canPickRoute
                                                          ? () => _pickTrailRoute(
                                                            trailDataset,
                                                            trailRegionKey,
                                                            activeRoute.id,
                                                          )
                                                          : null,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildMapOverlayPill(
                                              icon: Icons.radar_rounded,
                                              iconColor: boundaryLineColor,
                                              borderColor: boundaryLineColor
                                                  .withAlpha(140),
                                              label: radiusLabel,
                                              onTap:
                                                  () => _mapController.move(
                                                    geofenceCenter,
                                                    10.2,
                                                  ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _cardBorder,
                                  ),
                                  Semantics(
                                    button: true,
                                    toggled: _isMapExpanded,
                                    label: context.trText(
                                      _isMapExpanded
                                          ? 'Ringkas peta'
                                          : 'Perluas peta',
                                    ),
                                    child: Material(
                                      color: _cardBg,
                                      child: InkWell(
                                        key: const Key(
                                          'hiking_map_expand_toggle',
                                        ),
                                        onTap:
                                            () => setState(
                                              () =>
                                                  _isMapExpanded =
                                                      !_isMapExpanded,
                                            ),
                                        child: SizedBox(
                                          height: 36,
                                          width: double.infinity,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              AnimatedSwitcher(
                                                duration:
                                                    context.reduceMotion
                                                        ? Duration.zero
                                                        : const Duration(
                                                          milliseconds: 180,
                                                        ),
                                                child: Text(
                                                  context.trText(
                                                    _isMapExpanded
                                                        ? 'Ringkas peta'
                                                        : 'Perluas peta',
                                                  ),
                                                  key: ValueKey(_isMapExpanded),
                                                  style:
                                                      AppFonts.plusJakartaSans(
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: _textMuted,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              AnimatedRotation(
                                                turns:
                                                    _isMapExpanded ? 0.5 : 0.0,
                                                duration:
                                                    context.reduceMotion
                                                        ? Duration.zero
                                                        : const Duration(
                                                          milliseconds: 300,
                                                        ),
                                                curve: Curves.easeOutCubic,
                                                child: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  size: 18,
                                                  color: _textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (trailDataset.metadata.displayLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                                left: 4,
                                right: 4,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: HikingTrailSourceAttribution(
                                  metadata: trailDataset.metadata,
                                ),
                              ),
                            ),

                          const SizedBox(height: 10),

                          _HikingStatsGrid(tracking: tracking),

                          if (tracking.error != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: context.bgSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Text(
                                tracking.error!,
                                style: TextStyle(
                                  color: context.errorColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          if (!tracking.isActive)
                            FilledButton.icon(
                              onPressed:
                                  tracking.isStarting ||
                                          tracking.isStopping ||
                                          tracking.isPausing
                                      ? null
                                      : () => _startTracking(context, tracking),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                tracking.isStarting
                                    ? context.trText('Menyiapkan GPS...')
                                    : context.trText('Mulai Tracking'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      context.isHighContrast
                                          ? context.bgPrimary
                                          : Colors.white,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor:
                                    context.isHighContrast
                                        ? context.bgPrimary
                                        : Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                elevation: 2,
                                shadowColor: _accentColor.withAlpha(80),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            )
                          else ...[
                            FilledButton.icon(
                              onPressed:
                                  tracking.isStarting ||
                                          tracking.isStopping ||
                                          tracking.isPausing
                                      ? null
                                      : () async {
                                        if (tracking.isPaused) {
                                          await tracking.resume();
                                        } else {
                                          await tracking.pause();
                                        }
                                      },
                              icon: Icon(
                                tracking.isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                              ),
                              label: Text(
                                tracking.isPausing
                                    ? context.trText('Menjeda tracking...')
                                    : tracking.isStarting
                                    ? context.trText('Menyiapkan GPS...')
                                    : tracking.isPaused
                                    ? context.trText('Lanjutkan Tracking')
                                    : context.trText('Jeda Tracking'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      context.isHighContrast
                                          ? context.bgPrimary
                                          : Colors.white,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _accentColor,
                                foregroundColor:
                                    context.isHighContrast
                                        ? context.bgPrimary
                                        : Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                elevation: 2,
                                shadowColor: _accentColor.withAlpha(80),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed:
                                  tracking.isStarting ||
                                          tracking.isStopping ||
                                          tracking.isPausing
                                      ? null
                                      : () =>
                                          _finishTracking(context, tracking),
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: Text(
                                tracking.isStopping
                                    ? context.trText('Menyelesaikan...')
                                    : context.trText('Selesaikan Pendakian'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.errorColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.errorColor,
                                minimumSize: const Size.fromHeight(48),
                                side: BorderSide(color: context.errorColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],

                          // Tombol Reset Tracking jika terdapat riwayat tracking
                          if (tracking.hasHistory) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed:
                                  tracking.isStarting ||
                                          tracking.isStopping ||
                                          tracking.isPausing
                                      ? null
                                      : () => _confirmResetTracking(
                                        context,
                                        tracking,
                                      ),
                              icon: Icon(
                                Icons.restart_alt_rounded,
                                size: 18,
                                color: context.errorColor,
                              ),
                              label: Text(
                                context.trText('Reset Riwayat Tracking'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.errorColor,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.errorColor,
                                backgroundColor: context.bgSurface,
                                side: BorderSide(
                                  color: context.borderColor,
                                  width: context.borderWidth,
                                ),
                                minimumSize: const Size.fromHeight(48),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          Text(
                            context.trText(
                              'Lokasi pendakian direkam selama tracking aktif.',
                            ),
                            textAlign: TextAlign.center,
                            style: AppFonts.plusJakartaSans(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
              Positioned(
                right: 16,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
                child: Builder(
                  builder: (context) {
                    final isVisible = tracking.isActive;
                    final isCompact =
                        MediaQuery.sizeOf(context).shortestSide < 360;
                    final buttonSize = isCompact ? 60.0 : 68.0;
                    return IgnorePointer(
                      ignoring: !isVisible,
                      child: ExcludeSemantics(
                        excluding: !isVisible,
                        child: AnimatedOpacity(
                          opacity: isVisible ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: AnimatedScale(
                            scale: isVisible ? 1 : 0.72,
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutBack,
                            child: _buildFloatingSosButton(
                              context,
                              tracking,
                              size: buttonSize,
                              compact: isCompact,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildFloatingSosButton(
    BuildContext context,
    HikingTrackingService tracking, {
    required double size,
    required bool compact,
  }) {
    final sosColor = context.errorColor;
    final label = context.trText('Buka panel SOS');
    return Semantics(
      button: true,
      enabled: !tracking.isStopping,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: sosColor,
          elevation: 8,
          shadowColor: sosColor.withAlpha(100),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap:
                tracking.isStopping
                    ? null
                    : () => _confirmSendSos(context, tracking),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: compact ? 28 : 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startTracking(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    final volcanoProvider = context.read<VolcanoProvider>();
    final started = await tracking.start(
      region: volcanoProvider.selectedRegion,
    );
    if (!context.mounted || started) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tracking.error ?? context.trTextSafe('Tracking belum dapat dimulai.'),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildTrackingConfirmDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String confirmLabel,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    final primaryText = context.textPrimary;
    final secondaryText = context.textSecondary;
    final actionForeground =
        context.isHighContrast ? context.bgPrimary : Colors.white;

    return AlertDialog(
      backgroundColor: context.bgSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.bgSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: context.errorColor, size: 28),
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: AppFonts.plusJakartaSans(
          color: primaryText,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      content: Text(
        description,
        textAlign: TextAlign.center,
        style: AppFonts.plusJakartaSans(
          color: secondaryText,
          fontSize: 13.5,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryText,
                  side: BorderSide(
                    color: context.borderColor,
                    width: context.borderWidth,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr('cancel'),
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: primaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: context.errorColor,
                  foregroundColor: actionForeground,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: actionForeground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmSendSos(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    if (!tracking.hasActiveSos) {
      final send = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => _buildTrackingConfirmDialog(
              dialogContext,
              icon: Icons.sos_rounded,
              title: dialogContext.trText('Kirim sinyal SOS?'),
              description: dialogContext.trText(
                'Kirim sinyal SOS beserta lokasi GPS terakhir yang tersedia?',
              ),
              confirmLabel: dialogContext.trText('Kirim SOS'),
              onCancel: () => Navigator.pop(dialogContext, false),
              onConfirm: () => Navigator.pop(dialogContext, true),
            ),
      );
      if (send != true || !context.mounted) return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HikingSosPanel(tracking: tracking),
    );
  }

  Future<void> _finishTracking(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => _buildTrackingConfirmDialog(
            dialogContext,
            icon: Icons.stop_circle_rounded,
            title: dialogContext.tr('finish_tracking'),
            description: dialogContext.trText(
              'Sesi tracking akan dihentikan dan lokasi baru tidak lagi direkam setelah pendakian diselesaikan.',
            ),
            confirmLabel: dialogContext.trText('Selesaikan'),
            onCancel: () => Navigator.pop(dialogContext, false),
            onConfirm: () => Navigator.pop(dialogContext, true),
          ),
    );
    if (confirmed == true) await tracking.stop();
  }

  /// Dialog konfirmasi untuk menghapus / reset riwayat tracking lokal
  Future<void> _confirmResetTracking(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => _buildTrackingConfirmDialog(
            dialogContext,
            icon: Icons.restart_alt_rounded,
            title: dialogContext.trText('Reset Riwayat Tracking?'),
            description:
                tracking.isActive
                    ? dialogContext.trText(
                      'Tracking saat ini sedang aktif. Mereset akan menghentikan sesi dan menghapus seluruh durasi, rute, serta jarak tempuh saat ini.',
                    )
                    : dialogContext.trText(
                      'Semua riwayat tracking lokal meliputi durasi, jarak tempuh, dan titik koordinat rute akan dihapus dan kembali ke nol.',
                    ),
            confirmLabel: dialogContext.trText('Ya, Reset'),
            onCancel: () => Navigator.pop(dialogContext, false),
            onConfirm: () => Navigator.pop(dialogContext, true),
          ),
    );

    if (confirmed == true) {
      await tracking.reset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.trTextSafe('Riwayat tracking berhasil di-reset.'),
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

/// Strip telemetri GPS ringkas bergaya minimalis modern.
/// Tampil 1 baris padat saat normal/aktif dan otomatis meluas 2 baris saat ada
/// peringatan geofence atau sinyal GPS bermasalah.
class _HikingStatusBanner extends StatelessWidget {
  const _HikingStatusBanner({required this.tracking, this.onTap});

  final HikingTrackingService tracking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final trackingStatus = tracking.trackingStatus;
    final isOutsideGrace =
        tracking.isActive &&
        trackingStatus == HikingTrackingStatus.outsideGrace;
    final isGpsUnavailable =
        tracking.isActive &&
        trackingStatus == HikingTrackingStatus.gpsUnavailable;
    final isAlert = isOutsideGrace || isGpsUnavailable;
    final location = tracking.locationService;
    final isActive = tracking.isActive;
    final hasFreshGps = location.hasFreshRealPosition;
    final isGpsReady = location.gpsStatus == GpsStatus.active;

    final accentColor =
        tracking.isPaused
            ? context.textSecondary
            : isAlert
            ? context.warningColor
            : context.successColor;

    final statusText =
        tracking.isPaused
            ? context.trText('Tracking dijeda')
            : isOutsideGrace
            ? context.trText('Di luar radius pendakian')
            : isGpsUnavailable
            ? context.trText('Sinyal GPS tidak tersedia atau tidak akurat')
            : isActive
            ? context.trText('Tracking aktif')
            : isGpsReady
            ? context.trText('GPS siap')
            : context.trText('Menunggu GPS...');

    final distanceFromRadius = tracking.distanceFromHikingRadiusKm;
    final outsideDistanceText =
        distanceFromRadius == null
            ? ''
            : distanceFromRadius >= 0
            ? '${distanceFromRadius.toStringAsFixed(1)} km di luar batas'
            : '${distanceFromRadius.abs().toStringAsFixed(1)} km di dalam batas';
    final remaining = tracking.outsideGraceRemaining;
    final remainingText =
        '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    final coordCompact =
        '${location.userLat.toStringAsFixed(4)}, ${location.userLng.toStringAsFixed(4)}';
    final accuracy = location.accuracyMeters;
    final accuracyTag =
        hasFreshGps && accuracy != null ? '±${accuracy.round()}m' : null;
    final rightTelemetry =
        hasFreshGps
            ? coordCompact
            : '${context.trText('Terakhir')} · $coordCompact';

    final bgColor =
        isHC
            ? context.bgSurface
            : isAlert
            ? accentColor.withAlpha(16)
            : isActive && !tracking.isPaused
            ? accentColor.withAlpha(12)
            : context.bgSurface;
    final borderColor =
        isHC
            ? (isAlert || isActive ? accentColor : context.borderColor)
            : (isAlert || (isActive && !tracking.isPaused))
            ? accentColor.withAlpha(110)
            : context.borderColor;

    final statusDotColor =
        tracking.isPaused
            ? context.textTertiary
            : isAlert
            ? accentColor
            : (isActive || isGpsReady)
            ? accentColor
            : context.textTertiary;

    return AnimatedSize(
      duration:
          context.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('hiking_gps_telemetry_strip'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isAlert ? 10 : 8.5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: (isAlert || isActive) ? 1.2 : context.borderWidth,
              ),
            ),
            child:
                isAlert
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isOutsideGrace
                                  ? Icons.location_off_rounded
                                  : Icons.gps_off_rounded,
                              size: 15,
                              color: accentColor,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            if (isOutsideGrace) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isHC
                                          ? context.bgPrimary
                                          : accentColor.withAlpha(28),
                                  borderRadius: BorderRadius.circular(6),
                                  border:
                                      isHC
                                          ? Border.all(color: accentColor)
                                          : null,
                                ),
                                child: Text(
                                  remainingText,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Text(
                            isOutsideGrace
                                ? outsideDistanceText
                                : context.trText(
                                  'Pencatatan titik ditahan · sesi tetap berjalan',
                                ),
                            style: AppFonts.plusJakartaSans(
                              fontSize: 11,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                    : Row(
                      children: [
                        // Indikator titik live minimalis
                        Container(
                          width: 14,
                          height: 14,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusDotColor.withAlpha(isHC ? 55 : 36),
                          ),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusDotColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          maxLines: 1,
                          softWrap: false,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isActive && !tracking.isPaused
                                    ? accentColor
                                    : context.textPrimary,
                          ),
                        ),
                        if (accuracyTag != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isHC
                                      ? context.bgPrimary
                                      : context.bgSecondary,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: context.borderColor,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              accuracyTag,
                              style: AppFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: context.textSecondary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rightTelemetry,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (onTap != null) ...[
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: context.textTertiary,
                          ),
                        ],
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class _HikingStatsGrid extends StatelessWidget {
  const _HikingStatsGrid({required this.tracking});
  final HikingTrackingService tracking;

  @override
  Widget build(BuildContext context) {
    final elapsed = tracking.elapsed;
    final distance = tracking.distanceKm;
    final distanceLabel =
        distance < 1
            ? '${(distance * 1000).round()} m'
            : '${distance.toStringAsFixed(2)} km';
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final duration = '$hours:$minutes:$seconds';

    return Row(
      children: [
        Expanded(
          child: _HikingStatTile(
            label: context.trText('Durasi'),
            value: duration,
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HikingStatTile(
            label: context.trText('Jarak'),
            value: distanceLabel,
            icon: Icons.route_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HikingStatTile(
            label: context.tr('gps_point'),
            value: '${tracking.pointsRecorded}',
            icon: Icons.pin_drop_outlined,
          ),
        ),
      ],
    );
  }
}

class _HikingStatTile extends StatelessWidget {
  const _HikingStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accentColor = context.successColor;
    final cardBg = context.bgSurface;
    final cardBorder = context.borderColor;
    final textDark = context.textPrimary;
    final textMuted = context.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: context.borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: AppFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppFonts.plusJakartaSans(fontSize: 11, color: textMuted),
          ),
        ],
      ),
    );
  }
}
