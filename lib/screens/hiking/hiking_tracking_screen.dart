import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../services/hiking_tracking_service.dart';
import '../../services/location_service.dart';

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

class HikingTrackingScreen extends StatelessWidget {
  const HikingTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      Provider.of<HikingTrackingService>(context, listen: false);
      return const _HikingTrackingDispatcher();
    } catch (_) {
      return ChangeNotifierProvider(
        create: (_) => HikingTrackingService(),
        child: const _HikingTrackingDispatcher(),
      );
    }
  }
}

/// Dispatcher: cek auth dulu, lalu dispatch ke tampilan yang tepat.
/// - Belum login → gate login
/// - GPS bukan Rinjani → info "di luar wilayah pendakian"
/// - GPS di Rinjani → tampilan tracking aktif
class _HikingTrackingDispatcher extends StatelessWidget {
  const _HikingTrackingDispatcher();

  /// Cek apakah koordinat GPS berada di area pendakian Gunung Rinjani.
  /// Batas longgar: mencakup zona KRB Rinjani dan area sekitar jalur pendakian.
  static bool _isInRinjaniArea(double lat, double lng) {
    return lat <= -8.1 && lat >= -8.9 && lng >= 115.9 && lng <= 117.0;
  }

  @override
  Widget build(BuildContext context) {
    final volcanoProvider = context.watch<VolcanoProvider>();
    final tracking = context.watch<HikingTrackingService>();
    final location = tracking.locationService;

    // ── Gate 1: Belum login ──
    if (volcanoProvider.isGuest) {
      return const _HikingLoginGate();
    }

    // ── Gate 2: GPS tidak di area Rinjani (dan tidak sedang aktif tracking) ──
    // Jika tracking sedang aktif, tetap tampilkan view penuh (jangan interrupt)
    final inRinjani = _isInRinjaniArea(location.userLat, location.userLng);
    if (!inRinjani && !tracking.isActive) {
      return _HikingUnavailableView(
        currentRegion: volcanoProvider.selectedRegion,
      );
    }

    return const _HikingTrackingView();
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
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        [peakColor.withAlpha(60), peakColor.withAlpha(30)],
      );

    final bgPath = ui.Path()
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
    final fgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(w / 2, 0),
        Offset(w / 2, h),
        [peakColor.withAlpha(160), peakColor.withAlpha(220)],
      );

    final fgPath = ui.Path()
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
    final fogPaint = Paint()
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

/// Tampilan minimalis ketika GPS user tidak berada di area pendakian Rinjani.
/// Tidak ada tombol redirect wilayah — user cukup diberi informasi.
class _HikingUnavailableView extends StatelessWidget {
  final String currentRegion;

  const _HikingUnavailableView({
    required this.currentRegion,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgTop = Colors.white;
    const Color bgBottom = Color(0xFFF1F5F9);
    const Color peakColor = Color(0xFFE2E8F0);
    const Color accentColor = Color(0xFF16A34A);
    const Color textDark = Color(0xFF1E293B);
    const Color textMuted = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgTop,
      body: Stack(
        children: [
          // Clean gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, Color(0xFFF8FAFC), bgBottom],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: textDark, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Tracking Pendakian',
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
                      color: const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    'Anda Tidak Berada di\nWilayah Pendakian',
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
                    'Fitur tracking aktif saat GPS Anda\nterdeteksi di area Gunung Rinjani, Lombok.',
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
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Kembali',
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
    const Color bgTop = Colors.white;
    const Color bgBottom = Color(0xFFF1F5F9);
    const Color peakColor = Color(0xFFE2E8F0);
    const Color accentColor = Color(0xFF16A34A);
    const Color textDark = Color(0xFF1E293B);
    const Color textMuted = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgTop,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, Color(0xFFF8FAFC), bgBottom],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: textDark, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Tracking Pendakian',
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
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withAlpha(20),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
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
                    'Masuk untuk Mulai\nTracking Pendakian',
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
                    'Fitur tracking pendakian memerlukan akun\nuntuk menyimpan dan memantau jalur Anda.',
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
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      elevation: 2,
                      shadowColor: accentColor.withAlpha(80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Masuk Akun',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Kembali',
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

/// Tampilan tracking aktif ketika user berada di wilayah Lombok (Gunung Rinjani).
class _HikingTrackingView extends StatefulWidget {
  const _HikingTrackingView();

  @override
  State<_HikingTrackingView> createState() => _HikingTrackingViewState();
}

class _HikingTrackingViewState extends State<_HikingTrackingView> {
  final MapController _mapController = MapController();

  // Titik tengah default jalur pendakian Rinjani Sembalun
  static const LatLng _rinjaniCenter = LatLng(-8.3900, 116.4950);

  // Warna tema putih bersih & modern
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _accentColor = Color(0xFF16A34A);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Consumer<HikingTrackingService>(
      builder: (context, tracking, _) {
        final location = tracking.locationService;
        final userPoint = LatLng(location.userLat, location.userLng);

        final isUserInLombok = location.userLat <= -8.1 &&
            location.userLat >= -8.9 &&
            location.userLng >= 115.9 &&
            location.userLng <= 116.9;

        final defaultCenter = isUserInLombok ? userPoint : _rinjaniCenter;

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
                    peakColor: const Color(0xFFDCFCE7).withAlpha(140),
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
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: _textDark, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Expanded(
                            child: Text(
                              'Tracking Pendakian',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                          ),
                          if (tracking.hasHistory)
                            IconButton(
                              tooltip: 'Reset Riwayat Tracking',
                              onPressed: tracking.isStarting || tracking.isStopping
                                  ? null
                                  : () => _confirmResetTracking(context, tracking),
                              icon: const Icon(Icons.restart_alt_rounded,
                                  color: Color(0xFFDC2626), size: 22),
                            ),
                          IconButton(
                            tooltip: 'Pusatkan ke Rinjani',
                            onPressed: () =>
                                _mapController.move(_rinjaniCenter, 12.5),
                            icon: const Icon(Icons.terrain_rounded,
                                color: _textDark, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Lokasi saya',
                            onPressed: () =>
                                _mapController.move(userPoint, 15),
                            icon: const Icon(Icons.my_location_rounded,
                                color: _textDark, size: 20),
                          ),
                        ],
                      ),
                    ),

                    // Label gunung
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
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
                        child: const Text(
                          'GUNUNG RINJANI · 3.726 MDPL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Konten scrollable
                    Expanded(
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          _HikingStatusBanner(tracking: tracking),

                          const SizedBox(height: 12),

                          // Peta
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              height: 260,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _cardBorder,
                                    width: 1.2),
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
                                          isUserInLombok ? 13.5 : 12.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.sigumi.app',
                                      ),
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: _rinjaniWaypoints
                                                .map((w) => w.point)
                                                .toList(),
                                            strokeWidth: 4.0,
                                            color: _accentColor,
                                          ),
                                          if (tracking.routePoints.length >= 2)
                                            Polyline(
                                              points: tracking.routePoints,
                                              strokeWidth: 4.5,
                                              color: const Color(0xFF2563EB),
                                            ),
                                        ],
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          ..._rinjaniWaypoints.map((w) {
                                            return Marker(
                                              point: w.point,
                                              width: 80,
                                              height: 54,
                                              child: GestureDetector(
                                                onTap: () {
                                                  ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(SnackBar(
                                                    content: Text(
                                                        '${w.name} (${w.altitude})'),
                                                    duration: const Duration(
                                                        seconds: 2),
                                                    backgroundColor:
                                                        _textDark,
                                                  ));
                                                },
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .all(4.5),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: Colors.white,
                                                        shape:
                                                            BoxShape.circle,
                                                        border: Border.all(
                                                          color:
                                                              _accentColor,
                                                          width: 1.8,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withAlpha(25),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Icon(w.icon,
                                                          size: 13,
                                                          color:
                                                              _accentColor),
                                                    ),
                                                    const SizedBox(
                                                        height: 2),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5,
                                                          vertical: 1.5),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: Colors.white.withAlpha(240),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    4),
                                                        border: Border.all(
                                                          color: _cardBorder,
                                                          width: 0.8,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withAlpha(15),
                                                            blurRadius: 3,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        w.name
                                                            .replaceAll(
                                                                'Sembalun',
                                                                '')
                                                            .trim(),
                                                        style:
                                                            const TextStyle(
                                                          fontSize: 8.5,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700,
                                                          color: _textDark,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
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
                                            child: const Icon(
                                              Icons
                                                  .person_pin_circle_rounded,
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
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(240),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(color: _cardBorder),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.route_rounded,
                                              color: _accentColor,
                                              size: 13),
                                          SizedBox(width: 5),
                                          Text(
                                            'Jalur Sembalun',
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
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFFECACA)),
                              ),
                              child: Text(
                                tracking.error!,
                                style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 12),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          FilledButton.icon(
                            onPressed:
                                tracking.isStarting || tracking.isStopping
                                    ? null
                                    : () => tracking.isActive
                                        ? _finishTracking(
                                            context, tracking)
                                        : _startTracking(
                                            context, tracking),
                            icon: Icon(
                              tracking.isActive
                                  ? Icons.stop_circle_outlined
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              tracking.isStarting
                                  ? 'Menyiapkan GPS...'
                                  : tracking.isStopping
                                      ? 'Menyelesaikan...'
                                      : tracking.isActive
                                          ? 'Selesaikan Pendakian'
                                          : 'Mulai Tracking',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: tracking.isActive
                                  ? const Color(0xFFDC2626)
                                  : _accentColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              elevation: 2,
                              shadowColor: (tracking.isActive
                                      ? const Color(0xFFDC2626)
                                      : _accentColor)
                                  .withAlpha(80),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),

                          // Tombol Reset Tracking jika terdapat riwayat tracking
                          if (tracking.hasHistory) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: tracking.isStarting || tracking.isStopping
                                  ? null
                                  : () => _confirmResetTracking(context, tracking),
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              label: Text(
                                'Reset Riwayat Tracking',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                backgroundColor: const Color(0xFFFEF2F2),
                                side: const BorderSide(
                                    color: Color(0xFFFECACA), width: 1.2),
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
                            'Lokasi tersinkron ke Posko SAR selama tracking aktif.',
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
            ],
          ),
        );
      },
    );
  }

  Future<void> _startTracking(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    final volcanoProvider = context.read<VolcanoProvider>();
    final started =
        await tracking.start(region: volcanoProvider.selectedRegion);
    if (!context.mounted || started) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(tracking.error ?? 'Tracking belum dapat dimulai.'),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  Future<void> _finishTracking(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Selesaikan tracking?',
            style: TextStyle(color: _textDark, fontWeight: FontWeight.w700)),
        content: const Text(
          'Posko SAR tidak akan menerima pembaruan koordinat setelah sesi diselesaikan.',
          style: TextStyle(color: _textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: _textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Selesaikan'),
          ),
        ],
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restart_alt_rounded,
              color: Color(0xFFDC2626),
              size: 28,
            ),
          ),
        ),
        title: Text(
          'Reset Riwayat Tracking?',
          textAlign: TextAlign.center,
          style: AppFonts.plusJakartaSans(
            color: _textDark,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Text(
          tracking.isActive
              ? 'Tracking saat ini sedang aktif. Mereset akan menghentikan sesi dan menghapus seluruh durasi, rute, serta jarak tempuh saat ini.'
              : 'Semua riwayat tracking lokal meliputi durasi, jarak tempuh, dan titik koordinat rute akan dihapus dan kembali ke nol.',
          textAlign: TextAlign.center,
          style: AppFonts.plusJakartaSans(
            color: _textMuted,
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
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _textDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Ya, Reset',
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await tracking.reset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Riwayat tracking berhasil di-reset.',
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
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

  static const Color _accentColor = Color(0xFF16A34A);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final location = tracking.locationService;
    final isActive = tracking.isActive;

    final statusText = isActive
        ? 'Tracking aktif'
        : location.gpsStatus == GpsStatus.active
            ? 'GPS siap · Rinjani'
            : 'Menunggu GPS...';

    final coordText =
        '${location.userLat.toStringAsFixed(5)}, ${location.userLng.toStringAsFixed(5)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _accentColor.withAlpha(120) : _cardBorder,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? _accentColor.withAlpha(20)
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
              color: (isActive ? _accentColor : _textMuted).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: isActive ? _accentColor : _textMuted,
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
                    color: isActive ? _accentColor : _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coordText,
                  style: AppFonts.plusJakartaSans(
                      fontSize: 11, color: _textMuted),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withAlpha(120),
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

/// Stats grid light clean theme
class _HikingStatsGrid extends StatelessWidget {
  const _HikingStatsGrid({required this.tracking});
  final HikingTrackingService tracking;

  @override
  Widget build(BuildContext context) {
    final elapsed = tracking.elapsed;
    final duration =
        '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: _HikingStatTile(
            label: 'Durasi',
            value: duration,
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HikingStatTile(
            label: 'Jarak',
            value: '${tracking.distanceKm.toStringAsFixed(2)} km',
            icon: Icons.route_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HikingStatTile(
            label: 'Titik GPS',
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

  static const Color _accentColor = Color(0xFF16A34A);
  static const Color _cardBg = Colors.white;
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
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
          Icon(icon, size: 18, color: _accentColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style:
                AppFonts.plusJakartaSans(fontSize: 11, color: _textMuted),
          ),
        ],
      ),
    );
  }
}
