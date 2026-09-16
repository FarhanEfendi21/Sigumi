import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../services/hiking_tracking_service.dart';
import '../../services/location_service.dart';

class HikingTrackingScreen extends StatelessWidget {
  const HikingTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HikingTrackingService(),
      child: const _HikingTrackingView(),
    );
  }
}

class _HikingTrackingView extends StatefulWidget {
  const _HikingTrackingView();

  @override
  State<_HikingTrackingView> createState() => _HikingTrackingViewState();
}

class _HikingTrackingViewState extends State<_HikingTrackingView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Consumer<HikingTrackingService>(
      builder: (context, tracking, _) {
        final location = tracking.locationService;
        final currentPoint = LatLng(location.userLat, location.userLng);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tracking Pendakian'),
            actions: [
              IconButton(
                tooltip: 'Pusatkan lokasi',
                onPressed: () => _mapController.move(currentPoint, 15),
                icon: const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _StatusBanner(tracking: tracking),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: currentPoint,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.sigumi.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentPoint,
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 42,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _StatsGrid(tracking: tracking),
                if (tracking.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    tracking.error!,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed:
                      tracking.isStarting || tracking.isStopping
                          ? null
                          : () =>
                              tracking.isActive
                                  ? _finishTracking(context, tracking)
                                  : _startTracking(context, tracking),
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
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: tracking.isActive ? Colors.red : null,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Lokasi hanya dikirim selama sesi aktif dan dapat dipantau oleh admin untuk keselamatan pendaki.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startTracking(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    final started = await tracking.start();
    if (!context.mounted || started) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tracking.error ?? 'Tracking belum dapat dimulai.'),
      ),
    );
  }

  Future<void> _finishTracking(
    BuildContext context,
    HikingTrackingService tracking,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selesaikan tracking?'),
            content: const Text(
              'Admin tidak akan menerima titik lokasi baru setelah sesi ditutup.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Selesaikan'),
              ),
            ],
          ),
    );
    if (confirmed == true) await tracking.stop();
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.tracking});

  final HikingTrackingService tracking;

  @override
  Widget build(BuildContext context) {
    final location = tracking.locationService;
    final isActive = tracking.isActive;
    final color = isActive ? Colors.green : Colors.blueGrey;
    final status =
        isActive
            ? 'Tracking aktif'
            : location.gpsStatus == GpsStatus.active
            ? 'GPS siap digunakan'
            : 'Tracking belum dimulai';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.gps_fixed : Icons.gps_not_fixed, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${location.userLat.toStringAsFixed(5)}, ${location.userLng.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isActive)
            const SizedBox(
              width: 12,
              height: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.tracking});

  final HikingTrackingService tracking;

  @override
  Widget build(BuildContext context) {
    final elapsed = tracking.elapsed;
    final duration =
        '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}';
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Durasi',
            value: duration,
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Jarak',
            value: '${tracking.distanceKm.toStringAsFixed(2)} km',
            icon: Icons.route_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Titik',
            value: '${tracking.pointsRecorded}',
            icon: Icons.pin_drop_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
