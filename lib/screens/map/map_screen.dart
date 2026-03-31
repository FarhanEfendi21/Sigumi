import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/volcano_provider.dart';
import '../../services/location_service.dart';
import '../../services/magma_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showLegend = true;
  late final MapController _mapController;

  List<VolcanoStatus> _volcanoes = [];
  bool _isLoading = true;
  bool _isOfflineData = false;
  bool _isLocating = false;
  VolcanoStatus? _selectedVolcano;
  VolcanoStatus? _focusedVolcano;

  static const _defaultCenter = LatLng(AppConstants.merapiLat, AppConstants.merapiLng);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadVolcanoData();
  }

  Future<void> _loadVolcanoData() async {
    setState(() => _isLoading = true);
    final data = await MagmaService.fetchAllVolcanoStatus();
    if (!mounted) return;
    final isOffline = data.isNotEmpty && (data.first.lastUpdate?.contains('offline') ?? false);
    final merapi = data.where((v) => v.name.toLowerCase().contains('merapi')).firstOrNull;
    setState(() {
      _volcanoes = data;
      _isLoading = false;
      _isOfflineData = isOffline;
      _focusedVolcano = merapi ?? (data.isNotEmpty ? data.first : null);
    });
  }

  Future<void> _updateLocation() async {
    setState(() => _isLocating = true);
    await LocationService.fetchUserLocation();
    if (!mounted) return;
    context.read<VolcanoProvider>().notifyListeners();
    _mapController.move(
      LatLng(LocationService.userLat, LocationService.userLng),
      13,
    );
    setState(() => _isLocating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final distance = provider.distanceFromMerapi;
        final zoneLevel = provider.zoneLevel;
        final zoneColor = SigumiTheme.getStatusColor(zoneLevel);
        final userPos = LatLng(LocationService.userLat, LocationService.userLng);
        final focusedPos = _focusedVolcano != null
            ? LatLng(_focusedVolcano!.latitude, _focusedVolcano!.longitude)
            : _defaultCenter;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Peta Risiko'),
            actions: [
              if (_isOfflineData)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.cloud_off, size: 18, color: Colors.white70),
                ),
              IconButton(
                icon: Icon(_showLegend ? Icons.layers : Icons.layers_outlined),
                onPressed: () => setState(() => _showLegend = !_showLegend),
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _loadVolcanoData,
              ),
            ],
          ),
          body: Stack(
            children: [

              // ── Peta ────────────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: focusedPos,
                  initialZoom: 10.5,
                  minZoom: 5,
                  maxZoom: 18,
                  onTap: (_, __) => setState(() => _selectedVolcano = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sigumi.app',
                    maxZoom: 19,
                  ),

                  // Lingkaran zona KRB
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: focusedPos, radius: 20000, useRadiusInMeter: true,
                        color: SigumiTheme.statusNormal.withAlpha(20),
                        borderColor: SigumiTheme.statusNormal.withAlpha(80), borderStrokeWidth: 1.5,
                      ),
                      CircleMarker(
                        point: focusedPos, radius: 15000, useRadiusInMeter: true,
                        color: SigumiTheme.statusWaspada.withAlpha(25),
                        borderColor: SigumiTheme.statusWaspada.withAlpha(100), borderStrokeWidth: 1.5,
                      ),
                      CircleMarker(
                        point: focusedPos, radius: 10000, useRadiusInMeter: true,
                        color: SigumiTheme.statusSiaga.withAlpha(30),
                        borderColor: SigumiTheme.statusSiaga.withAlpha(100), borderStrokeWidth: 2,
                      ),
                      CircleMarker(
                        point: focusedPos, radius: 5000, useRadiusInMeter: true,
                        color: SigumiTheme.statusAwas.withAlpha(40),
                        borderColor: SigumiTheme.statusAwas.withAlpha(120), borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                  // Marker gunung + user
                  MarkerLayer(
                    markers: [
                      ..._volcanoes.map((v) {
                        final isFocused = _focusedVolcano?.id == v.id;
                        final color = _statusColor(v.statusLevel);
                        return Marker(
                          point: LatLng(v.latitude, v.longitude),
                          width: isFocused ? 68 : 50,
                          height: isFocused ? 68 : 50,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVolcano = v;
                                _focusedVolcano = v;
                              });
                              _mapController.move(LatLng(v.latitude, v.longitude), 11);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(isFocused ? 7 : 5),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: isFocused ? 2.5 : 1.5),
                                    boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: isFocused ? 10 : 6)],
                                  ),
                                  child: Icon(Icons.landscape, color: Colors.white, size: isFocused ? 16 : 10),
                                ),
                                if (isFocused)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                                    child: Text(v.name,
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      // Marker lokasi user
                      Marker(
                        point: userPos,
                        width: 56,
                        height: 56,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: Colors.blue.withAlpha(100), blurRadius: 10, spreadRadius: 2)],
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                              child: const Text('Saya',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Loading indicator ──────────────────────────────────────────
              if (_isLoading)
                Positioned(
                  top: 60, left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: SigumiTheme.primaryBlue)),
                          SizedBox(width: 8),
                          Text('Memuat data MAGMA...', style: TextStyle(fontSize: 12, color: SigumiTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Kontrol kanan ──────────────────────────────────────────────
              Positioned(
                top: 12, right: 12,
                child: Column(
                  children: [
                    // Info angin
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.air, color: SigumiTheme.primaryBlue, size: 18),
                          const SizedBox(height: 2),
                          Text(provider.volcano.windDirection ?? 'N/A',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                          Text('${provider.volcano.windSpeed ?? 0} km/h',
                              style: const TextStyle(fontSize: 9, color: SigumiTheme.textSecondary)),
                        ],
                      ),
                    ).animate().fadeIn().slideX(begin: 0.3),
                    const SizedBox(height: 8),
                    _mapButton(
                      icon: Icons.landscape_rounded,
                      tooltip: 'Ke Gunung',
                      onTap: () => _mapController.move(focusedPos, 11),
                    ),
                    const SizedBox(height: 8),
                    _mapButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Lokasi Saya',
                      onTap: () => _mapController.move(userPos, 13),
                    ),
                  ],
                ),
              ),

              // ── Legenda kiri ───────────────────────────────────────────────
              if (_showLegend)
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Zona Bahaya', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(height: 6),
                        _legendItem(SigumiTheme.statusAwas, 'KRB III: 0–5 km'),
                        _legendItem(SigumiTheme.statusSiaga, 'KRB II: 5–10 km'),
                        _legendItem(SigumiTheme.statusWaspada, 'KRB I: 10–15 km'),
                        _legendItem(SigumiTheme.statusNormal, 'Aman: >15 km'),
                        const Divider(height: 10),
                        _legendItem(Colors.red.shade700, 'Puncak Gunung', isCircle: true),
                        _legendItem(Colors.blue, 'Lokasi Anda', isCircle: true),
                        if (_isOfflineData) ...[
                          const Divider(height: 8),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off, size: 10, color: SigumiTheme.textSecondary),
                              SizedBox(width: 4),
                              Text('Data offline', style: TextStyle(fontSize: 9, color: SigumiTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: -0.3),
                ),

              // ── Popup detail gunung ────────────────────────────────────────
              if (_selectedVolcano != null)
                Positioned(
                  bottom: 240, left: 16, right: 16,
                  child: _VolcanoPopup(
                    volcano: _selectedVolcano!,
                    onClose: () => setState(() => _selectedVolcano = null),
                  ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2),
                ),

              // ── Card bawah ─────────────────────────────────────────────────
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -3))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(color: SigumiTheme.divider, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(height: 14),

                      // Info jarak + zona
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                                color: zoneColor.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.my_location, color: zoneColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${distance.toStringAsFixed(1)} km dari Merapi',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: zoneColor),
                                ),
                                Text(
                                  LocationService.hasRealLocation
                                      ? provider.zoneLabel
                                      : '${provider.zoneLabel}  ·  lokasi estimasi',
                                  style: const TextStyle(fontSize: 11, color: SigumiTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: zoneColor, borderRadius: BorderRadius.circular(16)),
                            child: Text('Level ${provider.zoneLevel}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Progress bar radius
                      ..._buildRadiusBars(distance),

                      const SizedBox(height: 12),

                      // Tombol update GPS
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLocating ? null : _updateLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: SigumiTheme.primaryBlue),
                                )
                              : const Icon(Icons.gps_fixed, size: 16),
                          label: Text(_isLocating ? 'Mencari lokasi...' : 'Perbarui Lokasi GPS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SigumiTheme.primaryBlue,
                            side: const BorderSide(color: SigumiTheme.primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Sumber data
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isOfflineData ? Icons.cloud_off : Icons.cloud_done,
                            size: 11,
                            color: _isOfflineData ? SigumiTheme.textSecondary : SigumiTheme.statusNormal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isOfflineData
                                ? 'Data offline · ${_volcanoes.length} gunung'
                                : 'Sumber: MAGMA ESDM · ${_volcanoes.length} gunung aktif',
                            style: const TextStyle(fontSize: 10, color: SigumiTheme.textSecondary),
                          ),
                        ],
                      ),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(int level) {
    switch (level) {
      case 4: return SigumiTheme.statusAwas;
      case 3: return SigumiTheme.statusSiaga;
      case 2: return SigumiTheme.statusWaspada;
      default: return SigumiTheme.statusNormal;
    }
  }

  Widget _mapButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40, height: 40, alignment: Alignment.center,
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
            width: 12, height: 12,
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
              child: Text(label, style: TextStyle(
                  fontSize: 9,
                  fontWeight: isInZone ? FontWeight.w700 : FontWeight.w400,
                  color: isInZone ? color : SigumiTheme.textSecondary)),
            ),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                    color: isInZone ? color.withAlpha(50) : SigumiTheme.divider,
                    borderRadius: BorderRadius.circular(3)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (distance / km).clamp(0, 1),
                  child: Container(
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
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

// ── Popup detail gunung ────────────────────────────────────────────────────

class _VolcanoPopup extends StatelessWidget {
  final VolcanoStatus volcano;
  final VoidCallback onClose;
  const _VolcanoPopup({required this.volcano, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(volcano.statusLevel);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.landscape_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('G. ${volcano.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: SigumiTheme.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                  child: Text('Level ${volcano.statusLevel} – ${volcano.statusLabel}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                if (volcano.lastUpdate != null) ...[
                  const SizedBox(height: 4),
                  Text(volcano.lastUpdate!,
                      style: const TextStyle(fontSize: 10, color: SigumiTheme.textSecondary)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
            color: SigumiTheme.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  Color _statusColor(int level) {
    switch (level) {
      case 4: return SigumiTheme.statusAwas;
      case 3: return SigumiTheme.statusSiaga;
      case 2: return SigumiTheme.statusWaspada;
      default: return SigumiTheme.statusNormal;
    }
  }
}