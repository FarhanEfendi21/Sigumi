import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/volcano_provider.dart';

class VisualMerapiScreen extends StatelessWidget {
  const VisualMerapiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final volcano = context.read<VolcanoProvider>().volcano;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Live Visual',
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF1E1E2C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Live View Section ──
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Mock Camera View / Mountain Silhouette
                  CustomPaint(
                    size: const Size(double.infinity, 240),
                    painter: _MountainPainter(),
                  ),
                  
                  // Top Left: Live Badge
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                           .fade(duration: 800.ms, begin: 0.2, end: 1.0),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: AppFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Right: Actions (Refresh, Fullscreen)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        _buildGlassButton(Icons.refresh_rounded, () {
                          // TODO: Refresh action
                        }),
                        const SizedBox(width: 8),
                        _buildGlassButton(Icons.fullscreen_rounded, () {
                          // TODO: Fullscreen action
                        }),
                      ],
                    ),
                  ),

                  // Center: Info Overlay
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_rounded,
                          color: const Color(0xFF1E1E2C).withValues(alpha: 0.3),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CCTV ${volcano.name}',
                                style: AppFonts.plusJakartaSans(
                                  color: const Color(0xFF1E1E2C),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Sumber: BPPTKG',
                                style: AppFonts.plusJakartaSans(
                                  color: const Color(0xFF6B6B78),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
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
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 28),
            
            // ── Informasi Terkini ──
            Text(
              'Informasi Terkini',
              style: AppFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7, 
              children: [
                _buildInfoGridCard(
                  icon: Icons.thermostat_rounded,
                  title: 'Suhu Kawah',
                  value: '${volcano.temperature ?? '-'}°C',
                  color: Colors.orange,
                ),
                _buildInfoGridCard(
                  icon: Icons.air_rounded,
                  title: 'Arah Angin',
                  value: volcano.windDirection ?? '-',
                  color: Colors.blue,
                ),
                _buildInfoGridCard(
                  icon: Icons.speed_rounded,
                  title: 'Kecepatan',
                  value: '${volcano.windSpeed ?? '-'} km/h',
                  color: Colors.teal,
                ),
                _buildInfoGridCard(
                  icon: Icons.height_rounded,
                  title: 'Elevasi',
                  value: '${volcano.elevation} mdpl',
                  color: Colors.indigo,
                ),
              ],
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),

            // ── Riwayat Erupsi ──
            Text(
              'Riwayat Erupsi',
              style: AppFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  const _TimelineItem(
                    year: '2023',
                    desc: 'Guguran lava pijar dan awan panas. Status Siaga (Level III).',
                    isLatest: true,
                  ),
                  const _TimelineItem(
                    year: '2021',
                    desc: 'Erupsi besar dengan awan panas guguran hingga 3 km. Evakuasi massal dilakukan.',
                  ),
                  const _TimelineItem(
                    year: '2018',
                    desc: 'Erupsi freatik. Kolom abu setinggi 5.5 km di atas puncak.',
                  ),
                  const _TimelineItem(
                    year: '2010',
                    desc: 'Erupsi dahsyat VEI 4. 353 korban jiwa. Evakuasi 400.000 warga.',
                  ),
                  const _TimelineItem(
                    year: '2006',
                    desc: 'Erupsi menghasilkan awan panas dan lava. Evakuasi ribuan warga.',
                    isLast: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 32),

            // ── Galeri Visual ──
            Text(
              'Galeri Visual',
              style: AppFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2C),
              ),
            ),
            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _GalleryItem('Puncak Kawah', Icons.landscape_rounded, Colors.brown),
                _GalleryItem('Kubah Lava', Icons.local_fire_department_rounded, Colors.redAccent),
                _GalleryItem('Guguran Vulkanik', Icons.cloud_rounded, Colors.grey.shade700),
                _GalleryItem('Aliran Lahar', Icons.water_drop_rounded, Colors.blueAccent),
              ],
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF1E1E2C),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGridCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B6B78),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1E2C),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
              margin: const EdgeInsets.only(top: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isLatest ? Colors.white : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLatest ? Colors.redAccent : const Color(0xFFD1D5DB),
                  width: 3,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 56,
                color: const Color(0xFFF3F4F6),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  year,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isLatest ? Colors.redAccent : const Color(0xFF1E1E2C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF6B6B78),
                  ),
                ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Make it interactive
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: const Color(0xFF1E1E2C),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient for sky
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.lightBlue.shade50.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.2),
        ],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    final highlightPaint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
      
    final basePaint = Paint()
      ..color = Colors.grey.shade400.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Background Mountain 1
    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height)
      ..close();
    canvas.drawPath(path1, highlightPaint);

    // Main Volcano
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
    canvas.drawPath(path, basePaint);

    // Snow cap / Ash
    final snow = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final snowPath = Path()
      ..moveTo(size.width * 0.42, size.height * 0.32)
      ..lineTo(size.width * 0.45, size.height * 0.25)
      ..lineTo(size.width * 0.55, size.height * 0.22)
      ..lineTo(size.width * 0.58, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.35, size.width * 0.42, size.height * 0.32)
      ..close();
    canvas.drawPath(snowPath, snow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

