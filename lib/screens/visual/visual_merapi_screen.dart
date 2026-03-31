import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';

class VisualMerapiScreen extends StatelessWidget {
  const VisualMerapiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final volcano = context.read<VolcanoProvider>().volcano;

    return Scaffold(
      appBar: AppBar(title: const Text('Visual Gunung Merapi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live view placeholder
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade100,
                    Colors.green.shade100,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Mountain silhouette
                  CustomPaint(
                    size: const Size(double.infinity, 220),
                    painter: _MountainPainter(),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam, color: Colors.white.withOpacity(0.8), size: 48),
                        const SizedBox(height: 8),
                        Text(
                          'Live CCTV Gunung Merapi',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Sumber: BPPTKG',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 20),
            Text('Info Terkini', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Status info cards
            _InfoCard(
              icon: Icons.thermostat,
              title: 'Suhu Kawah',
              value: '${volcano.temperature ?? 28}°C',
              color: Colors.orange,
            ),
            _InfoCard(
              icon: Icons.air,
              title: 'Arah Angin',
              value: volcano.windDirection ?? 'N/A',
              color: Colors.blue,
            ),
            _InfoCard(
              icon: Icons.speed,
              title: 'Kecepatan Angin',
              value: '${volcano.windSpeed ?? 0} km/h',
              color: Colors.teal,
            ),

            const SizedBox(height: 20),
            Text('Riwayat Erupsi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            _TimelineItem(
              year: '2023',
              desc: 'Guguran lava pijar dan awan panas. Status Siaga (Level III).',
              isLatest: true,
            ),
            _TimelineItem(
              year: '2021',
              desc: 'Erupsi besar dengan awan panas guguran hingga 3 km. Evakuasi massal dilakukan.',
            ),
            _TimelineItem(
              year: '2018',
              desc: 'Erupsi freatik. Kolom abu setinggi 5.5 km di atas puncak.',
            ),
            _TimelineItem(
              year: '2010',
              desc: 'Erupsi dahsyat VEI 4. 353 korban jiwa. Evakuasi 400.000 warga.',
            ),
            _TimelineItem(
              year: '2006',
              desc: 'Erupsi menghasilkan awan panas dan lava. Evakuasi ribuan warga.',
              isLast: true,
            ),

            const SizedBox(height: 20),
            Text('Galeri Visual', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _GalleryItem('Puncak Merapi', Icons.landscape, Colors.brown),
                _GalleryItem('Kubah Lava', Icons.local_fire_department, Colors.red),
                _GalleryItem('Awan Panas', Icons.cloud, Colors.grey),
                _GalleryItem('Lahar Dingin', Icons.water, Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13)),
        trailing: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String year;
  final String desc;
  final bool isLatest;
  final bool isLast;

  const _TimelineItem({
    required this.year,
    required this.desc,
    this.isLatest = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isLatest ? SigumiTheme.statusAwas : SigumiTheme.divider,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLatest ? SigumiTheme.statusAwas : SigumiTheme.textSecondary,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: SigumiTheme.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  year,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isLatest ? SigumiTheme.statusAwas : SigumiTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GalleryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _GalleryItem(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.15, size.height * 0.6)
      ..lineTo(size.width * 0.3, size.height * 0.75)
      ..lineTo(size.width * 0.45, size.height * 0.25)
      ..lineTo(size.width * 0.55, size.height * 0.22)
      ..lineTo(size.width * 0.7, size.height * 0.65)
      ..lineTo(size.width * 0.85, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // Snow cap
    final snow = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final snowPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.32)
      ..lineTo(size.width * 0.45, size.height * 0.25)
      ..lineTo(size.width * 0.55, size.height * 0.22)
      ..lineTo(size.width * 0.58, size.height * 0.3)
      ..close();

    canvas.drawPath(snowPath, snow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
