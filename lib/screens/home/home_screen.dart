import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../services/ai_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'widgets/news_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasCheckedRegion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<VolcanoProvider>();
      await provider.autoDetectAndSetRegion();

      if (!mounted) return;

      // Jika di luar cakupan, tampilkan pemilihan daerah manual
      if (provider.needsManualRegionSelection && !_hasCheckedRegion) {
        _hasCheckedRegion = true;
        _showMandatoryRegionPicker(context, provider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final volcano = provider.volcano;
        final statusColor = SigumiTheme.getStatusColor(volcano.statusLevel);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
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
                            Column(
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
                                ),
                              ],
                            ),
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
                        Builder(
                          builder: (context) {
                            String formattedName =
                                volcano.name
                                    .toLowerCase()
                                    .replaceAll('gunung ', '')
                                    .trim();
                            String imagePath =
                                'assets/images/$formattedName.jpg';

                            return Container(
                              width: double.infinity,
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
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
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
                                              Colors.black.withAlpha(20),
                                              Colors.black.withAlpha(220),
                                            ],
                                            stops: const [0.3, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Content
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 10),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.landscape,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      volcano.name,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: -0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Elevasi: ${volcano.elevation.toInt()} mdpl',
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: statusColor,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withAlpha(40),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  volcano.statusLabel,
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 30),
                                          // Distance indicator
                                          GestureDetector(
                                            onTap:
                                                () => Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.zoneDetail,
                                                ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withAlpha(
                                                  240,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withAlpha(20),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.my_location,
                                                    color:
                                                        SigumiTheme.getStatusColor(
                                                          provider.zoneLevel,
                                                        ),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          provider
                                                              .distanceLabel,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Plus Jakarta Sans',
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                SigumiTheme.getStatusColor(
                                                                  provider
                                                                      .zoneLevel,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          provider.zoneLabel,
                                                          style: const TextStyle(
                                                            fontFamily:
                                                                'Plus Jakarta Sans',
                                                            fontSize: 12,
                                                            color:
                                                                SigumiTheme
                                                                    .textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    color:
                                                        SigumiTheme.getStatusColor(
                                                          provider.zoneLevel,
                                                        ),
                                                    size: 24,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Tourism Promo Banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: _TourismBannerCard(region: provider.selectedRegion),
                  ),

                  // Menu Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Menu Utama',
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
                    childAspectRatio: 2.2,
                    children: [
                      _ShadMenuCard(
                        icon: Icons.alt_route_rounded,
                        label: 'Titik Aman\nEvakuasi',
                        color: Colors.green,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.evacuation,
                            ),
                      ),
                      _ShadMenuCard(
                        icon: Icons.camera_alt_rounded,
                        label: 'CCTV\nGunung',
                        color: Colors.teal,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.visualMerapi,
                            ),
                      ),
                      _ShadMenuCard(
                        icon: Icons.school_rounded,
                        label: 'Edukasi',
                        color: Colors.orange,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.education,
                            ),
                      ),
                      _ShadMenuCard(
                        icon: Icons.local_hospital_rounded,
                        label: 'Posko &\nFaskes',
                        color: Colors.indigo,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.postDisaster,
                            ),
                      ),
                      _ShadMenuCard(
                        icon: Icons.chat_rounded,
                        label: 'Tanya\nSi Gumi',
                        color: Colors.purple,
                        onTap:
                            () =>
                                Navigator.pushNamed(context, AppRoutes.chatbot),
                      ),
                      _ShadMenuCard(
                        icon: Icons.phone_in_talk_rounded,
                        label: 'Nomor\nDarurat',
                        color: Colors.red,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.emergency,
                            ),
                      ),
                      _ShadMenuCard(
                        icon: Icons.accessibility_new_rounded,
                        label: 'Aksesibilitas',
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
                    child: Row(
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
                          'Berita Terkini',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${provider.newsItems.length} berita',
                          style: const TextStyle(
                            fontSize: 12,
                            color: SigumiTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // News Carousel Slider
                  NewsCarousel(newsItems: provider.newsItems),
          

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────
  // REGION SELECTOR — Header badge dengan deteksi GPS
  // ────────────────────────────────────────────────
  Widget _buildRegionSelector(BuildContext context, VolcanoProvider provider) {
    final isAutoDetected = provider.isRegionAutoDetected &&
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
                color: isAutoDetected
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
                      'Lokasi Anda',
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

  /// Tampilkan region picker wajib (tidak bisa di-dismiss tanpa memilih)
  void _showMandatoryRegionPicker(
      BuildContext context, VolcanoProvider provider) {
    _showRegionPickerSheet(
      context: context,
      provider: provider,
      isDismissible: false,
      title: 'Pilih Daerah Anda',
      subtitle:
          'Anda berada di luar area cakupan. Silakan pilih daerah untuk memantau gunung berapi.',
    );
  }

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
                              title ?? 'Pilih Daerah',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: SigumiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle ??
                                  'Pantau gunung berapi aktif di daerah Anda',
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
                          provider.dismissManualSelection();
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withAlpha(12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
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
                                            color: isSelected
                                                ? color
                                                : SigumiTheme.textPrimary,
                                          ),
                                        ),
                                        if (isDetected) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
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
                                                  color:
                                                      Colors.green.shade700,
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
              border: Border.all(
                color: color.withAlpha(40),
                width: 1,
              ),
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
      height: 120, // Clean, balanced height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            bgColor.withAlpha(200),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title Typography Hierarchy
                    Text(
                      'Jelajahi Wisata $region',
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
                            'Temukan destinasi & agenda budaya menarik',
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
