import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/fonts.dart';
import '../../config/theme_extensions.dart';
import '../../models/news_item.dart';
import '../../services/localization_service.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final newsItem = ModalRoute.of(context)!.settings.arguments as NewsItem;

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        title: Text(
          context.trText('Detail Berita'),
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: context.textPrimary,
          ),
        ),
        backgroundColor: context.bgSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.textPrimary,
            size: 24,
          ),
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
                color: context.bgSecondary,
                child: Image.network(
                  newsItem.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: context.bgSecondary,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: context.textTertiary,
                            size: 40,
                          ),
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
                  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: context.adaptUiColor(newsItem.categoryColor).withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  newsItem.categoryLabel.toUpperCase(),
                                  style: AppFonts.plusJakartaSans(
                                    color: context.contrastColor(context.adaptUiColor(newsItem.categoryColor)),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                newsItem.timeAgo,
                                style: AppFonts.plusJakartaSans(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 13,
                                color: context.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatPublishedDate(newsItem.publishedAt),
                                style: AppFonts.plusJakartaSans(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                        newsItem.title,
                        style: AppFonts.plusJakartaSans(
                          color: context.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 150.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 16),

                  // Source
                  Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: context.bgSecondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.source_rounded,
                              size: 14,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sumber: ${newsItem.source}',
                            style: AppFonts.plusJakartaSans(
                              color: context.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),
                  Divider(
                    color: context.dividerColor,
                    thickness: 1.5,
                    height: 1,
                  ),
                  const SizedBox(height: 24),

                  // Summary Callout
                  Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor, width: context.borderWidth),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              color: context.textTertiary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                newsItem.summary,
                                style: AppFonts.plusJakartaSans(
                                  color: context.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 250.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Content
                  Text(
                        newsItem.content,
                        style: AppFonts.plusJakartaSans(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.7,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 48),

                  // Share Action (Cupertino style)
                  SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          color: context.accentPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.share,
                                color: context.isHighContrast
                                    ? context.bgPrimary
                                    : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                context.trText('Bagikan Berita'),
                                style: AppFonts.plusJakartaSans(
                                  color: context.isHighContrast
                                      ? context.bgPrimary
                                      : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            SharePlus.instance.share(
                              ShareParams(text: '${newsItem.title}\n\nBaca selengkapnya di aplikasi SIGUMI:\nhttps://sigumi.app/news/${newsItem.id}'),
                            );
                          },
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 350.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format tanggal dan waktu untuk ditampilkan di detail berita
  String _formatPublishedDate(DateTime dateTime) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year · $hour:$minute';
  }
}
