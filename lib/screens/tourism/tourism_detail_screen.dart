import '../../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/theme_extensions.dart';
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
    final heroColor = context.isHighContrast ? context.bgPrimary : _catColor;
    final heroForeground =
        context.isHighContrast ? context.accentSecondary : Colors.white;
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: heroColor,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: context.isHighContrast
                    ? context.bgSurface
                    : Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: heroForeground,
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
                    colors: context.isHighContrast
                        ? [context.bgPrimary, context.bgPrimary]
                        : [_catColor, _catColor.withAlpha(200)],
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
                                color: context.isHighContrast
                                    ? context.bgSurface
                                    : Colors.white.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.isHighContrast
                                      ? context.borderColor
                                      : Colors.white.withAlpha(50),
                                ),
                              ),
                              child: Text(
                                destination.category,
                                style: TextStyle(
                                  color: heroForeground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Nama destinasi
                            Text(
                              destination.name,
                              style: TextStyle(
                                color: heroForeground,
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
                                    color: context.accentSecondary,
                                    size: 16,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  '${destination.rating.toStringAsFixed(1)} / 5.0',
                                  style: TextStyle(
                                    color: heroForeground,
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
                          label: context.tr('opening_hours'),
                          value: destination.openHours,
                          color: context.accentPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.confirmation_number_outlined,
                          label: context.tr('entry_ticket'),
                          value: destination.formattedFee,
                          color: destination.entryFee == 0
                              ? context.successColor
                              : context.accentPrimary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

                  const SizedBox(height: 24),

                  // Deskripsi
                  Text(
                    context.trText('Tentang Tempat Ini'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    destination.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
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
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
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
              color: context.isHighContrast
                  ? context.bgPrimary
                  : color.withAlpha(18),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
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
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.isHighContrast
                  ? context.bgPrimary
                  : context.accentPrimary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.place_rounded,
              color: context.accentPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.trText('Alamat'),
                  style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textSecondary,
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
    final actionColor = context.accentPrimary;
    final actionForeground =
        context.isHighContrast ? context.bgPrimary : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.isHighContrast ? actionColor : null,
            gradient: context.isHighContrast ? null : LinearGradient(
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, color: actionForeground, size: 20),
              const SizedBox(width: 10),
              Text(
                context.trText('Buka di Google Maps'),
                style: TextStyle(
                  color: actionForeground,
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
