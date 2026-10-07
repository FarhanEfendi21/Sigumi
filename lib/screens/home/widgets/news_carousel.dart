import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../config/theme_extensions.dart';
import '../../../models/news_item.dart';

class NewsCarousel extends StatefulWidget {
  final List<NewsItem> newsItems;

  const NewsCarousel({super.key, required this.newsItems});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant NewsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newsItems.length == widget.newsItems.length) return;

    _timer?.cancel();
    if (widget.newsItems.isEmpty) {
      _currentPage = 0;
      return;
    }

    _currentPage = _currentPage.clamp(0, widget.newsItems.length - 1).toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentPage);
      }
      _startAutoSlide();
    });
  }

  void _startAutoSlide() {
    _timer?.cancel();
    if (!mounted || widget.newsItems.length < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_pageController.hasClients) return;
      final currentPage = _pageController.page?.round() ?? _currentPage;
      final nextPage = (currentPage + 1) % widget.newsItems.length;
      _animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    if (_currentPage != index && mounted) {
      setState(() => _currentPage = index);
    }
    _startAutoSlide();
  }

  Future<void> _animateToPage(
    int page, {
    required Duration duration,
    required Curve curve,
    bool restartAutoSlide = false,
  }) async {
    if (!mounted ||
        !_pageController.hasClients ||
        widget.newsItems.length < 2) {
      return;
    }

    try {
      await _pageController.animateToPage(
        page,
        duration: duration,
        curve: curve,
      );
    } finally {
      if (restartAutoSlide && mounted) _startAutoSlide();
    }
  }

  void _navigateManually(int direction) {
    final itemCount = widget.newsItems.length;
    if (itemCount < 2 || !_pageController.hasClients) return;

    _timer?.cancel();
    final currentPage =
        (_pageController.page ?? _currentPage.toDouble()).round();
    final targetPage = (currentPage + direction + itemCount) % itemCount;
    _animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      restartAutoSlide: true,
    );
  }

  void _previousPage() => _navigateManually(-1);

  void _nextPage() => _navigateManually(1);

  @override
  Widget build(BuildContext context) {
    if (widget.newsItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              // ── PageView Slider ──
              PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: widget.newsItems.length,
                itemBuilder: (context, index) {
                  return _NewsCard(news: widget.newsItems[index]);
                },
              ),

              // ── Left Arrow ──
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _ArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: _previousPage,
                  ),
                ),
              ),

              // ── Right Arrow ──
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: _nextPage,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ── Dots Indicator ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.newsItems.length,
            (index) => _buildDot(index),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 20 : 6,
      decoration: BoxDecoration(
        color: isActive 
            ? SigumiTheme.primaryBlue 
            : SigumiTheme.primaryBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem news;

  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.newsDetail,
          arguments: news,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                Image.network(
                  news.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.image_rounded, color: Colors.grey),
                  ),
                ),

                // Black Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.4, 0.6, 1.0],
                    ),
                  ),
                ),

                // Category Badge (Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(news.categoryIcon, size: 12, color: context.adaptUiColor(news.categoryColor)),
                        const SizedBox(width: 4),
                        Text(
                          news.categoryLabel,
                          style: AppFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: context.adaptUiColor(news.categoryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideX(begin: -0.2, end: 0, duration: 400.ms),

                // Content (Bottom)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        style: AppFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            news.timeAgo,
                            style: AppFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SigumiTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              news.source,
                              style: AppFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
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
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ArrowButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        style: IconButton.styleFrom(
          foregroundColor: SigumiTheme.primaryBlue,
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 4,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

