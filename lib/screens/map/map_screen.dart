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
import '../../providers/volcano_provider.dart';
import '../../services/location_service.dart';

import 'widgets/blur_top_bar.dart';
import 'widgets/map_controls.dart';
import 'widgets/primary_info_card.dart';
import 'widgets/risk_bottom_sheet.dart';

/// Peta Risiko — Menampilkan lokasi real-time user, gunung berapi,
/// dan zona bahaya menggunakan data PostGIS dari Supabase.
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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
        showRetry: locationService.gpsStatus == GpsStatus.error || 
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
      // Hanya tampilkan snackbar kalau statusnya baru berubah ke error
      if (locationService.gpsStatus == GpsStatus.error && !_hasShownInitialError) {
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

  /// Tampilkan snackbar sementara (bukan persistent) untuk status GPS
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
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError 
            ? Colors.orange.shade700 
            : SigumiTheme.statusNormal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.22,
          left: 16,
          right: 16,
        ),
        duration: duration,
        action: showRetry
            ? SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
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
    // Remove listener saat dispose
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
    // Refresh lokasi dulu, lalu pindah kamera
    locationService.refreshLocation().then((_) {
      if (mounted) {
        final pos = LatLng(locationService.userLat, locationService.userLng);
        _mapController.move(pos, 13);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VolcanoProvider, LocationService>(
      builder: (context, provider, locationService, _) {
        // Data dari LocationService (real GPS + PostGIS calculation)
        final distance = locationService.distanceFromVolcano;
        final zoneLevel = locationService.zoneLevel;
        final zoneLabel = locationService.zoneLabel;

        // Koordinat user (real GPS atau fallback)
        final userPos = LatLng(
          locationService.userLat,
          locationService.userLng,
        );

        // Koordinat gunung berapi aktif
        final volcanoPos = LatLng(
          provider.volcano.latitude,
          provider.volcano.longitude,
        );

        return Scaffold(
          backgroundColor: Colors.white,
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
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: volcanoPos,
                        radius: _kmToMeter(20),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusNormal.withAlpha(15),
                        borderColor: SigumiTheme.statusNormal.withAlpha(50),
                        borderStrokeWidth: 1,
                      ),
                      CircleMarker(
                        point: volcanoPos,
                        radius: _kmToMeter(15),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusWaspada.withAlpha(20),
                        borderColor: SigumiTheme.statusWaspada.withAlpha(60),
                        borderStrokeWidth: 1.5,
                      ),
                      CircleMarker(
                        point: volcanoPos,
                        radius: _kmToMeter(10),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusSiaga.withAlpha(25),
                        borderColor: SigumiTheme.statusSiaga.withAlpha(80),
                        borderStrokeWidth: 1.5,
                      ),
                      CircleMarker(
                        point: volcanoPos,
                        radius: _kmToMeter(5),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusAwas.withAlpha(35),
                        borderColor: SigumiTheme.statusAwas.withAlpha(100),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ).animate().fadeIn(duration: 800.ms),

                  // ── Map Markers ──
                  MarkerLayer(
                    markers: [
                      // User Marker — posisi dari GPS real-time
                      Marker(
                        point: userPos,
                        width: 48,
                        height: 48,
                        child: _buildUserMarker(locationService),
                      ),
                      // Volcano Marker — dengan glow animasi
                      Marker(
                        point: volcanoPos,
                        width: 80,
                        height: 80,
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(
                                        (100 * _glowController.value).toInt()),
                                    blurRadius: 20 * _glowController.value,
                                    spreadRadius: 10 * _glowController.value,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.volcano_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
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

              // ── GPS Status Badge (Subtle) ──
              // Badge kecil di pojok kiri bawah top bar — hanya tampil saat ada masalah
              if (locationService.gpsStatus != GpsStatus.active && 
                  locationService.gpsStatus != GpsStatus.unknown)
                Positioned(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                  left: 16,
                  child: _buildGpsBadge(locationService),
                ),

              // ── Kontrol Overlay UI ──
              IgnorePointer(
                ignoring: _isMapFocused,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isMapFocused ? 0.0 : 1.0,
                  child: Stack(
                    children: [
                      // Layer 3: Floating Map Controls (Right)
                      Positioned(
                        top: MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            16,
                        right: 16,
                        child: MapControls(
                          onLocateMerapi: () =>
                              _mapController.move(volcanoPos, 11),
                          onLocateUser: () =>
                              _recenterToUser(locationService),
                        ),
                      ).animate().fadeIn().slideX(begin: 0.2),

                      // Layer: Floating Posko & Faskes Button (Left)
                      Positioned(
                        top: MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            16 +
                            // Beri space kalau ada GPS badge
                            (locationService.gpsStatus != GpsStatus.active && 
                             locationService.gpsStatus != GpsStatus.unknown
                                ? 44 : 0),
                        left: 16,
                        child: ShadcnMapButton(
                          icon: Icons.health_and_safety_rounded,
                          tooltip: 'Posko & Faskes',
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.postDisaster),
                        ),
                      ).animate().fadeIn().slideX(begin: -0.2),

                      // Layer 4: Primary Info Card (Status & Distance)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom:
                            MediaQuery.of(context).size.height * 0.18 + 16,
                        child: Hero(
                          tag: 'primary_info_card',
                          child: PrimaryInfoCard(
                            distance: distance,
                            zoneLevel: zoneLevel,
                          ),
                        ),
                      ),

                      // Layer 5: Draggable Bottom Sheet
                      RiskBottomSheet(
                        distance: distance,
                        zoneLabel: zoneLabel,
                      ),
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

  /// User marker — biru untuk real GPS, abu-abu untuk simulasi
  /// Dengan pulse ring saat GPS aktif
  Widget _buildUserMarker(LocationService locationService) {
    final isRealGps = locationService.isUsingRealGps;
    final isActive = locationService.gpsStatus == GpsStatus.active;
    final color = isRealGps ? const Color(0xFF2563EB) : Colors.grey.shade500;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring — hanya tampil saat GPS aktif & tracking
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
              .fadeOut(
                begin: 0.6,
                duration: 2000.ms,
              ),

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

  /// Badge GPS kecil yang subtle — hanya tampil saat ada masalah
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
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade600;
        label = 'GPS Tidak Stabil';
        break;
      case GpsStatus.error:
        icon = Icons.gps_off_rounded;
        bgColor = Colors.red.shade50;
        iconColor = Colors.red.shade500;
        label = 'GPS Error';
        showRetry = true;
        break;
      case GpsStatus.disabled:
        icon = Icons.location_disabled_rounded;
        bgColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade600;
        label = 'GPS Nonaktif';
        break;
      case GpsStatus.denied:
        icon = Icons.block_rounded;
        bgColor = Colors.red.shade50;
        iconColor = Colors.red.shade400;
        label = 'Izin Ditolak';
        showRetry = true;
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: showRetry
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
          border: Border.all(color: iconColor.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading spinner saat retrying
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
