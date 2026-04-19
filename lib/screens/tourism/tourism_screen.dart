import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/tourism_destination.dart';
import '../../models/tourism_event.dart';
import '../../providers/tourism_provider.dart';
import '../../providers/volcano_provider.dart';
import 'tourism_detail_screen.dart';

class TourismScreen extends StatefulWidget {
  const TourismScreen({super.key});

  @override
  State<TourismScreen> createState() => _TourismScreenState();
}

class _TourismScreenState extends State<TourismScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final region = context.read<VolcanoProvider>().selectedRegion;
      context.read<TourismProvider>().loadForRegion(region);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VolcanoProvider, TourismProvider>(
      builder: (context, volcanoProvider, tourismProvider, _) {
        final region = volcanoProvider.selectedRegion;

        // Reload jika region berubah
        if (tourismProvider.currentRegion != region) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            tourismProvider.loadForRegion(region);
          });
        }

        return Scaffold(
          backgroundColor: SigumiTheme.background,
          body: RefreshIndicator(
            color: SigumiTheme.primaryBlue,
            onRefresh: () async {
              await tourismProvider.loadForRegion(region);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── App Bar ──────────────────────────────────
                _SliverHeader(
                  region: region,
                  isAutoDetected: volcanoProvider.isRegionAutoDetected,
                ),

                // ── Filter Kategori ──────────────────────────
                SliverToBoxAdapter(
                  child: _CategoryFilter(
                    selected: tourismProvider.selectedCategory,
                    onChanged: tourismProvider.setCategory,
                  ).animate().fadeIn(duration: 400.ms).slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                ),

                // ── Section: Agenda Mendatang ─────────────────
                SliverToBoxAdapter(
                  child: _AgendaSection(
                    events: tourismProvider.upcomingEvents,
                    isLoading: tourismProvider.isLoadingEvents,
                  ),
                ),

                // ── Section Header: Destinasi ─────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Destinasi Wisata',
                    subtitle: _destinationSubtitle(
                      tourismProvider.filteredDestinations.length,
                      tourismProvider.selectedCategory,
                    ),
                  ),
                ),

                // ── Destinasi List ────────────────────────────
                tourismProvider.isLoadingDestinations
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, __) => const _DestinationShimmer(),
                          childCount: 4,
                        ),
                      )
                    : tourismProvider.filteredDestinations.isEmpty
                    ? SliverToBoxAdapter(child: _EmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final dest =
                                tourismProvider.filteredDestinations[index];
                            return _DestinationCard(
                              destination: dest,
                              index: index,
                              onTap:
                                  () => _openDetail(context, dest, region),
                            );
                          },
                          childCount:
                              tourismProvider.filteredDestinations.length,
                        ),
                      ),

                // ── Bottom Padding ────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _destinationSubtitle(int count, String category) {
    if (category == 'Semua') return '$count tempat ditemukan';
    return '$count tempat — $category';
  }

  void _openDetail(
    BuildContext context,
    TourismDestination destination,
    String region,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TourismDetailScreen(destination: destination),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SLIVER HEADER (RESPONSIVE FIX)
// ─────────────────────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final String region;
  final bool isAutoDetected;

  const _SliverHeader({required this.region, required this.isAutoDetected});

  static const Map<String, _RegionStyle> _styles = {
    'Yogyakarta': _RegionStyle(
      gradient: [Color(0xFF1B2E7B), Color(0xFF2D4499), Color(0xFF3A5BC7)],
      tagline: 'Kota Budaya & Warisan Dunia',
    ),
    'Bali': _RegionStyle(
      gradient: [Color(0xFF1A6B4A), Color(0xFF228B5E), Color(0xFF2EAD76)],
      tagline: 'Pulau Dewata yang Memesona',
    ),
    'Lombok': _RegionStyle(
      gradient: [Color(0xFF0D4F7C), Color(0xFF1565A0), Color(0xFF1E88C8)],
      tagline: 'Surga Tersembunyi Nusa Tenggara',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[region] ?? _styles['Yogyakarta']!;
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: style.gradient.first,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double appBarHeight = constraints.maxHeight;
          final double expandedHeight = 220 + topPadding;
          final double shrinkLimit = kToolbarHeight + topPadding;
          
          double opacity = (appBarHeight - shrinkLimit) / (expandedHeight - shrinkLimit);
          opacity = opacity.clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: style.gradient,
                ),
              ),
              child: Opacity(
                opacity: opacity,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAutoDetected
                                    ? Icons.my_location_rounded
                                    : Icons.place_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isAutoDetected ? 'Lokasi Anda' : 'Daerah Pilihan',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            region,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          style.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            centerTitle: false,
            title: Opacity(
              opacity: (1.0 - opacity).clamp(0.0, 1.0),
              child: Text(
                'Wisata $region',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
          );
        },
      ),
    );
  }
}

class _RegionStyle {
  final List<Color> gradient;
  final String tagline;

  const _RegionStyle({
    required this.gradient,
    required this.tagline,
  });
}

// ─────────────────────────────────────────────────────────────────
// FILTER KATEGORI
// ─────────────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SigumiTheme.background,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label section
          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SigumiTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children:
                  TourismProvider.categories.map((cat) {
                    final isSelected = selected == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onChanged(cat),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? SigumiTheme.primaryBlue
                                        : SigumiTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? SigumiTheme.primaryBlue
                                          : SigumiTheme.divider,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : SigumiTheme.textBody,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: SigumiTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: SigumiTheme.textSecondary,
                    fontWeight: FontWeight.w400,
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

// ─────────────────────────────────────────────────────────────────
// SECTION AGENDA MENDATANG
// ─────────────────────────────────────────────────────────────────

class _AgendaSection extends StatelessWidget {
  final List<TourismEvent> events;
  final bool isLoading;

  const _AgendaSection({required this.events, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agenda Mendatang',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: SigumiTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pertunjukan, festival, & ritual budaya',
                      style: TextStyle(
                        fontSize: 12,
                        color: SigumiTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable cards horizontal
        SizedBox(
          height: 168,
          child:
              isLoading
                  ? _AgendaShimmerRow()
                  : events.isEmpty
                  ? const _EmptyAgenda()
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        return _AgendaCard(
                          event: events[index],
                          index: index,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AGENDA CARD
// ─────────────────────────────────────────────────────────────────

class _AgendaCard extends StatelessWidget {
  final TourismEvent event;
  final int index;

  const _AgendaCard({required this.event, required this.index});

  // Warna per tipe event
  static const Map<String, Color> _typeColors = {
    'Festival': Color(0xFFE65100),
    'Pertunjukan': Color(0xFF4A148C),
    'Ritual': Color(0xFF1B5E20),
    'Pameran': Color(0xFF0D47A1),
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[event.eventType] ?? SigumiTheme.primaryBlue;

    return Container(
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: SigumiTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SigumiTheme.divider.withAlpha(180)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {}, // bisa dikembangkan ke detail event
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: Tag tipe + countdown
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.eventType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Countdown badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                event.isRecurring
                                    ? SigumiTheme.statusNormal.withAlpha(20)
                                    : SigumiTheme.primaryBlue.withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.countdownLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color:
                                  event.isRecurring
                                      ? SigumiTheme.statusNormal
                                      : SigumiTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Judul event
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SigumiTheme.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Lokasi
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 12,
                          color: SigumiTheme.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: SigumiTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Row: Waktu + Harga
                    Row(
                      children: [
                        if (event.time != null) ...[
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: SigumiTheme.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              event.time!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: SigumiTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          event.formattedPrice,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: event.price == 0 ? color : SigumiTheme.textBody,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Belum ada agenda mendatang',
        style: TextStyle(
          fontSize: 13,
          color: SigumiTheme.textSecondary.withAlpha(160),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DESTINATION CARD
// ─────────────────────────────────────────────────────────────────

class _DestinationCard extends StatelessWidget {
  final TourismDestination destination;
  final VoidCallback onTap;
  final int index;

  const _DestinationCard({
    required this.destination,
    required this.onTap,
    required this.index,
  });

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

  @override
  Widget build(BuildContext context) {
    final catColor =
        _categoryColors[destination.category] ?? SigumiTheme.primaryBlue;
    final catIcon = _categoryIcons[destination.category] ?? Icons.place_rounded;

    return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: SigumiTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: SigumiTheme.divider.withAlpha(180),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Foto / Placeholder ──
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              catColor.withAlpha(200),
                              catColor.withAlpha(140),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Icon dekoratif
                            Positioned(
                              right: -12,
                              bottom: -12,
                              child: Icon(
                                catIcon,
                                size: 100,
                                color: Colors.white.withAlpha(25),
                              ),
                            ),
                            // Label kategori
                            Positioned(
                              top: 12,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(60),
                                  ),
                                ),
                                child: Text(
                                  destination.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            // Rating badge
                            Positioned(
                              top: 12,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFD623),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      destination.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Nama di atas gradient
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 14,
                              child: Text(
                                destination.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Info Row ──
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Deskripsi singkat
                          Text(
                            destination.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: SigumiTheme.textBody,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Row: Jam + Tiket + Tombol Detail
                          Row(
                            children: [
                              // Jam buka
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: SigumiTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                destination.openHours,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: SigumiTheme.textSecondary,
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Harga tiket
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 13,
                                color:
                                    destination.entryFee == 0
                                        ? SigumiTheme.statusNormal
                                        : SigumiTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                destination.formattedFee,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      destination.entryFee == 0
                                          ? SigumiTheme.statusNormal
                                          : SigumiTheme.textSecondary,
                                ),
                              ),

                              const Spacer(),

                              // Tombol detail
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: SigumiTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Detail',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.06, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────
// SHIMMER LOADING
// ─────────────────────────────────────────────────────────────────

class _DestinationShimmer extends StatelessWidget {
  const _DestinationShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _AgendaShimmerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 220,
            height: 168,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.explore_off_rounded,
              size: 52,
              color: SigumiTheme.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada destinasi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: SigumiTheme.textSecondary.withAlpha(160),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coba pilih kategori lain',
              style: TextStyle(
                fontSize: 13,
                color: SigumiTheme.textSecondary.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
