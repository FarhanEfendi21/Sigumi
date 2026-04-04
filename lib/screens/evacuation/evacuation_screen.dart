import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/evacuation_route.dart';
import '../../services/ai_service.dart';
import '../../providers/volcano_provider.dart';

class EvacuationScreen extends StatelessWidget {
  const EvacuationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = EvacuationRoute.mockRoutes();
    final volcano = context.read<VolcanoProvider>().volcano;
    final windRecommendation =
        AiService.getEvacuationRecommendation(volcano.windDirection);

    return Scaffold(
      appBar: AppBar(title: const Text('Jalur Evakuasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI wind recommendation
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SigumiTheme.primaryBlue.withOpacity(0.08),
                    Colors.purple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SigumiTheme.primaryBlue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SigumiTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.smart_toy,
                        color: SigumiTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rekomendasi AI',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: SigumiTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          windRecommendation,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 8),
            // Wind info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.air, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Arah angin: ${volcano.windDirection ?? "N/A"} • ${volcano.windSpeed ?? 0} km/h',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Jalur Evakuasi Tersedia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            ...routes.asMap().entries.map((entry) {
              final i = entry.key;
              final route = entry.value;
              return _RouteCard(route: route, index: i);
            }),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final EvacuationRoute route;
  final int index;

  const _RouteCard({required this.route, required this.index});

  Color _getCongestionColor(String level) {
    switch (level.toLowerCase()) {
      case 'rendah':
        return SigumiTheme.statusNormal;
      case 'sedang':
        return SigumiTheme.statusWaspada;
      case 'tinggi':
        return SigumiTheme.statusAwas;
      default:
        return SigumiTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (route.isRecommended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: SigumiTheme.statusNormal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        SizedBox(width: 2),
                        Text(
                          'AI Rekomendasikan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(
                    route.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              route.description,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(Icons.straighten, '${route.distance} km'),
                const SizedBox(width: 8),
                _InfoChip(Icons.timer, '${route.estimatedMinutes} mnt'),
                const SizedBox(width: 8),
                _InfoChip(
                  Icons.traffic,
                  route.congestionLevel,
                  color: _getCongestionColor(route.congestionLevel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Safety score bar
            Row(
              children: [
                const Text('Skor keamanan: ',
                    style: TextStyle(fontSize: 12)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: route.safetyScore,
                      backgroundColor: SigumiTheme.divider,
                      valueColor: AlwaysStoppedAnimation(
                        route.safetyScore > 0.8
                            ? SigumiTheme.statusNormal
                            : route.safetyScore > 0.6
                                ? SigumiTheme.statusWaspada
                                : SigumiTheme.statusAwas,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(route.safetyScore * 100).toInt()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Waypoints
            Wrap(
              spacing: 6,
              children: route.waypoints
                  .map((wp) => Chip(
                        label: Text(wp, style: const TextStyle(fontSize: 11)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        avatar: const Icon(Icons.place, size: 14),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: 400.ms,
        );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SigumiTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
