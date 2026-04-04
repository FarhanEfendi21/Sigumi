import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

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

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _glowController;
  bool _isMapFocused = false;

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
    await locationService.initialize();
    locationService.startTracking(distanceFilterMeters: 30);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  double _kmToMeter(double km) => km * 1000;

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
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sigumi.app',
                    maxZoom: 19,
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
                        width: 40,
                        height: 40,
                        child: _buildUserMarker(locationService.isUsingRealGps),
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
                                    color: Colors.red.withAlpha((100 * _glowController.value).toInt()),
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
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.volcano_rounded, color: Colors.white, size: 24),
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

              // ── GPS status indicator ──
              if (locationService.locationError != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                  left: 16,
                  right: 16,
                  child: _buildLocationWarning(locationService),
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
                        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                        right: 16,
                        child: MapControls(
                          onLocateMerapi: () => _mapController.move(volcanoPos, 11),
                          onLocateUser: () {
                            // Refresh lokasi sebelum pindah
                            locationService.refreshLocation();
                            _mapController.move(userPos, 13);
                          },
                        ),
                      ).animate().fadeIn().slideX(begin: 0.2),

                      // Layer: Floating Posko & Faskes Button (Left)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                        left: 16,
                        child: ShadcnMapButton(
                          icon: Icons.health_and_safety_rounded,
                          tooltip: 'Posko & Faskes',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.postDisaster),
                        ),
                      ).animate().fadeIn().slideX(begin: -0.2),

                      // Layer 4: Primary Info Card (Status & Distance)
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
  Widget _buildUserMarker(bool isRealGps) {
    final color = isRealGps ? const Color(0xFF2563EB) : Colors.grey.shade500;
    return Container(
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
        size: 20,
      ),
    );
  }

  /// Warning banner saat GPS error
  Widget _buildLocationWarning(LocationService locationService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.gps_off, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              locationService.locationError ?? 'Lokasi GPS tidak tersedia',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => locationService.refreshLocation(),
            child: Icon(Icons.refresh, size: 18, color: Colors.amber.shade800),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3);
  }
}
