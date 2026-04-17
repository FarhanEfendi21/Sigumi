import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flip_card/flip_card.dart';
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

class _ChildrenEducationGrid extends StatefulWidget {
  const _ChildrenEducationGrid();

  @override
  State<_ChildrenEducationGrid> createState() => _ChildrenEducationGridState();
}

class _ChildrenEducationGridState extends State<_ChildrenEducationGrid> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cards = EducationMockData.childrenTopics;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: const _AnimatedHeader(
            title: 'Petualangan Anak Hebat! 🎈',
            subtitle: 'Geser kartu di bawah ini dan mainkan kuis serunya!',
            icon: Icons.child_care_rounded,
          ),
        ),
        const Spacer(),
        CarouselSlider.builder(
          itemCount: cards.length,
          itemBuilder: (context, index, realIndex) {
            return _ChildFlashcardItem(card: cards[index], index: index);
          },
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height * 0.55,
            enlargeCenterPage: true,
            viewportFraction: 0.85,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const Spacer(),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: cards.asMap().entries.map((entry) {
            return Container(
              width: _currentIndex == entry.key ? 24.0 : 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: (cards[entry.key]['color'] as Color)
                    .withValues(alpha: _currentIndex == entry.key ? 0.9 : 0.3),
              ),
            );
          }).toList(),
        ),
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

class _ChildFlashcardItem extends StatefulWidget {
  final Map<String, dynamic> card;
  final int index;

  const _ChildFlashcardItem({required this.card, required this.index});

  @override
  State<_ChildFlashcardItem> createState() => _ChildFlashcardItemState();
}

class _ChildFlashcardItemState extends State<_ChildFlashcardItem> {
  int? _selectedAnswerIndex;
  bool _hasAnswered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.card['color'] as Color;

    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      front: _buildFrontCard(color),
      back: _buildBackCard(color),
    );
  }

  Widget _buildFrontCard(Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36), // Bubbly corners
        border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Image/Emoji
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(33)),
              ),
              child: Center(
                child: Text(
                  widget.card['emoji'] as String,
                  style: const TextStyle(fontSize: 80),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(end: 1.08, duration: 1.5.seconds, curve: Curves.easeInOutSine)
                 .slideY(end: -0.1, duration: 1.5.seconds, curve: Curves.easeInOutSine),
              ),
            ),
          ),
          // Content
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.card['title'] as String,
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.card['intro'] as String,
                    textAlign: TextAlign.center,
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Ketuk untuk main kuis!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        const Icon(Icons.touch_app, color: Colors.white, size: 18),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.05, duration: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Color color) {
    if (widget.card['quizAnswers'] == null) {
      return Container(
         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(36)),
         child: const Center(child: Text('Belum ada kuis untuk bagian ini!')),
      );
    }
    
    final answers = widget.card['quizAnswers'] as List<String>;
    final correctAnswerIndex = widget.card['correctAnswerIndex'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Text(
              'Ayo Jawab!',
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.card['quizQuestion'] as String,
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: answers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final isSelected = _selectedAnswerIndex == i;
                  final isCorrect = i == correctAnswerIndex;
                  
                  Color btnColor = Colors.grey.shade100;
                  Color textColor = Colors.black87;
                  
                  if (_hasAnswered) {
                    if (isCorrect) {
                      btnColor = Colors.green.shade100;
                      textColor = Colors.green.shade800;
                    } else if (isSelected && !isCorrect) {
                      btnColor = Colors.red.shade100;
                      textColor = Colors.red.shade800;
                    }
                  } else if (isSelected) {
                    btnColor = color.withValues(alpha: 0.2);
                  }

                  return InkWell(
                    onTap: _hasAnswered ? null : () {
                      setState(() {
                        _selectedAnswerIndex = i;
                        _hasAnswered = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: btnColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (_hasAnswered && isCorrect) 
                             ? Colors.green 
                             : ((_hasAnswered && isSelected && !isCorrect) ? Colors.red : Colors.transparent),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              answers[i],
                              style: AppFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (_hasAnswered && isCorrect)
                            const Icon(Icons.check_circle, color: Colors.green),
                          if (_hasAnswered && isSelected && !isCorrect)
                            const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_hasAnswered)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedAnswerIndex == correctAnswerIndex 
                      ? Colors.green.shade50 
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedAnswerIndex == correctAnswerIndex
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  )
                ),
                child: Text(
                  widget.card['explanation'] as String,
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _selectedAnswerIndex == correctAnswerIndex
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ],
        ),
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

