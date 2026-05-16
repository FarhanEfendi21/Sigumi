import 'dart:math';
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
              subtitle:
                  'Pelajari dasar-dasar kesiapsiagaan menghadapi bencana gunung berapi dengan panduan yang jelas.',
              icon: Icons.menu_book,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 220,
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
  // Tracking kartu yang sudah dijawab semua kuis-nya (in-session)
  final Set<int> _completedCards = {};

  late final List<Map<String, dynamic>> _shuffledCards;

  @override
  void initState() {
    super.initState();
    _shuffledCards = List.from(EducationMockData.childrenTopics)..shuffle();
  }

  void _onCardCompleted(int index) {
    setState(() {
      _completedCards.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = _shuffledCards;
    final activeColor = cards[_currentIndex]['color'] as Color;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // ── Banner Hero ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ChildrenBanner(
            answeredCount: _completedCards.length,
            totalCount: cards.length,
          ),
        ),

        // ── Carousel Kartu ───────────────────────────────────────
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardHeight = MediaQuery.of(context).size.height * 0.62;
              return CarouselSlider.builder(
                itemCount: cards.length,
                itemBuilder: (context, index, realIndex) {
                  return _ChildFlashcardItem(
                    card: cards[index],
                    index: index,
                    cardNumber: index + 1,
                    totalCards: cards.length,
                    onCompleted: () => _onCardCompleted(index),
                  );
                },
                options: CarouselOptions(
                  height: cardHeight,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.18,
                  viewportFraction: 0.88,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() => _currentIndex = index);
                  },
                ),
              );
            },
          ),
        ),

        // ── Pill Indicator ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${cards.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ...cards.asMap().entries.map((entry) {
                  final isActive = _currentIndex == entry.key;
                  final cardColor = cards[entry.key]['color'] as Color;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 22.0 : 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isActive
                          ? cardColor
                          : cardColor.withValues(alpha: 0.25),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // ── Hint geser ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe_rounded, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  'Geser kartu • Ketuk untuk kuis',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
              subtitle:
                  'Panduan khusus bagi individu dengan disabilitas dan lansia untuk memastikan keselamatan bersama.',
              icon: Icons.accessibility_new,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 240,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _DisabilityGridCard(item: items[index], index: index),
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
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 100 * index),
          duration: 400.ms,
        )
        .scale(
          delay: Duration(milliseconds: 100 * index),
          duration: 400.ms,
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
        );
  }
}

// =============================================================================
// FLASHCARD ITEM — 5 pertanyaan per kartu, randomized
// =============================================================================

class _ChildFlashcardItem extends StatefulWidget {
  final Map<String, dynamic> card;
  final int index;
  final int cardNumber;
  final int totalCards;
  final VoidCallback? onCompleted;

  const _ChildFlashcardItem({
    required this.card,
    required this.index,
    required this.cardNumber,
    required this.totalCards,
    this.onCompleted,
  });

  @override
  State<_ChildFlashcardItem> createState() => _ChildFlashcardItemState();
}

class _ChildFlashcardItemState extends State<_ChildFlashcardItem>
    with SingleTickerProviderStateMixin {
  // ── Quiz state ──────────────────────────────────────────────────
  late List<Map<String, dynamic>> _quizQuestions; // 5 soal teracak
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _hasAnswered = false;
  int _correctCount = 0;
  bool _quizFinished = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initQuiz();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _initQuiz() {
    final allQuestions =
        List<Map<String, dynamic>>.from(widget.card['quizQuestions'] as List);
    allQuestions.shuffle(Random());
    // Ambil 5 soal (atau semua kalau < 5)
    _quizQuestions = allQuestions.take(5).toList();
    _currentQuestionIndex = 0;
    _selectedAnswerIndex = null;
    _hasAnswered = false;
    _correctCount = 0;
    _quizFinished = false;
  }

  void _handleAnswer(int selectedIndex, int correctIndex) {
    if (_hasAnswered) return;
    setState(() {
      _selectedAnswerIndex = selectedIndex;
      _hasAnswered = true;
      if (selectedIndex == correctIndex) {
        _correctCount++;
      } else {
        _shakeController.forward(from: 0);
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _hasAnswered = false;
      });
    } else {
      setState(() => _quizFinished = true);
      widget.onCompleted?.call();
    }
  }

  void _restartQuiz() {
    setState(() => _initQuiz());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.card['color'] as Color;
    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      front: _buildFrontCard(color),
      back: _buildBackCard(color),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SISI DEPAN KARTU
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFrontCard(Color color) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.06),
        Colors.white,
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Area Emoji (Header) ───────────────────────────
          Expanded(
            flex: 38,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(34)),
                    child: CustomPaint(
                      painter: _StarPatternPainter(color: color),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Topik ${widget.cardNumber} dari ${widget.totalCards}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                // Badge jumlah soal
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Text(
                      '5 Soal 🧠',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    widget.card['emoji'] as String,
                    style: const TextStyle(fontSize: 82),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .scaleXY(
                        end: 1.1,
                        duration: 1800.ms,
                        curve: Curves.easeInOutSine,
                      )
                      .slideY(
                        end: -0.08,
                        duration: 1800.ms,
                        curve: Curves.easeInOutSine,
                      ),
                ),
              ],
            ),
          ),

          // ── Konten Teks ───────────────────────────────────
          Expanded(
            flex: 62,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.card['title'] as String,
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: color,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        widget.card['intro'] as String,
                        style: AppFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.65),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 11),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🧠 Ketuk → Main Kuis 5 Soal!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          end: 1.05,
                          duration: 900.ms,
                          curve: Curves.easeInOutSine,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ─────────────────────────────────────────────────────────────────
  // SISI BELAKANG (KUIS — 5 SOAL)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBackCard(Color color) {
    if (_quizFinished) {
      return _buildFinishCard(color);
    }

    final currentQ = _quizQuestions[_currentQuestionIndex];
    final answers = currentQ['answers'] as List<String>;
    final correctIndex = currentQ['correctIndex'] as int;
    final isCorrect = _hasAnswered && _selectedAnswerIndex == correctIndex;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final dx = _hasAnswered && !isCorrect
            ? 6 * (_shakeAnimation.value * 2 - 1)
            : 0.0;
        return Transform.translate(
          offset: Offset(dx.clamp(-6.0, 6.0), 0),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: _hasAnswered
                ? (isCorrect
                    ? Colors.green.withValues(alpha: 0.6)
                    : Colors.red.withValues(alpha: 0.4))
                : color.withValues(alpha: 0.4),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hasAnswered
                      ? (isCorrect ? Colors.green : Colors.orange)
                      : color)
                  .withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header kuis ─────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('🧠', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soal ${_currentQuestionIndex + 1} dari ${_quizQuestions.length}',
                          style: AppFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: color,
                          ),
                        ),
                        Text(
                          'Pilih jawaban yang benar ya!',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Progress bar soal ────────────────────────
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _quizQuestions.length,
                  minHeight: 6,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              const SizedBox(height: 14),

              // ── Pertanyaan ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(
                  currentQ['question'] as String,
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Pilihan Jawaban ──────────────────────────
              ...answers.asMap().entries.map((entry) {
                final i = entry.key;
                final answer = entry.value;
                final isSelected = _selectedAnswerIndex == i;
                final isCorrectAnswer = i == correctIndex;

                Color pillBg;
                Color pillBorder;
                Color pillText;
                Widget? trailingIcon;

                if (!_hasAnswered) {
                  pillBg = isSelected
                      ? color.withValues(alpha: 0.15)
                      : Colors.grey.shade50;
                  pillBorder = isSelected ? color : Colors.grey.shade200;
                  pillText = isSelected ? color : Colors.black87;
                  trailingIcon = null;
                } else {
                  if (isCorrectAnswer) {
                    pillBg = const Color(0xFFE8F5E9);
                    pillBorder = Colors.green;
                    pillText = Colors.green.shade800;
                    trailingIcon = const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20);
                  } else if (isSelected && !isCorrectAnswer) {
                    pillBg = const Color(0xFFFFEBEE);
                    pillBorder = Colors.red;
                    pillText = Colors.red.shade700;
                    trailingIcon = const Icon(Icons.cancel_rounded,
                        color: Colors.red, size: 20);
                  } else {
                    pillBg = Colors.grey.shade50;
                    pillBorder = Colors.grey.shade200;
                    pillText = Colors.grey.shade400;
                    trailingIcon = null;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _hasAnswered
                        ? null
                        : () => _handleAnswer(i, correctIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: pillBorder, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: pillBorder.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(
                                  color: pillText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              answer,
                              style: AppFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: pillText,
                              ),
                            ),
                          ),
                          if (trailingIcon != null) trailingIcon,
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // ── Feedback setelah menjawab ────────────────
              if (_hasAnswered) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCorrect
                          ? [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)]
                          : [
                              const Color(0xFFFFF8E1),
                              const Color(0xFFFFFDE7)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? '🌟' : '💪',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCorrect
                                  ? 'Luar Biasa! Kamu Pintar!'
                                  : 'Hampir Benar! Semangat!',
                              style: AppFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: isCorrect
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              currentQ['explanation'] as String,
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isCorrect
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                // ── Tombol Soal Berikutnya ───────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentQuestionIndex < _quizQuestions.length - 1
                          ? 'Soal Berikutnya →'
                          : 'Lihat Hasil Kuis 🎉',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // KARTU HASIL AKHIR KUIS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFinishCard(Color color) {
    final total = _quizQuestions.length;
    final isAllCorrect = _correctCount == total;
    final isPerfect = _correctCount == total;
    final String emoji = isPerfect
        ? '🏆'
        : _correctCount >= 3
            ? '⭐'
            : '💪';
    final String title = isPerfect
        ? 'Sempurna! Kamu Jenius!'
        : _correctCount >= 3
            ? 'Hebat! Kamu Hampir Sempurna!'
            : 'Terus Semangat Belajar!';
    final String subtitle = isPerfect
        ? 'Semua $_correctCount dari $total soal benar! Kamu luar biasa!'
        : 'Kamu menjawab $_correctCount dari $total soal dengan benar.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isAllCorrect
              ? Colors.amber.withValues(alpha: 0.6)
              : color.withValues(alpha: 0.4),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAllCorrect ? Colors.amber : color).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji hasil
            Text(emoji, style: const TextStyle(fontSize: 72))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                    end: 1.15,
                    duration: 1200.ms,
                    curve: Curves.easeInOutSine),

            const SizedBox(height: 20),

            // Judul
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: isAllCorrect ? Colors.amber.shade700 : color,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Skor visual
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    i < _correctCount ? '⭐' : '☆',
                    style: const TextStyle(fontSize: 24),
                  )
                      .animate(
                          delay: Duration(milliseconds: 100 * i))
                      .scaleXY(
                          begin: 0.5,
                          end: 1.0,
                          duration: 400.ms,
                          curve: Curves.elasticOut),
                );
              }),
            ),

            const SizedBox(height: 28),

            // Tombol ulangi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _restartQuiz,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Ulangi Kuis',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        curve: Curves.easeOutCubic);
  }
}

// =============================================================================
// BANNER HERO ANAK-ANAK
// =============================================================================

class _ChildrenBanner extends StatelessWidget {
  final int answeredCount;
  final int totalCount;

  const _ChildrenBanner({
    required this.answeredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? answeredCount / totalCount : 0.0;
    final List<String> starEmojis = List.generate(
      totalCount,
      (i) => i < answeredCount ? '⭐' : '☆',
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFFB74D),
            Color(0xFFFFD54F),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -15,
            right: 30,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🦸', style: const TextStyle(fontSize: 44))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          end: 1.08,
                          duration: 1600.ms,
                          curve: Curves.easeInOutSine),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, Pahlawan Cilik! 👋',
                          style: AppFonts.plusJakartaSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          answeredCount == 0
                              ? 'Ayo mulai belajar tentang gunung berapi!'
                              : answeredCount == totalCount
                                  ? 'Hebat! Kamu sudah selesaikan semua topik! 🎉'
                                  : 'Bagus! Terus semangat belajarnya ya!',
                          style: AppFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Progress Belajar:',
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$answeredCount/$totalCount topik selesai',
                    style: AppFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: starEmojis
                    .asMap()
                    .entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(e.value, style: const TextStyle(fontSize: 18))
                            .animate(
                                delay: Duration(milliseconds: 80 * e.key))
                            .scaleXY(
                              begin: 0.8,
                              end: 1.0,
                              duration: 300.ms,
                              curve: Curves.elasticOut,
                            ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.05, end: 0);
  }
}

// =============================================================================
// DISABILITY GRID CARD
// =============================================================================

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
        onTap: () => _showTipsModal(context, item, color, iconData),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1)),
                child: Center(child: Icon(iconData, size: 40, color: color)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms);
  }

  void _showTipsModal(BuildContext context, Map<String, dynamic> item,
      Color color, IconData icon) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: AppFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87),
                        ),
                        Text(
                          item['subtitle'] as String,
                          style: AppFonts.plusJakartaSans(
                              fontSize: 12, color: SigumiTheme.textSecondary),
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
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: Icon(Icons.check, size: 12, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        (item['tips'] as List<String>)[i],
                        style: AppFonts.plusJakartaSans(
                            fontSize: 14, height: 1.5, color: Colors.black87),
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
      case 'hearing':
        return Icons.hearing;
      case 'visibility_off':
        return Icons.visibility_off;
      case 'accessible':
        return Icons.accessible;
      case 'elderly':
        return Icons.elderly;
      default:
        return Icons.person;
    }
  }
}

// =============================================================================
// CUSTOM PAINTER — POLA BINTANG DEKORATIF DI HEADER KARTU
// =============================================================================

class _StarPatternPainter extends CustomPainter {
  final Color color;
  _StarPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color.withValues(alpha: 0.09),
    );

    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.18), 38, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.08, size.height * 0.80), 26, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.50, size.height * 0.90), 18, circlePaint);

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final dotPositions = [
      Offset(size.width * 0.20, size.height * 0.15),
      Offset(size.width * 0.60, size.height * 0.12),
      Offset(size.width * 0.90, size.height * 0.50),
      Offset(size.width * 0.30, size.height * 0.70),
      Offset(size.width * 0.72, size.height * 0.75),
    ];
    for (final pos in dotPositions) {
      canvas.drawCircle(pos, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}