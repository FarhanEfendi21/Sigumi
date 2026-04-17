import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/tourism_destination.dart';

/// Halaman detail destinasi wisata.
class TourismDetailScreen extends StatelessWidget {
  final TourismDestination destination;

  const TourismDetailScreen({super.key, required this.destination});

  static const Map<String, Color> _categoryColors = {
    'Alam': Color(0xFF2E7D32),
    'Budaya': Color(0xFF4A148C),
    'Pantai': Color(0xFF0277BD),
    'Kuliner': Color(0xFFE65100),
  };

  static const Map<String, IconData> _categoryIcons = {
    'Alam': Icons.forest_rounded,
    'Budaya': Icons.account_balance_rounded,
    'Pantai': Icons.beach_access_rounded,
    'Kuliner': Icons.restaurant_rounded,
  };

  Color get _catColor =>
      _categoryColors[destination.category] ?? SigumiTheme.primaryBlue;

  IconData get _catIcon =>
      _categoryIcons[destination.category] ?? Icons.place_rounded;

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(destination.name);
    final uri = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SigumiTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _catColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _catColor,
                      _catColor.withAlpha(200),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Icon dekoratif background
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(
                        _catIcon,
                        size: 220,
                        color: Colors.white.withAlpha(15),
                      ),
                    ),
                    // Konten hero
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Kategori badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withAlpha(50),
                                ),
                              ),
                              child: Text(
                                destination.category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Nama destinasi
                            Text(
                              destination.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Rating row
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  final full = i < destination.rating.floor();
                                  final half =
                                      !full &&
                                      i < destination.rating &&
                                      destination.rating - i >= 0.5;
                                  return Icon(
                                    full
                                        ? Icons.star_rounded
                                        : half
                                        ? Icons.star_half_rounded
                                        : Icons.star_outline_rounded,
                                    color: const Color(0xFFFFD623),
                                    size: 16,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '${destination.rating.toStringAsFixed(1)} / 5.0',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(220),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards: Jam + Harga
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.schedule_rounded,
                          label: 'Jam Buka',
                          value: destination.openHours,
                          color: SigumiTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Tiket Masuk',
                          value: destination.formattedFee,
                          color:
                              destination.entryFee == 0
                                  ? SigumiTheme.statusNormal
                                  : _catColor,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

                  const SizedBox(height: 24),

                  // Deskripsi
                  const Text(
                    'Tentang Tempat Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: SigumiTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    destination.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: SigumiTheme.textBody,
                      height: 1.65,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Alamat
                  _AddressRow(address: destination.address)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Tombol buka maps
                  _OpenMapsButton(
                    destination: destination,
                    catColor: _catColor,
                    onTap: _openMaps,
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ──────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SigumiTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SigumiTheme.divider.withAlpha(180)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: SigumiTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: SigumiTheme.textPrimary,
                    height: 1.3,
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

// ── Address Row ────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final String address;

  const _AddressRow({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SigumiTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SigumiTheme.divider.withAlpha(180)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SigumiTheme.primaryBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.place_rounded,
              color: SigumiTheme.primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat',
                  style: TextStyle(
                    fontSize: 10,
                    color: SigumiTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SigumiTheme.textBody,
                    height: 1.5,
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

// ── Open Maps Button ────────────────────────────────────────────────

class _OpenMapsButton extends StatelessWidget {
  final TourismDestination destination;
  final Color catColor;
  final VoidCallback onTap;

  const _OpenMapsButton({
    required this.destination,
    required this.catColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [catColor, catColor.withAlpha(200)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: catColor.withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Buka di Google Maps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
