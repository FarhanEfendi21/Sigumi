import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../providers/news_provider.dart';
import '../../services/ai_service.dart';
import '../../services/localization_service.dart';
import '../../models/news_item.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shimmer/shimmer.dart';
import 'widgets/news_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final volcanoProvider = context.read<VolcanoProvider>();
      await volcanoProvider.autoDetectAndSetRegion();

      // Fetch news dari Supabase
      final newsProvider = context.read<NewsProvider>();
      await newsProvider.fetchLatestNews(limit: 5);

      if (!mounted) return;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final volcano = provider.volcano;
        final statusColor = SigumiTheme.getStatusColor(volcano.statusLevel);

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.forceRefresh();
              // Refresh berita juga
              final newsProvider = context.read<NewsProvider>();
              await newsProvider.refreshLatestNews(limit: 5);
            },
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFF0F4FF),
                            Color(0xFFE8EDFA),
                            Color(0xFFFFF8E8),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B2E7B).withAlpha(18),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/images/SIGUMI-logo.png',
                                      height: 36,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AiService.getPersonalizedGreeting(
                                        provider.currentUser,
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF5A6380),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  if (provider.isOffline)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.cloud_off,
                                            color: Colors.orange,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Offline',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  _buildRegionSelector(context, provider),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Status Card (Dynamic Hero Image)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth = constraints.maxWidth;
                              String formattedName =
                                  volcano.name
                                      .toLowerCase()
                                      .replaceAll('gunung ', '')
                                      .trim();
                              String imagePath =
                                  'assets/images/$formattedName.jpg';

                              return GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.visualMerapi,
                                  arguments: volcano,
                                ),
                                child: Container(
                                  width: cardWidth,
                                  // Tinggi dinamis: 42% lebar layar, min 180, max 240
                                  height: (cardWidth * 0.42).clamp(180.0, 240.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1B2E7B).withAlpha(40),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Stack(
                                      children: [
                                        // Background Image
                                        Positioned.fill(
                                          child: Image.asset(
                                            imagePath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, _) {
                                              return Container(
                                                color: SigumiTheme.primaryBlue,
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white54,
                                                    size: 40,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Gradient overlay
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withAlpha(15),
                                                  Colors.black.withAlpha(210),
                                                ],
                                                stops: const [0.25, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Content
                                         Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // ── Baris 1: Nama gunung (lebar penuh, tanpa gangguan) ──
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.landscape_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        volcano.name,
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'Plus Jakarta Sans',
                                                          fontSize: 19,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Colors.white,
                                                          letterSpacing: -0.5,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 5),

                                                // ── Baris 2: Elevasi · Status MAGMA (info sekunder) ──
                                                // FittedBox agar bisa menyusut jika layar terlalu sempit
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 28),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment: Alignment.centerLeft,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        // Elevasi
                                                        Text(
                                                          '${volcano.elevation.toInt()} mdpl',
                                                          style: TextStyle(
                                                            fontFamily: 'Plus Jakarta Sans',
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w700,
                                                            color: Colors.white.withAlpha(170),
                                                          ),
                                                        ),

                                                        // Pemisah
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                                          child: Text(
                                                            '·',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.white.withAlpha(110),
                                                              fontWeight: FontWeight.w300,
                                                            ),
                                                          ),
                                                        ),

                                                        // Badge Status MAGMA
                                                        if (provider.isLoadingVolcanoes)
                                                          Shimmer.fromColors(
                                                            baseColor: Colors.white24,
                                                            highlightColor: Colors.white38,
                                                            child: Container(
                                                              width: 64,
                                                              height: 18,
                                                              decoration: BoxDecoration(
                                                                color: Colors.white.withAlpha(40),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                            decoration: BoxDecoration(
                                                              color: statusColor.withAlpha(40),
                                                              border: Border.all(color: statusColor.withAlpha(100), width: 1),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                // Dot
                                                                Container(
                                                                  width: 7,
                                                                  height: 7,
                                                                  decoration: BoxDecoration(
                                                                    color: statusColor,
                                                                    shape: BoxShape.circle,
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: statusColor.withAlpha(200),
                                                                        blurRadius: 4,
                                                                        spreadRadius: 0,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 5),
                                                                // Label
                                                                Text(
                                                                  volcano.statusLabel,
                                                                  style: const TextStyle(
                                                                    fontFamily: 'Plus Jakarta Sans',
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w700,
                                                                    color: Colors.white,
                                                                  ),
                                                                  maxLines: 1,
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                        const SizedBox(width: 8),

                                                        // Waktu Pembaruan
                                                        if (!provider.isLoadingVolcanoes)
                                                          Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              Icon(
                                                                Icons.update_rounded,
                                                                size: 11,
                                                                color: Colors.white.withAlpha(160),
                                                              ),
                                                              const SizedBox(width: 3),
                                                              Text(
                                                                DateFormat('d MMM, HH:mm').format(volcano.lastUpdate),
                                                                style: TextStyle(
                                                                  fontFamily: 'Plus Jakarta Sans',
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Colors.white.withAlpha(160),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),

                                                const Spacer(),

                                                // ── Baris Bawah: Zone Indicator ──
                                                _buildZoneIndicatorCard(
                                                  context,
                                                  provider,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 500.ms).slideY(
                                begin: 0.1,
                                end: 0,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Tourism Promo Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: _TourismBannerCard(
                        region: provider.selectedRegion,
                      ),
                    ),

                    // Menu Grid
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        context.tr('main_menu'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.7,
                      children: [
                        _ShadMenuCard(
                          icon: Icons.alt_route_rounded,
                          label: context.tr('evacuation_point'),
                          color: Colors.green,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.evacuation,
                              ),
                        ),
                        _ShadMenuCard(
                          icon: Icons.videocam_rounded,
                          label: context.tr('cctv_monitoring'),
                          color: Colors.teal,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.visualMerapi,
                                arguments: volcano,
                              ),
                        ),
                        _ShadMenuCard(
                          icon: Icons.school_rounded,
                          label: context.tr('education'),
                          color: Colors.orange,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.education,
                              ),
                        ),
                        _ShadMenuCard(
                          icon: Icons.local_hospital_rounded,
                          label: context.tr('posko_faskes'),
                          color: Colors.indigo,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.postDisaster,
                              ),
                        ),
                        _ShadMenuCard(
                          icon: Icons.chat_rounded,
                          label: context.tr('ask_sigumi'),
                          color: Colors.purple,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.chatbot,
                              ),
                        ),
                        _ShadMenuCard(
                          icon: Icons.phone_in_talk_rounded,
                          label: context.tr('emergency_number'),
                          color: Colors.red,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.emergency,
                              ),
                        ),
                        _ShadMenuCard(
                          icon: Icons.accessibility_new_rounded,
                          label: context.tr('accessibility'),
                          color: Colors.brown,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                AppRoutes.accessibility,
                              ),
                        ),
                      ],
                    ),

                    // Berita Terkini Section (Disembunyikan sementara menunggu fitur Admin selesai)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Consumer<NewsProvider>(
                        builder: (context, newsProvider, _) {
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: SigumiTheme.primaryBlue.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.newspaper_rounded,
                                  color: SigumiTheme.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.tr('latest_news'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              if (newsProvider.isLoading)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      SigumiTheme.textSecondary,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  '${newsProvider.newsList.length} ${context.tr('latest_news').toLowerCase()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SigumiTheme.textSecondary,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    // News Carousel Slider
                    Consumer<NewsProvider>(
                      builder: (context, newsProvider, _) {
                        // Convert NewsModel to NewsItem
                        final newsItems =
                            newsProvider.newsList.map((news) {
                              return NewsItem(
                                id: news.id,
                                title: news.title,
                                summary: news.title,
                                content: news.content ?? '',
                                source: 'Sigumi',
                                publishedAt: news.createdAt ?? DateTime.now(),
                                category: NewsCategory.info,
                                imageUrl: news.imageUrl,
                              );
                            }).toList();

                        if (newsProvider.isLoading) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.tr('loading_news'),
                                    style: AppFonts.plusJakartaSans(
                                      color: SigumiTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (newsItems.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Text(
                                'Belum ada berita',
                                style: AppFonts.plusJakartaSans(
                                  color: SigumiTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        return NewsCarousel(newsItems: newsItems);
                      },
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────
  // ZONE INDICATOR — Opsi D: Stack vertikal dua baris
  // Baris 1 (atas)  : jarak — teks inline, tanpa container
  // Baris 2 (bawah) : status zona — pill badge berwarna
  // Satu warna per baris → hierarki jelas, tidak bertabrakan
  // ────────────────────────────────────────────────
  Widget _buildZoneIndicatorCard(
    BuildContext context,
    VolcanoProvider provider,
  ) {
    final volcanoLevel = provider.volcano.statusLevel;
    final zoneLevel   = provider.zoneLevel;
    final zoneColor   = SigumiTheme.getStatusColor(zoneLevel);
    final isHighAlert = volcanoLevel >= 3;

    final zoneIcon = isHighAlert
        ? Icons.warning_amber_rounded
        : Icons.shield_rounded;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.zoneDetail),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris 1: Jarak (teks inline, tanpa background) ──
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 11,
                color: Colors.white.withAlpha(170),
              ),
              const SizedBox(width: 4),
              Text(
                provider.distanceShort,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withAlpha(220),
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'dari puncak',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(150),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // ── Baris 2: Status Zona (pill badge — satu warna penuh) ──
          // FittedBox agar tidak overflow jika teks zona panjang
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: zoneColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withAlpha(isHighAlert ? 140 : 70),
                  width: isHighAlert ? 1.5 : 1.0,
                ),
                boxShadow: isHighAlert
                    ? [
                        BoxShadow(
                          color: zoneColor.withAlpha(180),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(zoneIcon, size: 12, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    provider.zoneLabel,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ────────────────────────────────────────────────
  // REGION SELECTOR — Header badge dengan deteksi GPS
  // ────────────────────────────────────────────────
  Widget _buildRegionSelector(BuildContext context, VolcanoProvider provider) {
    final isAutoDetected =
        provider.isRegionAutoDetected &&
        provider.detectedRegion == provider.selectedRegion;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRegionPicker(context, provider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2E7B).withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1B2E7B).withAlpha(20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAutoDetected
                    ? Icons.gps_fixed_rounded
                    : Icons.location_on_rounded,
                color:
                    isAutoDetected
                        ? Colors.green.shade600
                        : const Color(0xFF1B2E7B),
                size: 16,
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAutoDetected)
                    Text(
                      context.tr('your_location'),
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    provider.selectedRegion,
                    style: const TextStyle(
                      color: Color(0xFF1B2E7B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF1B2E7B),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // REGION PICKER — Bottom sheet dropdown
  // ────────────────────────────────────────────────
  void _showRegionPicker(BuildContext context, VolcanoProvider provider) {
    _showRegionPickerSheet(
      context: context,
      provider: provider,
      isDismissible: true,
    );
  }

  // (Mandatory picker has been removed in favor of auto-detect)

  void _showRegionPickerSheet({
    required BuildContext context,
    required VolcanoProvider provider,
    bool isDismissible = true,
    String? title,
    String? subtitle,
  }) {
    final detectedRegion = provider.detectedRegion;
    final regionData = <Map<String, dynamic>>[
      {
        'name': 'Yogyakarta',
        'volcano': 'Gunung Merapi',
        'elevation': '2.968 mdpl',
        'icon': Icons.landscape_rounded,
        'color': const Color(0xFFE65100),
      },
      {
        'name': 'Bali',
        'volcano': 'Gunung Agung',
        'elevation': '3.031 mdpl',
        'icon': Icons.terrain_rounded,
        'color': const Color(0xFFC62828),
      },
      {
        'name': 'Lombok',
        'volcano': 'Gunung Rinjani',
        'elevation': '3.726 mdpl',
        'icon': Icons.filter_hdr_rounded,
        'color': const Color(0xFF1565C0),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      builder: (ctx) {
        return PopScope(
          canPop: isDismissible,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SigumiTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SigumiTheme.primaryBlue.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: SigumiTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title ?? context.tr('select_region'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: SigumiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle ??
                                  context.tr('monitor_volcano'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: SigumiTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                // Region options
                ...regionData.map((region) {
                  final regionName = region['name'] as String;
                  final isSelected = provider.selectedRegion == regionName;
                  final isDetected = detectedRegion == regionName;
                  final color = region['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          provider.setRegion(regionName);
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? color.withAlpha(12)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? color.withAlpha(60)
                                      : SigumiTheme.divider.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(20),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  region['icon'] as IconData,
                                  color: color,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          regionName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                isSelected
                                                    ? color
                                                    : SigumiTheme.textPrimary,
                                          ),
                                        ),
                                        if (isDetected) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.green.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.gps_fixed_rounded,
                                                  size: 10,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  'Lokasi Anda',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${region['volcano']} \u2022 ${region['elevation']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: SigumiTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShadMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShadMenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color.withAlpha(15);
    final iconBgColor = color.withAlpha(30);
    final iconColor = color.withAlpha(220);

    return ShadCard(
      padding: EdgeInsets.zero,
      radius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withAlpha(30),
          highlightColor: color.withAlpha(15),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(40), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SigumiTheme.textPrimary.withAlpha(220),
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TOURISM BANNER CARD (FEATURED)
// ─────────────────────────────────────────────────────────────────

class _TourismBannerCard extends StatelessWidget {
  final String region;

  const _TourismBannerCard({required this.region});

  static const Map<String, Color> _regionColors = {
    'Yogyakarta': Color(0xFF1B2E7B),
    'Bali': Color(0xFF1A6B4A),
    'Lombok': Color(0xFF0D4F7C),
  };

  @override
  Widget build(BuildContext context) {
    // Default fallback to signature blue if region not strictly matched
    final bgColor = _regionColors[region] ?? const Color(0xFF1B2E7B);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, bgColor.withAlpha(200)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, AppRoutes.tourism),
          child: Stack(
            children: [
              // Decorative Background Icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.explore_rounded,
                  size: 140,
                  color: Colors.white.withAlpha(25),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title Typography Hierarchy
                      Text(
                        '${context.tr('explore_tourism')} $region',
                        style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Subtitle & Action Indicator (Hierarchical Spacing)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('find_destination'),
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
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
    );
  }
}
