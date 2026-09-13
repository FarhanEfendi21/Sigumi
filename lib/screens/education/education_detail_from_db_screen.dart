import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import '../../config/theme.dart';
import '../../models/education_model.dart';

/// Halaman detail untuk konten edukasi yang berasal dari tabel `public.educations`.
///
/// Berbeda dari [EducationDetailScreen] (mock), screen ini menampilkan
/// [EducationItem.content] sebagai teks panjang scrollable.
class EducationDetailFromDbScreen extends StatelessWidget {
  final EducationItem item;

  const EducationDetailFromDbScreen({super.key, required this.item});

  // Warna aksen default berdasarkan kategori
  Color get _accentColor {
    switch (item.category?.toLowerCase()) {
      case 'mitigasi':
        return const Color(0xFF1565C0);
      case 'evakuasi':
        return const Color(0xFFE65100);
      case 'pertolongan':
        return const Color(0xFF2E7D32);
      case 'siaga':
        return const Color(0xFFAD1457);
      default:
        return SigumiTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: item.imageUrl != null ? 260 : 180,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar dari URL atau fallback gradient
                  if (item.imageUrl != null)
                    Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackHeader(color),
                    )
                  else
                    _buildFallbackHeader(color),

                  // Gradient overlay bawah ke putih
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white,
                        ],
                        stops: const [0.45, 0.78, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Judul & Meta Info ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip kategori & lokasi
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.category != null)
                        _MetaChip(
                          label: item.category!.toUpperCase(),
                          color: color,
                          icon: Icons.label_outline_rounded,
                        ),
                      if (item.lokasi != null)
                        _MetaChip(
                          label: item.lokasi!,
                          color: Colors.grey.shade600,
                          icon: Icons.location_on_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: Colors.black87,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

                  if (item.createdAt != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(item.createdAt!),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Konten Artikel ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
            sliver: SliverToBoxAdapter(
              child: Text(
                item.content,
                style: AppFonts.plusJakartaSans(
                  fontSize: 15.5,
                  height: 1.75,
                  color: Colors.black87.withValues(alpha: 0.85),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 500.ms),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackHeader(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 72,
          color: color.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MetaChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
