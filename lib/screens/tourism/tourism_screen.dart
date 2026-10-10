import '../../services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/theme_extensions.dart';
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
        final destinationColumns = MediaQuery.sizeOf(context).width >= 700 ? 3 : 2;

        // Reload jika region berubah
        if (tourismProvider.currentRegion != region) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            tourismProvider.loadForRegion(region);
          });
        }

        return Scaffold(
          backgroundColor: context.bgPrimary,
          body: RefreshIndicator(
            color: context.accentPrimary,
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
                    title: context.tr('tourism_destination'),
                    subtitle: _destinationSubtitle(
                      tourismProvider.filteredDestinations.length,
                      tourismProvider.selectedCategory,
                    ),
                  ),
                ),

                // ── Destinasi Grid ────────────────────────────
                tourismProvider.isLoadingDestinations
                    ? SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: destinationColumns,
                            childAspectRatio: destinationColumns == 2 ? 0.68 : 0.76,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, __) => const _DestinationShimmer(),
                            childCount: 4,
                          ),
                        ),
                      )
                    : tourismProvider.filteredDestinations.isEmpty
                    ? SliverToBoxAdapter(child: _EmptyState())
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: destinationColumns,
                            childAspectRatio: destinationColumns == 2 ? 0.68 : 0.76,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
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
    final heroGradient = context.isHighContrast
        ? [context.bgPrimary, context.bgPrimary]
        : style.gradient;
    final heroForeground =
        context.isHighContrast ? context.accentSecondary : Colors.white;
    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: heroGradient.first,
      iconTheme: IconThemeData(color: heroForeground),
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
                  colors: heroGradient,
                ),
              ),
              child: Stack(
                children: [
                  // Pattern / Watermark
                  Positioned(
                    right: -40,
                    bottom: -20,
                    child: Icon(
                      Icons.terrain_rounded,
                      size: 240,
                      color: Colors.white.withAlpha(20),
                    ),
                  ),
                  Opacity(
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
                    color: context.isHighContrast
                        ? context.bgSurface
                        : Colors.white.withAlpha(30),
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
                                color: heroForeground,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isAutoDetected
                                    ? context.trText('Lokasi Anda')
                                    : context.trText('Daerah Pilihan'),
                                style: TextStyle(
                                  color: heroForeground,
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
                            style: TextStyle(
                              color: heroForeground,
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
                            color: heroForeground,
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
            ],
          ),
        ),
            centerTitle: false,
            title: Opacity(
              opacity: (1.0 - opacity).clamp(0.0, 1.0),
              child: Text(
                '${context.tr('tourism_section')} $region',
                style: TextStyle(
                  color: heroForeground,
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

  static const Map<String, IconData> _catIcons = {
    'Semua': Icons.apps_rounded,
    'Alam': Icons.forest_rounded,
    'Budaya': Icons.account_balance_rounded,
    'Pantai': Icons.beach_access_rounded,
    'Kuliner': Icons.restaurant_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.bgPrimary,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.trText('Kategori Pilihan'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children:
                  TourismProvider.categories.map((cat) {
                    final isSelected = selected == cat;
                    final icon = _catIcons[cat] ?? Icons.place_rounded;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: 80,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onChanged(cat),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.accentPrimary
                                    : context.bgSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? context.accentPrimary
                                      : context.borderColor,
                                  width: context.borderWidth,
                                ),
                                boxShadow: isSelected && !context.isHighContrast ? [
                                  BoxShadow(
                                    color: context.accentPrimary.withAlpha(50),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : [],
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    icon,
                                    color: isSelected && context.isHighContrast
                                        ? context.bgPrimary
                                        : isSelected ? Colors.white : context.textSecondary,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected && context.isHighContrast
                                          ? context.bgPrimary
                                          : isSelected ? Colors.white : context.textPrimary,
                                    ),
                                  ),
                                ],
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trText('Agenda Mendatang'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      context.trText('Pertunjukan, festival, & ritual budaya'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
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
    final color = context.isHighContrast
        ? context.accentSecondary
        : _typeColors[event.eventType] ?? SigumiTheme.primaryBlue;

    return Container(
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.borderColor,
              width: context.borderWidth,
            ),
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
                            color: context.isHighContrast
                                ? context.bgPrimary
                                : color.withAlpha(20),
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
                            color: context.isHighContrast
                                ? context.bgPrimary
                                : event.isRecurring
                                    ? context.adaptUiColor(SigumiTheme.statusNormal).withAlpha(20)
                                    : SigumiTheme.primaryBlue.withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.countdownLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: context.isHighContrast
                                  ? context.accentSecondary
                                  : event.isRecurring
                                      ? context.adaptUiColor(SigumiTheme.statusNormal)
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        height: 1.3,
                        letterSpacing: -0.1,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Lokasi
                    Row(
                      children: [
                    Icon(
                          Icons.place_rounded,
                          size: 12,
                          color: context.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary,
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
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: context.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              event.time!,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
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
                            color: event.price == 0 ? color : context.textSecondary,
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
        context.trText('Belum ada agenda mendatang'),
        style: TextStyle(
          fontSize: 13,
          color: context.textSecondary,
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
    final catColor = context.isHighContrast
        ? context.bgSurface
        : context.adaptUiColor(
            _categoryColors[destination.category] ?? SigumiTheme.primaryBlue,
          );
    final catIcon = _categoryIcons[destination.category] ?? Icons.place_rounded;
    final photoUrl = destination.photoUrl?.trim() ?? '';
    final hasPhoto = photoUrl.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.borderColor,
              width: context.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Foto / Placeholder ──
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
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
                        if (hasPhoto)
                          Positioned.fill(
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Icon(
                                  catIcon,
                                  size: 70,
                                  color: Colors.white.withAlpha(30),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(catIcon, size: 70, color: Colors.white.withAlpha(30)),
                          ),
                        // Rating Badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.isHighContrast
                                  ? context.bgPrimary
                                  : Colors.black.withAlpha(60),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: context.accentSecondary, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  destination.rating.toStringAsFixed(1),
                                  style: TextStyle(color: context.isHighContrast ? context.accentSecondary : Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
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
              // ── Info Bawah ──
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          height: 1.2,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 10, color: context.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              destination.openHours,
                              style: TextStyle(fontSize: 10, color: context.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                        Text(
                          destination.formattedFee,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: destination.entryFee == 0
                              ? context.successColor
                              : context.accentPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────
// SHIMMER LOADING
// ─────────────────────────────────────────────────────────────────

class _DestinationShimmer extends StatelessWidget {
  const _DestinationShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.bgSurface,
      highlightColor: context.borderColor,
      child: Container(
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(16),
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
          baseColor: context.bgSurface,
          highlightColor: context.borderColor,
          child: Container(
            width: 220,
            height: 168,
            decoration: BoxDecoration(
              color: context.bgSurface,
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
              color: context.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              context.trText('Belum ada destinasi'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.trText('Coba pilih kategori lain'),
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
