import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/volcano_provider.dart';
import '../../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showLegend = true;
  late final MapController _mapController;

  static const _merapiPos = LatLng(
    AppConstants.merapiLat,
    AppConstants.merapiLng,
  );

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final distance = provider.distanceFromMerapi;
        final zoneLevel = provider.zoneLevel;
        final zoneColor = SigumiTheme.getStatusColor(zoneLevel);
        final userPos = LatLng(LocationService.userLat, LocationService.userLng);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Peta Risiko'),
            actions: [
              IconButton(
                icon: Icon(_showLegend ? Icons.layers : Icons.layers_outlined),
                onPressed: () => setState(() => _showLegend = !_showLegend),
                tooltip: 'Tampilkan Legenda',
              ),
            ],
          ),
          body: Stack(
            children: [
              // ── OpenStreetMap ──
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _merapiPos,
                  initialZoom: 10.5,
                  minZoom: 8,
                  maxZoom: 18,
                ),
                children: [
                  // OSM Tile Layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sigumi.app',
                    maxZoom: 19,
                  ),

                  // KRB Zone Circles
                  CircleLayer(
                    circles: [
                      // >15 km — safe zone
                      CircleMarker(
                        point: _merapiPos,
                        radius: _kmToPixelRadius(20),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusNormal.withAlpha(20),
                        borderColor: SigumiTheme.statusNormal.withAlpha(80),
                        borderStrokeWidth: 1.5,
                      ),
                      // 10-15 km — caution
                      CircleMarker(
                        point: _merapiPos,
                        radius: _kmToPixelRadius(15),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusWaspada.withAlpha(25),
                        borderColor: SigumiTheme.statusWaspada.withAlpha(100),
                        borderStrokeWidth: 1.5,
                      ),
                      // 5-10 km — warning
                      CircleMarker(
                        point: _merapiPos,
                        radius: _kmToPixelRadius(10),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusSiaga.withAlpha(30),
                        borderColor: SigumiTheme.statusSiaga.withAlpha(100),
                        borderStrokeWidth: 2,
                      ),
                      // 0-5 km — danger
                      CircleMarker(
                        point: _merapiPos,
                        radius: _kmToPixelRadius(5),
                        useRadiusInMeter: true,
                        color: SigumiTheme.statusAwas.withAlpha(40),
                        borderColor: SigumiTheme.statusAwas.withAlpha(120),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                  // Markers
                  MarkerLayer(
                    markers: [
                      // Merapi marker
                      Marker(
                        point: _merapiPos,
                        width: 60,
                        height: 60,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withAlpha(80),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.landscape,
                                  color: Colors.white, size: 18),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Merapi',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // User marker
                      Marker(
                        point: userPos,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withAlpha(80),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Map Controls (top right) ──
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    // Wind info
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.air,
                              color: SigumiTheme.primaryBlue, size: 18),
                          const SizedBox(height: 2),
                          Text(
                            provider.volcano.windDirection ?? 'N/A',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${provider.volcano.windSpeed ?? 0} km/h',
                            style: const TextStyle(
                                fontSize: 9,
                                color: SigumiTheme.textSecondary),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideX(begin: 0.3),
                    const SizedBox(height: 8),
                    // Center on Merapi
                    _mapButton(
                      icon: Icons.landscape_rounded,
                      tooltip: 'Ke Merapi',
                      onTap: () => _mapController.move(_merapiPos, 11),
                    ),
                    const SizedBox(height: 8),
                    // Center on user
                    _mapButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Lokasi Saya',
                      onTap: () => _mapController.move(userPos, 13),
                    ),
                  ],
                ),
              ),

              // ── Legend (top left) ──
              if (_showLegend)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Zona Bahaya',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        _legendItem(
                            SigumiTheme.statusAwas, 'KRB III: 0–5 km'),
                        _legendItem(
                            SigumiTheme.statusSiaga, 'KRB II: 5–10 km'),
                        _legendItem(
                            SigumiTheme.statusWaspada, 'KRB I: 10–15 km'),
                        _legendItem(
                            SigumiTheme.statusNormal, 'Aman: >15 km'),
                        const Divider(height: 10),
                        _legendItem(Colors.red.shade700, 'Puncak Merapi',
                            isCircle: true),
                        _legendItem(Colors.blue, 'Lokasi Anda',
                            isCircle: true),
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: -0.3),
                ),

              // ── Bottom Info Card ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: SigumiTheme.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: zoneColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.my_location,
                                color: zoneColor, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${distance.toStringAsFixed(1)} km dari Puncak Merapi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: zoneColor,
                                  ),
                                ),
                                Text(
                                  provider.zoneLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: SigumiTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: zoneColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Level ${provider.zoneLevel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Zone bars
                      ..._buildRadiusBars(distance),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  double _kmToPixelRadius(double km) => km * 1000;

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: SigumiTheme.primaryBlue),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, {bool isCircle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCircle ? color : color.withAlpha(60),
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              border: isCircle ? null : Border.all(color: color, width: 1.5),
              borderRadius: isCircle ? null : BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  List<Widget> _buildRadiusBars(double distance) {
    final zones = [
      {'km': 5.0, 'label': '5 km', 'color': SigumiTheme.statusAwas},
      {'km': 10.0, 'label': '10 km', 'color': SigumiTheme.statusSiaga},
      {'km': 15.0, 'label': '15 km', 'color': SigumiTheme.statusWaspada},
      {'km': 20.0, 'label': '20 km', 'color': SigumiTheme.statusNormal},
    ];

    return zones.map((zone) {
      final km = zone['km'] as double;
      final label = zone['label'] as String;
      final color = zone['color'] as Color;
      final isInZone = distance <= km;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isInZone ? FontWeight.w700 : FontWeight.w400,
                  color: isInZone ? color : SigumiTheme.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: isInZone ? color.withAlpha(50) : SigumiTheme.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (distance / km).clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            if (isInZone)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.arrow_left, size: 14, color: color),
              ),
          ],
        ),
      );
    }).toList();
  }
}
