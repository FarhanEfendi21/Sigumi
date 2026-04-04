import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class MagmaScreen extends StatefulWidget {
  const MagmaScreen({super.key});

  @override
  State<MagmaScreen> createState() => _MagmaScreenState();
}

class _MagmaScreenState extends State<MagmaScreen> {
  static const String _magmaUrl = 'https://magma.esdm.go.id/v1';
  bool _isAboutExpanded = false;
  bool _isFeaturesExpanded = false;

  Future<void> _launchMagma() async {
    final uri = Uri.parse(_magmaUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFFB71C1C),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFD32F2F),
                      Color(0xFFB71C1C),
                      Color(0xFF880E4F),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      // MAGMA icon
                      Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.volcano_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 12),
                      const Text(
                        'MAGMA Indonesia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 4),
                      Text(
                        'Multiplatform Application for\nGeohazard Mitigation and Assessment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Tentang MAGMA (Dropdown) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SigumiTheme.divider.withAlpha(100),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Dropdown header
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isAboutExpanded = !_isAboutExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFB71C1C,
                                      ).withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFFB71C1C),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tentang MAGMA',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: SigumiTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Ketuk untuk melihat informasi MAGMA',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: SigumiTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _isAboutExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFB71C1C,
                                        ).withAlpha(15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFFB71C1C),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Expandable content
                        AnimatedCrossFade(
                          firstChild: const SizedBox(width: double.infinity),
                          secondChild: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              children: [
                                Divider(
                                  color: SigumiTheme.divider.withAlpha(80),
                                  height: 1,
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'MAGMA Indonesia adalah platform resmi milik Kementerian ESDM '
                                  'yang menyediakan informasi real-time tentang aktivitas gunung api, '
                                  'gempa bumi, dan gerakan tanah di seluruh Indonesia. Platform ini '
                                  'menjadi sumber data utama untuk pemantauan dan mitigasi bencana geologi.',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: SigumiTheme.textBody,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          crossFadeState:
                              _isAboutExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 350),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 20),

                // ── Fitur Utama (Dropdown) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SigumiTheme.divider.withAlpha(100),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Dropdown header (tappable)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isFeaturesExpanded = !_isFeaturesExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFB71C1C,
                                      ).withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.grid_view_rounded,
                                      color: Color(0xFFB71C1C),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fitur Utama',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: SigumiTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Ketuk untuk melihat fitur-fitur MAGMA',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: SigumiTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _isFeaturesExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFB71C1C,
                                        ).withAlpha(15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFFB71C1C),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Expandable feature cards
                        AnimatedCrossFade(
                          firstChild: const SizedBox(width: double.infinity),
                          secondChild: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                Divider(
                                  color: SigumiTheme.divider.withAlpha(80),
                                  height: 1,
                                ),
                                const SizedBox(height: 14),
                                const _FeatureCard(
                                  icon: Icons.volcano_rounded,
                                  title: 'Monitoring Gunung Api',
                                  description:
                                      'Pantau aktivitas 127 gunung api di Indonesia secara real-time dengan data terkini.',
                                  color: Color(0xFFD32F2F),
                                ),
                                const SizedBox(height: 10),
                                const _FeatureCard(
                                  icon: Icons.assignment_rounded,
                                  title: 'Laporan Aktivitas',
                                  description:
                                      'Akses laporan harian dan mingguan aktivitas vulkanik dari pos pengamatan resmi.',
                                  color: Color(0xFFE65100),
                                ),
                                const SizedBox(height: 10),
                                const _FeatureCard(
                                  icon: Icons.show_chart_rounded,
                                  title: 'Data Seismik',
                                  description:
                                      'Visualisasi data seismik dan grafik kegempaan dari stasiun pemantauan.',
                                  color: Color(0xFF2E7D32),
                                ),
                                const SizedBox(height: 10),
                                const _FeatureCard(
                                  icon: Icons.satellite_alt_rounded,
                                  title: 'Citra Satelit',
                                  description:
                                      'Pantau perubahan morfologi gunung api melalui citra satelit terkini.',
                                  color: Color(0xFF1565C0),
                                ),
                                const SizedBox(height: 10),
                                const _FeatureCard(
                                  icon: Icons.warning_amber_rounded,
                                  title: 'Peringatan Dini',
                                  description:
                                      'Dapatkan notifikasi peringatan dini terkait peningkatan status aktivitas vulkanik.',
                                  color: Color(0xFFF57F17),
                                ),
                              ],
                            ),
                          ),
                          crossFadeState:
                              _isFeaturesExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 350),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── CTA Button ──
                Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _launchMagma,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB71C1C).withAlpha(60),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Buka MAGMA Indonesia',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                // URL hint
                Center(
                  child: Text(
                    _magmaUrl,
                    style: TextStyle(
                      fontSize: 11,
                      color: SigumiTheme.textSecondary.withAlpha(160),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Info banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFFE65100),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Website MAGMA Indonesia akan terbuka di browser Anda. '
                            'Pastikan Anda terhubung ke internet.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4E342E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for each MAGMA feature
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SigumiTheme.divider.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SigumiTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: SigumiTheme.textBody,
                    height: 1.45,
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
