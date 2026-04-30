import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/fonts.dart';
import '../../models/news_item.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final newsItem = ModalRoute.of(context)!.settings.arguments as NewsItem;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Detail Berita',
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1E1E2C),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E2C), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            if (newsItem.imageUrl != null)
              Container(
                width: double.infinity,
                height: 250,
                color: const Color(0xFFF8FAFC),
                child: Image.network(
                  newsItem.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 40),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
              
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category & Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: newsItem.categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          newsItem.categoryLabel.toUpperCase(),
                          style: AppFonts.plusJakartaSans(
                            color: newsItem.categoryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        newsItem.timeAgo,
                        style: AppFonts.plusJakartaSans(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    newsItem.title,
                    style: AppFonts.plusJakartaSans(
                      color: const Color(0xFF0F172A),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Source
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.source_rounded, size: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sumber: ${newsItem.source}',
                        style: AppFonts.plusJakartaSans(
                          color: const Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 1),
                  const SizedBox(height: 24),
                  
                  // Summary Callout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, color: Color(0xFF94A3B8), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            newsItem.summary,
                            style: AppFonts.plusJakartaSans(
                              color: const Color(0xFF334155),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Content
                  Text(
                    newsItem.content,
                    style: AppFonts.plusJakartaSans(
                      color: const Color(0xFF1E293B), // Slate 800
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.7,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 48),
                  
                  // Share Action (Cupertino style)
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.share, color: Color(0xFF0F172A), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bagikan Berita',
                            style: AppFonts.plusJakartaSans(
                              color: const Color(0xFF0F172A),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {
                        Share.share(
                          '${newsItem.title}\n\nBaca selengkapnya di aplikasi SIGUMI:\nhttps://sigumi.app/news/${newsItem.id}',
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
