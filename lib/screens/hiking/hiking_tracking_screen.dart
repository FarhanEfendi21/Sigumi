import 'dart:async';
import '../../services/localization_service.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../config/theme_extensions.dart';
import '../../providers/volcano_provider.dart';
import '../../services/hiking_tracking_service.dart';
import '../../services/location_service.dart';
import '../../widgets/hiking_weather_card.dart';
import '../../widgets/hiking_sos_panel.dart';

/// Titik koordinat pos resmi jalur pendakian Gunung Rinjani (Jalur Sembalun).
class _RinjaniWaypoint {
  final String name;
  final String altitude;
  final LatLng point;
  final IconData icon;

  const _RinjaniWaypoint({
    required this.name,
    required this.altitude,
    required this.point,
    this.icon = Icons.flag_rounded,
  });
}

const List<_RinjaniWaypoint> _rinjaniWaypoints = [
  _RinjaniWaypoint(
    name: 'Gerbang Sembalun',
    altitude: '1.050 mdpl',
    point: LatLng(-8.3585, 116.5280),
    icon: Icons.meeting_room_rounded,
  ),
  _RinjaniWaypoint(
    name: 'Pos 1 Pemantauan',
    altitude: '1.300 mdpl',
    point: LatLng(-8.3750, 116.5180),
    icon: Icons.home_repair_service_rounded,
  ),
  _RinjaniWaypoint(
    name: 'Pos 2 Tengengean',
    altitude: '1.500 mdpl',
    point: LatLng(-8.3880, 116.5050),
    icon: Icons.water_drop_rounded,
  ),
  _RinjaniWaypoint(
    name: 'Pos 3 Pada Balong',
    altitude: '1.800 mdpl',
    point: LatLng(-8.3980, 116.4880),
    icon: Icons.cabin_rounded,
  ),
  _RinjaniWaypoint(
    name: 'Plawangan Sembalun',
    altitude: '2.639 mdpl',
    point: LatLng(-8.4050, 116.4680),
    icon: Icons.holiday_village_rounded,
  ),
  _RinjaniWaypoint(
    name: 'Puncak Rinjani',
    altitude: '3.726 mdpl',
    point: LatLng(-8.4111, 116.4573),
    icon: Icons.terrain_rounded,
  ),
];

const List<_RinjaniWaypoint> _agungWaypoints = [
  _RinjaniWaypoint(
    name: 'Pura Pasar Agung',
    altitude: '1.609 mdpl',
    point: LatLng(-8.36866, 115.50317),
    icon: Icons.meeting_room_rounded,
  ),
  _RinjaniWaypoint(
    name: 'Puncak Gunung Agung',
    altitude: '3.142 mdpl',
    point: LatLng(-8.3415, 115.5033),
    icon: Icons.terrain_rounded,
  ),
];

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

        // Sesi aktif/terjeda harus bisa dibuka kembali dari riwayat sesi
        // tersimpan, walaupun GPS sedang belum mendapat fix baru.
        final profileRegion =
            volcanoProvider.selectedRegion.trim().toLowerCase();
        final profileAllowsAgung =
            profileRegion == 'bali' && location.isWithinHikingRegion('bali');
        final profileAllowsRinjani =
            profileRegion == 'lombok' &&
            location.isWithinHikingRegion('lombok');
        final activeSessionCanOpen =
            tracking.isActive &&
            const {'bali', 'lombok'}.contains(tracking.trackingRegion);
        if (!profileAllowsAgung &&
            !profileAllowsRinjani &&
            !activeSessionCanOpen) {
          return _HikingUnavailableView(
            currentRegion: volcanoProvider.selectedRegion,
          );
        }

        return const _HikingTrackingView();
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
/// Tidak ada tombol redirect wilayah — user cukup diberi informasi.
class _HikingUnavailableView extends StatelessWidget {
  final String currentRegion;

  const _HikingUnavailableView({required this.currentRegion});

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

  // Titik tengah jalur pendakian
  static const LatLng _rinjaniCenter = LatLng(-8.3900, 116.4950);
  static const LatLng _agungCenter = LatLng(-8.36866, 115.50317);

  Color get _bg => context.bgPrimary;
  Color get _cardBg => context.bgSurface;
  Color get _cardBorder => context.borderColor;
  Color get _accentColor => context.successColor;
  Color get _textDark => context.textPrimary;
  Color get _textMuted => context.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Consumer<HikingTrackingService>(
      builder: (context, tracking, _) {
        final location = tracking.locationService;
        final userPoint = LatLng(location.userLat, location.userLng);

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

        final mountainCenter = isUserInAgung ? _agungCenter : _rinjaniCenter;
        final waypoints = isUserInAgung ? _agungWaypoints : _rinjaniWaypoints;
        final defaultCenter =
            (isUserInAgung || isUserInLombok) ? userPoint : _rinjaniCenter;

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
                            child: Text(
                              context.trText('Tracking Pendakian'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                          ),
                          if (tracking.hasHistory)
                            IconButton(
                              tooltip: context.trText('Reset Riwayat Tracking'),
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
                                color: context.errorColor,
                                size: 22,
                              ),
                            ),
                          IconButton(
                            tooltip: context.trText(
                              isUserInAgung
                                  ? 'Pusatkan ke Agung'
                                  : 'Pusatkan ke Rinjani',
                            ),
                            onPressed:
                                () => _mapController.move(mountainCenter, 12.5),
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

                    // Label gunung
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          context.trText(
                            isUserInAgung
                                ? 'GUNUNG AGUNG · 3.142 MDPL'
                                : 'GUNUNG RINJANI · 3.726 MDPL',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: context.accentPrimary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Konten scrollable
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          tracking.isActive ? 108 : 24,
                        ),
                        children: [
                          _HikingStatusBanner(tracking: tracking),

                          const SizedBox(height: 12),

                          HikingWeatherCard(
                            latitude: location.userLat,
                            longitude: location.userLng,
                            cacheRegion: weatherRegion,
                            canFetch: location.hasFreshRealPosition,
                          ),

                          const SizedBox(height: 12),

                          // Peta
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              height: 260,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _cardBorder,
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
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
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.sigumi.app',
                                      ),
                                      PolylineLayer(
                                        polylines: [
                                          if (!isUserInAgung)
                                            Polyline(
                                              points:
                                                  waypoints
                                                      .map((w) => w.point)
                                                      .toList(),
                                              strokeWidth: 4.0,
                                              color: _accentColor,
                                            ),
                                          if (tracking.routePoints.length >= 2)
                                            Polyline(
                                              points: tracking.routePoints,
                                              strokeWidth: 4.5,
                                              color:
                                                  context.isHighContrast
                                                      ? context.accentSecondary
                                                      : const Color(0xFF2563EB),
                                            ),
                                        ],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          ...waypoints.map((w) {
                                            return Marker(
                                              point: w.point,
                                              width: 80,
                                              height: 54,
                                              child: GestureDetector(
                                                onTap: () {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '${context.trText(w.name)} (${context.trText(w.altitude)})',
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                      backgroundColor:
                                                          _textDark,
                                                    ),
                                                  );
                                                },
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            context.bgSurface,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: _accentColor,
                                                          width: 1.8,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withAlpha(25),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        w.icon,
                                                        size: 13,
                                                        color: _accentColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 1.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            context.bgSurface,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: _cardBorder,
                                                          width: 0.8,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withAlpha(15),
                                                            blurRadius: 3,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        w.name
                                                            .replaceAll(
                                                              'Sembalun',
                                                              '',
                                                            )
                                                            .trim(),
                                                        style: TextStyle(
                                                          fontSize: 8.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: _textDark,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                          Marker(
                                            point: userPoint,
                                            width: 48,
                                            height: 48,
                                            child: Icon(
                                              Icons.person_pin_circle_rounded,
                                              color: _accentColor,
                                              size: 40,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Badge jalur pojok atas peta
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.bgSurface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _cardBorder),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.route_rounded,
                                            color: _accentColor,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            context.trText('Jalur Sembalun'),
                                            style: TextStyle(
                                              color: _textDark,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

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

/// Status banner light clean theme
class _HikingStatusBanner extends StatelessWidget {
  const _HikingStatusBanner({required this.tracking});
  final HikingTrackingService tracking;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        tracking.isPaused ? context.textSecondary : context.successColor;
    final cardBg = context.bgSurface;
    final cardBorder = context.borderColor;
    final textDark = context.textPrimary;
    final textMuted = context.textSecondary;
    final location = tracking.locationService;
    final isActive = tracking.isActive;
    final hasFreshGps = location.hasFreshRealPosition;

    final statusText =
        tracking.isPaused
            ? context.trText('Tracking dijeda · riwayat tetap tersimpan')
            : isActive && hasFreshGps
            ? context.trText('Tracking aktif')
            : isActive
            ? context.trText('Menunggu sinyal GPS · posisi terakhir tersimpan')
            : location.gpsStatus == GpsStatus.active
            ? context.trText('GPS siap · Rinjani')
            : context.trText('Menunggu GPS...');

    final coordinatePrefix =
        hasFreshGps ? '' : '${context.trText('Terakhir')}: ';
    final coordText =
        '$coordinatePrefix${location.userLat.toStringAsFixed(5)}, ${location.userLng.toStringAsFixed(5)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive && !context.isHighContrast
                  ? accentColor.withAlpha(120)
                  : cardBorder,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isActive && !context.isHighContrast
                    ? accentColor.withAlpha(20)
                    : Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  context.isHighContrast
                      ? context.bgPrimary
                      : (isActive ? accentColor : textMuted).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tracking.isPaused
                  ? Icons.pause_circle_outline_rounded
                  : isActive
                  ? Icons.gps_fixed
                  : Icons.gps_not_fixed,
              color: isActive ? accentColor : textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? accentColor : textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coordText,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isActive && !tracking.isPaused)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withAlpha(120),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
        ],
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
            value: '${tracking.distanceKm.toStringAsFixed(2)} km',
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
