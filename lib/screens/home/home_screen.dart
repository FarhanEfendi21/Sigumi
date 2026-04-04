import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../services/ai_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                          Color(0xFFF0F4FF),   // Soft icy blue
                          Color(0xFFE8EDFA),   // Light periwinkle
                          Color(0xFFFFF8E8),   // Warm cream hint
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
                                  AiService.getPersonalizedGreeting(provider.currentUser),
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
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.cloud_off,
                                            color: Colors.orange, size: 14),
                                        SizedBox(width: 4),
                                        Text('Offline',
                                            style: TextStyle(
                                                color: Colors.orange, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B2E7B).withAlpha(15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, AppRoutes.accessibility),
                                    icon: const Icon(Icons.accessibility_new,
                                        color: Color(0xFF1B2E7B), size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Status Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF1B2E7B).withAlpha(15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1B2E7B).withAlpha(12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.landscape, color: statusColor, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          volcano.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'Elevasi: ${volcano.elevation.toInt()} mdpl',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: SigumiTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: statusColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      volcano.statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Distance indicator
                              GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.zoneDetail),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: SigumiTheme.getStatusColor(provider.zoneLevel)
                                      .withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: SigumiTheme.getStatusColor(provider.zoneLevel)
                                        .withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.my_location,
                                      color: SigumiTheme.getStatusColor(
                                          provider.zoneLevel),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            provider.distanceLabel,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: SigumiTheme.getStatusColor(
                                                  provider.zoneLevel),
                                            ),
                                          ),
                                          Text(
                                            provider.zoneLabel,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: SigumiTheme.getStatusColor(
                                          provider.zoneLevel),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  ),


                  // Menu Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'Menu Utama',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.85,
                    children: [
                      _MenuTile(
                        icon: Icons.map_rounded,
                        label: 'Peta\nRisiko',
                        color: Colors.blue,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.map),
                      ),
                      _MenuTile(
                        icon: Icons.phone_in_talk_rounded,
                        label: 'Nomor\nDarurat',
                        color: Colors.red,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.emergency),
                      ),
                      _MenuTile(
                        icon: Icons.alt_route_rounded,
                        label: 'Jalur\nEvakuasi',
                        color: Colors.green,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.evacuation),
                      ),
                      _MenuTile(
                        icon: Icons.chat_rounded,
                        label: 'AI\nChatbot',
                        color: Colors.purple,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.chatbot),
                      ),
                      _MenuTile(
                        icon: Icons.school_rounded,
                        label: 'Edukasi',
                        color: Colors.orange,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.education),
                      ),
                      _MenuTile(
                        icon: Icons.camera_alt_rounded,
                        label: 'Visual\nMerapi',
                        color: Colors.teal,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.visualMerapi),
                      ),
                      _MenuTile(
                        icon: Icons.healing_rounded,
                        label: 'Pasca\nBencana',
                        color: Colors.indigo,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.postDisaster),
                      ),
                      _MenuTile(
                        icon: Icons.accessibility_new_rounded,
                        label: 'Akses\nibilitas',
                        color: Colors.brown,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.accessibility),
                      ),
                    ],
                  ),

                  // Berita Terkini Section
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

                  // News List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.newsItems.length,
                    itemBuilder: (context, index) {
                      final news = provider.newsItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.newsDetail,
                              arguments: news,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: SigumiTheme.divider.withAlpha(128),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color:
                                        news.categoryColor.withAlpha(30),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    news.categoryIcon,
                                    color: news.categoryColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category badge
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color: news.categoryColor
                                              .withAlpha(25),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          news.categoryLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: news.categoryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Title
                                      Text(
                                        news.title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Summary
                                      Text(
                                        news.summary,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              SigumiTheme.textSecondary,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      // Source & time
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.source_outlined,
                                            size: 12,
                                            color: SigumiTheme
                                                .textSecondary
                                                .withAlpha(180),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            news.source,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: SigumiTheme
                                                  .textSecondary
                                                  .withAlpha(180),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: SigumiTheme
                                                .textSecondary
                                                .withAlpha(180),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            news.timeAgo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: SigumiTheme
                                                  .textSecondary
                                                  .withAlpha(180),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Arrow
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: SigumiTheme.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
