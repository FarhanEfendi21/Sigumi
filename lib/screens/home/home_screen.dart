import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../config/theme_extensions.dart';
import '../../providers/volcano_provider.dart';
import '../../providers/news_provider.dart';
import '../../services/ai_service.dart';
import '../../services/localization_service.dart';
import '../../models/news_item.dart';
import 'widgets/news_carousel.dart';
import 'package:flutter/services.dart';

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
      if (!mounted) return;

      final volcanoProvider = context.read<VolcanoProvider>();
      await volcanoProvider.autoDetectAndSetRegion();

      if (!mounted) return;

      // Fetch news dari Supabase, filtered by selected region
      final newsProvider = context.read<NewsProvider>();
      await newsProvider.fetchLatestNews(
        limit: 5,
        lokasi: volcanoProvider.selectedRegion,
      );

      // Listen to selectedRegion changes and auto-fetch news
      volcanoProvider.addListener(() {
        if (!mounted) return;
        final newsProvider = context.read<NewsProvider>();
        newsProvider.fetchLatestNews(
          limit: 5,
          lokasi: volcanoProvider.selectedRegion,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;

    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final volcano = provider.volcano;
        final cbMode = provider.colorBlindMode;
        final statusColor = SigumiTheme.getStatusColor(
          volcano.statusLevel,
          highContrast: isHighContrast,
          colorBlindMode: cbMode,
        );

        return Scaffold(
          backgroundColor: context.bgSecondary,
          body: RefreshIndicator(
            onRefresh: () async {
              // Get provider before async gap
              final newsProvider = Provider.of<NewsProvider>(
                context,
                listen: false,
              );

              await provider.forceRefresh();

              if (!mounted) return;

              // Refresh berita juga, filtered by selected region
              await newsProvider.refreshLatestNews(
                limit: 5,
                lokasi: provider.selectedRegion,
              );
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
                        gradient:
                            isHighContrast
                                ? null
                                : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFF0F4FF),
                                    Color(0xFFE8EDFA),
                                    Color(0xFFFFF8E8),
                                  ],
                                  stops: [0.0, 0.55, 1.0],
                                ),
                        color: isHighContrast ? context.bgSurface : null,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        border:
                            isHighContrast
                                ? Border.all(
                                  color: context.borderColor,
                                  width: context.borderWidth,
                                )
                                : null,
                        boxShadow: context.cardShadow,
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
                                      style: TextStyle(
                                        color: context.textTertiary,
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
                                        color: context.warningColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: context.warningColor
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.cloud_off,
                                            color: context.warningColor,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Offline',
                                            style: TextStyle(
                                              color: context.warningColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
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
                                // onTap: () => Navigator.pushNamed(
                                //   context,
                                //   AppRoutes.visualMerapi,
                                //   arguments: volcano,
                                // ),
                                child: Container(
                                  width: cardWidth,
                                  // Tinggi dinamis: 42% lebar layar, min 180, max 240
                                  height: (cardWidth * 0.42).clamp(
                                    180.0,
                                    240.0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF1B2E7B,
                                        ).withAlpha(40),
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
                                              gradient:
                                                  isHighContrast
                                                      ? null
                                                      : LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end:
                                                            Alignment
                                                                .bottomCenter,
                                                        colors: [
                                                          Colors.black
                                                              .withAlpha(15),
                                                          Colors.black
                                                              .withAlpha(210),
                                                        ],
                                                        stops: const [
                                                          0.25,
                                                          1.0,
                                                        ],
                                                      ),
                                              color:
                                                  isHighContrast
                                                      ? context.overlayDark(0.7)
                                                      : null,
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 28,
                                                      ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        // Elevasi
                                                        Text(
                                                          '${volcano.elevation.toInt()} mdpl',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Plus Jakarta Sans',
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white
                                                                .withAlpha(170),
                                                          ),
                                                        ),

                                                        // Pemisah
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                          child: Text(
                                                            '·',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .white
                                                                  .withAlpha(
                                                                    110,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
                                                            ),
                                                          ),
                                                        ),

                                                        // Badge Status MAGMA
                                                        if (provider
                                                            .isLoadingVolcanoes)
                                                          Shimmer.fromColors(
                                                            baseColor:
                                                                Colors.white24,
                                                            highlightColor:
                                                                Colors.white38,
                                                            child: Container(
                                                              width: 64,
                                                              height: 18,
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withAlpha(
                                                                      40,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 3,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: statusColor
                                                                  .withAlpha(
                                                                    40,
                                                                  ),
                                                              border: Border.all(
                                                                color: statusColor
                                                                    .withAlpha(
                                                                      100,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                // Dot
                                                                Container(
                                                                  width: 7,
                                                                  height: 7,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        statusColor,
                                                                    shape:
                                                                        BoxShape
                                                                            .circle,
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: statusColor
                                                                            .withAlpha(
                                                                              200,
                                                                            ),
                                                                        blurRadius:
                                                                            4,
                                                                        spreadRadius:
                                                                            0,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 5,
                                                                ),
                                                                // Label
                                                                Text(
                                                                  volcano
                                                                      .statusLabel,
                                                                  style: const TextStyle(
                                                                    fontFamily:
                                                                        'Plus Jakarta Sans',
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                  maxLines: 1,
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                        const SizedBox(
                                                          width: 8,
                                                        ),

                                                        // Waktu Pembaruan
                                                        if (!provider
                                                            .isLoadingVolcanoes)
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .update_rounded,
                                                                size: 11,
                                                                color: Colors
                                                                    .white
                                                                    .withAlpha(
                                                                      160,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 3,
                                                              ),
                                                              Text(
                                                                DateFormat(
                                                                  'd MMM, HH:mm',
                                                                ).format(
                                                                  volcano
                                                                      .lastUpdate,
                                                                ),
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Plus Jakarta Sans',
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .white
                                                                      .withAlpha(
                                                                        160,
                                                                      ),
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
                              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Guest Login Prompt Banner
                    if (provider.isGuest)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: _GuestLoginBanner(),
                      ),

                    // Tourism Promo Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: _TourismBannerCard(
                        region: provider.selectedRegion,
                      ),
                    ),

                    // Menu Grid — Opsi B: Featured + Small + FullWidth
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        context.tr('main_menu'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // Row 1: 2 featured cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _FeaturedMenuCard(
                                icon: Icons.alt_route_rounded,
                                label: context.tr('evacuation_point'),
                                subtitle: 'Titik & jalur evakuasi terdekat',
                                color: Colors.green,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.evacuation),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeaturedMenuCard(
                                icon: Icons.videocam_rounded,
                                label: context.tr('cctv_monitoring'),
                                subtitle: 'Pantau kondisi gunung live',
                                color: Colors.teal,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.visualMerapi,
                                  arguments: volcano,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Row 2: 4 small cards (ukuran asli, desain baru)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _ShadMenuCard(
                              icon: Icons.school_rounded,
                              label: context.tr('education'),
                              subtitle: context.tr('education_sub'),
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.education),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _ShadMenuCard(
                              icon: Icons.local_hospital_rounded,
                              label: context.tr('posko_faskes'),
                              subtitle: context.tr('posko_faskes_sub'),
                              color: Colors.indigo,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.postDisaster),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _ShadMenuCard(
                              icon: Icons.chat_rounded,
                              label: context.tr('ask_sigumi'),
                              subtitle: context.tr('ask_sigumi_sub'),
                              color: Colors.purple,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.chatbot),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: _ShadMenuCard(
                              icon: Icons.phone_in_talk_rounded,
                              label: context.tr('emergency_number'),
                              subtitle: context.tr('emergency_number_sub'),
                              color: Colors.red,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.emergency),
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Row 3: Full-width accessibility card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _FullWidthMenuCard(
                        icon: Icons.accessibility_new_rounded,
                        label: context.tr('accessibility'),
                        subtitle: 'Mode kontras tinggi & buta warna',
                        color: Colors.brown,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.accessibility),
                      ),
                    ),

                    // Berita Terkini Section (Disembunyikan sementara menunggu fitur Admin selesai)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Consumer<NewsProvider>(
                        builder: (context, newsProvider, _) {
                          return Row(
                            children: [
                              Text(
                                context.tr('latest_news'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
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
    final zoneLevel = provider.zoneLevel;
    final isHC = provider.highContrast;
    final cbMode = provider.colorBlindMode;
    final zoneColor = SigumiTheme.getStatusColor(zoneLevel, highContrast: isHC, colorBlindMode: cbMode);
    final isHighAlert = volcanoLevel >= 3;

    final zoneIcon =
        isHighAlert ? Icons.warning_amber_rounded : Icons.shield_rounded;

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: zoneColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withAlpha(isHighAlert ? 140 : 70),
                  width: isHighAlert ? 1.5 : 1.0,
                ),
                boxShadow:
                    isHighAlert
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
            color: context.accentPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.borderColor,
              width: context.borderWidth,
            ),
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
                        ? context.successColor
                        : context.accentPrimary,
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
                        color: context.successColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    provider.selectedRegion,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: context.textPrimary,
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
            decoration: BoxDecoration(
              color: context.bgPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border.all(
                color: context.borderColor,
                width: context.borderWidth,
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
                              subtitle ?? context.tr('monitor_volcano'),
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
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShadMenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final darkColor = Color.lerp(color, Colors.black, 0.28)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isHighContrast
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, darkColor],
                  ),
            color: isHighContrast ? context.bgSurface : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighContrast ? context.borderColor : color.withAlpha(80),
              width: context.borderWidth,
            ),
            boxShadow: isHighContrast
                ? []
                : [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(icon, size: 54, color: Colors.white.withAlpha(20)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(isHighContrast ? 30 : 45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: isHighContrast ? context.textPrimary : Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isHighContrast ? context.textPrimary : Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: isHighContrast
                                  ? context.textSecondary
                                  : Colors.white.withAlpha(170),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 10,
                          color: isHighContrast
                              ? context.textSecondary
                              : Colors.white.withAlpha(170),
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

// ─────────────────────────────────────────────────────────────────
// FEATURED MENU CARD — Opsi B (2 card besar atas)
// ─────────────────────────────────────────────────────────────────
class _FeaturedMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeaturedMenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final darkColor = Color.lerp(color, Colors.black, 0.28)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isHighContrast
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, darkColor],
                  ),
            color: isHighContrast ? context.bgSurface : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHighContrast ? context.borderColor : color.withAlpha(80),
              width: context.borderWidth,
            ),
            boxShadow: isHighContrast
                ? []
                : [
                    BoxShadow(
                      color: color.withAlpha(90),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(icon, size: 100, color: Colors.white.withAlpha(20)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(isHighContrast ? 30 : 45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isHighContrast ? context.textPrimary : Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isHighContrast ? context.textPrimary : Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isHighContrast
                                  ? context.textSecondary
                                  : Colors.white.withAlpha(180),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: isHighContrast
                              ? context.textSecondary
                              : Colors.white.withAlpha(180),
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

// ─────────────────────────────────────────────────────────────────
// FULL WIDTH MENU CARD — Opsi B (card aksesibilitas full-width)
// ─────────────────────────────────────────────────────────────────
class _FullWidthMenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FullWidthMenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final darkColor = Color.lerp(color, Colors.black, 0.28)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isHighContrast
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, darkColor],
                  ),
            color: isHighContrast ? context.bgSurface : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighContrast ? context.borderColor : color.withAlpha(80),
              width: context.borderWidth,
            ),
            boxShadow: isHighContrast
                ? []
                : [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -16,
                top: -16,
                child: Icon(icon, size: 90, color: Colors.white.withAlpha(20)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(isHighContrast ? 30 : 45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: isHighContrast ? context.textPrimary : Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isHighContrast ? context.textPrimary : Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isHighContrast
                                  ? context.textSecondary
                                  : Colors.white.withAlpha(180),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isHighContrast
                          ? context.textTertiary
                          : Colors.white.withAlpha(200),
                      size: 18,
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

// ─────────────────────────────────────────────────────────────────
// GUEST LOGIN BANNER — Clean Minimal Card (2025)
// ─────────────────────────────────────────────────────────────────

class _GuestLoginBanner extends StatefulWidget {
  const _GuestLoginBanner();

  @override
  State<_GuestLoginBanner> createState() => _GuestLoginBannerState();
}

class _GuestLoginBannerState extends State<_GuestLoginBanner> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isHighContrast ? context.accentPrimary : SigumiTheme.primaryBlue;
    final accentEnd = isHighContrast ? context.accentPrimary : const Color(0xFF1A3080);

    final bgColor = isHighContrast
        ? context.bgSurface
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF));

    final borderColor = isHighContrast
        ? context.borderColor
        : accent.withValues(alpha: isDark ? 0.25 : 0.18);

    final textPrimary = isHighContrast
        ? context.textPrimary
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A));

    final textSecondary = isHighContrast
        ? context.textSecondary
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, AppRoutes.login);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isHighContrast
                ? []
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.08 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon block
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isHighContrast
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, accentEnd],
                        ),
                  color: isHighContrast ? context.accentPrimary : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isHighContrast
                      ? []
                      : [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masuk ke Akun',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Akses laporan, AI, dan fitur lengkap',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // CTA chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: isHighContrast
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, accentEnd],
                        ),
                  color: isHighContrast ? context.accentPrimary : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isHighContrast
                      ? []
                      : [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Text(
                  'Masuk',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────
// TOURISM BANNER CARD (FEATURED)
// ─────────────────────────────────────────────────────────────────

class _TourismBannerCard extends StatelessWidget {
  final String region;

  const _TourismBannerCard({required this.region});

  static const Map<String, String> _regionImages = {
    'Yogyakarta':
        'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?auto=format&fit=crop&q=80&w=1000', // Merapi/Mountain style
    'Bali':
        'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&q=80&w=1000', // Bali temple style
    'Lombok':
        'https://images.unsplash.com/photo-1583022846753-83a4eba54ac1?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D', // Custom Lombok Image
  };

  @override
  Widget build(BuildContext context) {
    final isHighContrast = context.isHighContrast;
    // Default fallback to signature image if region not strictly matched
    final imageUrl = _regionImages[region] ??
        'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?auto=format&fit=crop&q=80&w=1000';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: isHighContrast ? context.accentPrimary : const Color(0xFF1B2E7B),
        image:
            isHighContrast
                ? null
                : DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  colorFilter: const ColorFilter.mode(
                    Colors.black54, // Dark overlay for readability
                    BlendMode.darken,
                  ),
                ),
        borderRadius: BorderRadius.circular(16),
        border:
            isHighContrast
                ? Border.all(
                  color: context.borderColor,
                  width: context.borderWidth,
                )
                : null,
        boxShadow:
            isHighContrast
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, AppRoutes.tourism);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title Typography Hierarchy
                Text(
                  '${context.tr('explore_tourism')} $region',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle & Action Indicator (Hierarchical Spacing)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr('find_destination'),
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SigumiTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Jelajah',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
