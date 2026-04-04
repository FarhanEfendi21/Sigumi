import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import '../../config/theme.dart';
import '../../models/education_model.dart';
import '../../data/education_mock.dart';
import 'education_detail_screen.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Edukasi Bencana',
            style: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: const Color(0xFF1E1E2C),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1E1E2C)),
          bottom: TabBar(
            indicatorColor: SigumiTheme.primaryBlue,
            labelColor: const Color(0xFF1E1E2C),
            unselectedLabelColor: const Color(0xFF1E1E2C).withValues(alpha: 0.5),
            indicatorWeight: 3,
            labelStyle: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            unselectedLabelStyle: AppFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Umum'),
              Tab(text: 'Anak-Anak'),
              Tab(text: 'Difabel'),
            ],
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        body: const TabBarView(
          children: [
            _GeneralEducationGrid(),
            _ChildrenEducationGrid(),
            _DisabilityEducationGrid(),
          ],
        ),
      ),
    );
  }
}

class _GeneralEducationGrid extends StatelessWidget {
  const _GeneralEducationGrid();

  @override
  Widget build(BuildContext context) {
    final topics = EducationMockData.generalTopics;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _AnimatedHeader(
              title: 'Panduan Edukasi Umum',
              subtitle: 'Pelajari dasar-dasar kesiapsiagaan menghadapi bencana gunung berapi dengan panduan yang jelas.',
              icon: Icons.menu_book,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75, // Adjusting for height
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final topic = topics[index];
                return _TopicGridCard(topic: topic, index: index);
              },
              childCount: topics.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

class _ChildrenEducationGrid extends StatelessWidget {
  const _ChildrenEducationGrid();

  @override
  Widget build(BuildContext context) {
    final cards = EducationMockData.childrenTopics;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _AnimatedHeader(
              title: 'Belajar Bersama Anak-Anak 🎈',
              subtitle: 'Kenali gunung berapi dan cara aman dengan bahasa yang mudah untuk si kecil.',
              icon: Icons.child_care_rounded,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ChildGridCard(card: cards[index], index: index),
              childCount: cards.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

class _DisabilityEducationGrid extends StatelessWidget {
  const _DisabilityEducationGrid();

  @override
  Widget build(BuildContext context) {
    final items = EducationMockData.disabilityTopics;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _AnimatedHeader(
              title: 'Aksesibilitas & Inklusi ♿',
              subtitle: 'Panduan khusus bagi individu dengan disabilitas dan lansia untuk memastikan keselamatan bersama.',
              icon: Icons.accessibility_new,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _DisabilityGridCard(item: items[index], index: index),
              childCount: items.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

// =============================================================================
// REUSABLE UI COMPONENTS
// =============================================================================

class _AnimatedHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AnimatedHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SigumiTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SigumiTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.5,
              color: SigumiTheme.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _TopicGridCard extends StatelessWidget {
  final EducationTopic topic;
  final int index;

  const _TopicGridCard({required this.topic, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EducationDetailScreen(
                title: topic.title,
                imagePath: topic.imagePath,
                accentColor: topic.color,
                icon: topic.icon,
                sections: topic.sections,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Top Half
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: topic.color.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    topic.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            // Bottom Info
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: topic.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PANDUAN',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: topic.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      topic.title,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.subtitle,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11,
                        color: SigumiTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: 400.ms,
    ).scale(
      delay: Duration(milliseconds: 100 * index),
      duration: 400.ms,
      begin: const Offset(0.9, 0.9),
      end: const Offset(1, 1),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ChildGridCard extends StatelessWidget {
  final Map<String, dynamic> card;
  final int index;

  const _ChildGridCard({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = card['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Illustration Header like General Section
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                card['emoji'] as String,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  card['title'] as String,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: color,
                  ),
                ),
                const SizedBox(height: 14),
                
                // Intro
                _buildHighlightedText(card['intro'] as String, color, fontSize: 15.5),
                const SizedBox(height: 18),
                
                // Bullets
                if (card['bullets'] != null)
                  ...((card['bullets'] as List<String>).map((bullet) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8, right: 12),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: _buildHighlightedText(bullet, color, fontSize: 14.5),
                            ),
                          ],
                        ),
                      ))),
                
                // Fun Fact / Tip
                if (card['tip'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TAHUKAH KAMU?',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildHighlightedText(card['tip'] as String, color, fontSize: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: 400.ms,
    ).slideY(
      begin: 0.05,
      end: 0,
      curve: Curves.easeOutCubic,
      duration: 400.ms,
      delay: Duration(milliseconds: 100 * index),
    );
  }

  Widget _buildHighlightedText(String text, Color highlightColor, {double fontSize = 14.0}) {
    final spans = <TextSpan>[];
    final parts = text.split('*');
    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Highlighted part - Now consistent with user request: Not bold & black
        spans.add(TextSpan(
          text: parts[i],
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w500, // Medium but not bold
            color: Colors.black.withValues(alpha: 0.9),
          ),
        ));
      } else {
        // Normal part
        spans.add(TextSpan(
          text: parts[i],
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ));
      }
    }
    return RichText(
      text: TextSpan(
        style: AppFonts.plusJakartaSans(
          fontSize: fontSize,
          height: 1.6, // Better line height for children's reading
        ),
        children: spans,
      ),
    );
  }
}

class _DisabilityGridCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const _DisabilityGridCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = Color(item['color'] as int);
    final iconData = _getIconData(item['icon'] as String);
    final isSpecialNeeds = item['title'] == 'Lansia';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showTipsModal(context, item, color, iconData);
        },
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Icon(iconData, size: 40, color: color),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSpecialNeeds ? 'LANSIA' : 'DIFABEL',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item['title'] as String,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk untuk baca tips →',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: SigumiTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: 400.ms,
    );
  }

  void _showTipsModal(BuildContext context, Map<String, dynamic> item, Color color, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: AppFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        Text(
                          item['subtitle'] as String,
                          style: AppFonts.plusJakartaSans(fontSize: 12, color: SigumiTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: (item['tips'] as List<String>).length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(Icons.check, size: 12, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (item['tips'] as List<String>)[i],
                        style: AppFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'hearing': return Icons.hearing;
      case 'visibility_off': return Icons.visibility_off;
      case 'accessible': return Icons.accessible;
      case 'elderly': return Icons.elderly;
      default: return Icons.person;
    }
  }
}

