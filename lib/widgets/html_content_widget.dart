import 'package:flutter/material.dart';
import '../config/fonts.dart';
import '../config/theme_extensions.dart';

/// Widget untuk me-render konten HTML menjadi tampilan Flutter native.
/// Mendukung:
/// - Paragraf `<p>` dan teks biasa
/// - Gambar `<img src="..." />` (termasuk yang berada di dalam paragraf `<p>`)
/// - Pratinjau gambar responsif + fitur tap untuk zoom fullscreen (InteractiveViewer)
/// - Heading `<h1>` s.d. `<h6>`
/// - Format teks inline: `<strong>`, `<b>`, `<em>`, `<i>`, `<u>`, `<s>`, `<del>`, `<a>`, `<code>`
/// - Pindah baris `<br>` dan garis pemisah `<hr>`
/// - List `<ul>`, `<ol>`, dan `<li>`
/// - Kutipan `<blockquote>`
/// - HTML Entities (bernama seperti &amp;, desimal &#..., dan heksadesimal &#x...)
class HtmlContentWidget extends StatelessWidget {
  final String htmlContent;
  final Color textColor;
  final double baseFontSize;
  final double lineHeight;

  const HtmlContentWidget({
    super.key,
    required this.htmlContent,
    required this.textColor,
    this.baseFontSize = 16.0,
    this.lineHeight = 1.7,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = _parseHtml(context, htmlContent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<Widget> _parseHtml(BuildContext context, String rawHtml) {
    final List<Widget> widgets = [];
    if (rawHtml.trim().isEmpty) return widgets;

    String html = rawHtml.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Ubah <figure> dengan <img> dan <figcaption> menjadi struktur yang bersih
    html = html.replaceAllMapped(
      RegExp(r'<figure[^>]*>([\s\S]*?)<\/figure>', caseSensitive: false),
      (m) {
        final inner = m.group(1) ?? '';
        final imgMatch = RegExp(r'<img\b[^>]*\/?>', caseSensitive: false).firstMatch(inner);
        final captionMatch = RegExp(r'<figcaption[^>]*>([\s\S]*?)<\/figcaption>', caseSensitive: false).firstMatch(inner);
        final imgStr = imgMatch?.group(0) ?? '';
        final captionStr = captionMatch?.group(1)?.trim() ?? '';
        if (imgStr.isNotEmpty) {
          if (captionStr.isNotEmpty) {
            return '\n$imgStr\n<p style="text-align:center;"><em>$captionStr</em></p>\n';
          }
          return '\n$imgStr\n';
        }
        return inner;
      },
    );

    // Hilangkan wrapper <div> dengan newline agar blok di dalamnya diproses secara independen
    html = html.replaceAll(RegExp(r'<\/?div[^>]*>', caseSensitive: false), '\n');

    _processBlocks(context, html, widgets);
    return widgets;
  }

  void _processBlocks(BuildContext context, String html, List<Widget> widgets) {
    // Pola blok utama: p, h1-6, ul, ol, blockquote, hr, img
    final blockPattern = RegExp(
      r'(<p[^>]*>[\s\S]*?<\/p>|<h[1-6][^>]*>[\s\S]*?<\/h[1-6]>|<ul[^>]*>[\s\S]*?<\/ul>|<ol[^>]*>[\s\S]*?<\/ol>|<blockquote[^>]*>[\s\S]*?<\/blockquote>|<hr\s*\/?>|<img\b[^>]*\/?>)',
      caseSensitive: false,
    );

    int lastEnd = 0;
    for (final match in blockPattern.allMatches(html)) {
      if (match.start > lastEnd) {
        final textBefore = html.substring(lastEnd, match.start).trim();
        if (textBefore.isNotEmpty) {
          _processParagraphOrText(context, textBefore, widgets);
        }
      }

      final tag = match.group(0)!;
      final tagLower = tag.toLowerCase();

      if (tagLower.startsWith('<p')) {
        final innerHtml = _extractInnerHtml(tag, 'p');
        if (innerHtml.isNotEmpty) {
          _processParagraphOrText(context, innerHtml, widgets);
        }
      } else if (RegExp(r'^<h[1-6]', caseSensitive: false).hasMatch(tagLower)) {
        final level = int.tryParse(tagLower[2]) ?? 3;
        final innerHtml = _extractInnerHtml(tag, 'h$level');
        if (innerHtml.isNotEmpty) {
          _processHeading(context, innerHtml, level, widgets);
        }
      } else if (tagLower.startsWith('<ul') || tagLower.startsWith('<ol')) {
        final isOrdered = tagLower.startsWith('<ol');
        final listType = isOrdered ? 'ol' : 'ul';
        final innerHtml = _extractInnerHtml(tag, listType);
        _buildList(context, innerHtml, isOrdered, widgets);
      } else if (tagLower.startsWith('<blockquote')) {
        final innerHtml = _extractInnerHtml(tag, 'blockquote');
        _buildBlockquote(context, innerHtml, widgets);
      } else if (tagLower.startsWith('<hr')) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(thickness: 1, height: 1),
        ));
      } else if (tagLower.startsWith('<img')) {
        final src = _extractAttr(tag, 'src');
        if (src.isNotEmpty) {
          widgets.add(_buildImage(context, src, tag));
          widgets.add(const SizedBox(height: 16));
        }
      }

      lastEnd = match.end;
    }

    if (lastEnd < html.length) {
      final remaining = html.substring(lastEnd).trim();
      if (remaining.isNotEmpty) {
        _processParagraphOrText(context, remaining, widgets);
      }
    }
  }

  /// Memproses teks atau paragraf yang mungkin mengandung tag `<img>` di dalamnya.
  /// Menghasilkan urutan: Teks RichText -> Widget Gambar -> Teks RichText
  void _processParagraphOrText(
    BuildContext context,
    String content,
    List<Widget> widgets, {
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    FontStyle fontStyle = FontStyle.normal,
    TextAlign textAlign = TextAlign.justify,
  }) {
    final effectiveFontSize = fontSize ?? baseFontSize;
    final effectiveHeight = height ?? lineHeight;

    // Cek apakah ada tag <img> di dalam konten ini
    final imgPattern = RegExp(r'<img\b[^>]*\/?>', caseSensitive: false);
    final matches = imgPattern.allMatches(content).toList();

    if (matches.isEmpty) {
      final spans = _parseInlineSpans(
        content,
        fontSize: effectiveFontSize,
        fontWeight: fontWeight,
        height: effectiveHeight,
        fontStyle: fontStyle,
      );
      if (spans.isNotEmpty) {
        widgets.add(RichText(
          text: TextSpan(children: spans),
          textAlign: textAlign,
        ));
        widgets.add(const SizedBox(height: 12));
      }
      return;
    }

    // Ada satu atau lebih tag <img> di dalam paragraf
    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        final textBefore = content.substring(lastEnd, match.start).trim();
        if (textBefore.isNotEmpty) {
          final spans = _parseInlineSpans(
            textBefore,
            fontSize: effectiveFontSize,
            fontWeight: fontWeight,
            height: effectiveHeight,
            fontStyle: fontStyle,
          );
          if (spans.isNotEmpty) {
            widgets.add(RichText(
              text: TextSpan(children: spans),
              textAlign: textAlign,
            ));
            widgets.add(const SizedBox(height: 12));
          }
        }
      }

      final imgTag = match.group(0)!;
      final src = _extractAttr(imgTag, 'src');
      if (src.isNotEmpty) {
        widgets.add(_buildImage(context, src, imgTag));
        widgets.add(const SizedBox(height: 16));
      }

      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      final textAfter = content.substring(lastEnd).trim();
      if (textAfter.isNotEmpty) {
        final spans = _parseInlineSpans(
          textAfter,
          fontSize: effectiveFontSize,
          fontWeight: fontWeight,
          height: effectiveHeight,
          fontStyle: fontStyle,
        );
        if (spans.isNotEmpty) {
          widgets.add(RichText(
            text: TextSpan(children: spans),
            textAlign: textAlign,
          ));
          widgets.add(const SizedBox(height: 12));
        }
      }
    }
  }

  void _processHeading(
    BuildContext context,
    String innerHtml,
    int level,
    List<Widget> widgets,
  ) {
    const fontSizes = {1: 24.0, 2: 22.0, 3: 20.0, 4: 18.0, 5: 16.0, 6: 14.0};
    final fontSize = fontSizes[level] ?? 18.0;
    _processParagraphOrText(
      context,
      innerHtml,
      widgets,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.3,
      textAlign: TextAlign.left,
    );
  }

  void _buildList(
    BuildContext context,
    String innerHtml,
    bool isOrdered,
    List<Widget> widgets,
  ) {
    final itemPattern = RegExp(
      r'<li[^>]*>([\s\S]*?)<\/li>',
      caseSensitive: false,
    );
    final matches = itemPattern.allMatches(innerHtml).toList();

    widgets.add(Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: matches.asMap().entries.map((entry) {
          final idx = entry.key;
          final match = entry.value;
          final itemContent = match.group(1) ?? '';
          final bullet = isOrdered ? '${idx + 1}.' : '\u2022';

          final spans = _parseInlineSpans(
            itemContent,
            fontSize: baseFontSize,
            fontWeight: FontWeight.w400,
            height: lineHeight,
            fontStyle: FontStyle.normal,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    bullet,
                    style: TextStyle(
                      fontSize: baseFontSize,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(children: spans),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ));
  }

  void _buildBlockquote(
    BuildContext context,
    String innerHtml,
    List<Widget> widgets,
  ) {
    final spans = _parseInlineSpans(
      innerHtml,
      fontSize: baseFontSize - 1,
      fontWeight: FontWeight.w400,
      height: lineHeight,
      fontStyle: FontStyle.italic,
    );

    widgets.add(Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: context.accentPrimary, width: 3.5),
          ),
          color: context.bgSurface,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: RichText(
          text: TextSpan(children: spans),
        ),
      ),
    ));
  }

  /// Render gambar responsif dengan penanganan alt, error, loading indicator, dan fitur fullscreen zoom
  Widget _buildImage(BuildContext context, String src, String fullTag) {
    final alt = _extractAttr(fullTag, 'alt');
    final widthStr = _extractAttr(fullTag, 'width');
    final heightStr = _extractAttr(fullTag, 'height');
    final double? origWidth = double.tryParse(widthStr);
    final double? origHeight = double.tryParse(heightStr);

    final double? aspectRatio = (origWidth != null && origHeight != null && origHeight > 0)
        ? origWidth / origHeight
        : null;

    Widget imageWidget = Image.network(
      src,
      fit: BoxFit.contain,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: context.accentPrimary,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              alt.isNotEmpty ? alt : 'Gambar tidak dapat dimuat',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    if (aspectRatio != null && aspectRatio > 0.3 && aspectRatio < 3.0) {
      imageWidget = AspectRatio(
        aspectRatio: aspectRatio,
        child: imageWidget,
      );
    } else {
      imageWidget = ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380),
        child: imageWidget,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showFullScreenImage(context, src, alt),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      imageWidget,
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (alt.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                alt,
                style: AppFonts.plusJakartaSans(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: textColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Dialog fullscreen dengan pinch-to-zoom (InteractiveViewer) saat gambar disentuh
  void _showFullScreenImage(BuildContext context, String src, String alt) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  src,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
              ),
            ),
            if (alt.isNotEmpty)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alt,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Parsing tag inline menjadi List<TextSpan>
  List<TextSpan> _parseInlineSpans(
    String html, {
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required FontStyle fontStyle,
  }) {
    final List<TextSpan> spans = [];
    final inlinePattern = RegExp(
      r'(<strong>[\s\S]*?<\/strong>|<b>[\s\S]*?<\/b>|<em>[\s\S]*?<\/em>|<i>[\s\S]*?<\/i>|<u>[\s\S]*?<\/u>|<s>[\s\S]*?<\/s>|<del>[\s\S]*?<\/del>|<a[^>]*>[\s\S]*?<\/a>|<code[^>]*>[\s\S]*?<\/code>|<span[^>]*>[\s\S]*?<\/span>|<br\s*\/?>)',
      caseSensitive: false,
    );

    int lastEnd = 0;
    for (final match in inlinePattern.allMatches(html)) {
      if (match.start > lastEnd) {
        final rawSlice = html.substring(lastEnd, match.start);
        final cleanText = _decodeHtmlEntities(_stripUnknownTags(rawSlice));
        if (cleanText.isNotEmpty) {
          spans.add(TextSpan(
            text: cleanText,
            style: AppFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height,
              color: textColor,
              fontStyle: fontStyle,
            ),
          ));
        }
      }

      final tag = match.group(0)!;
      final tagLower = tag.toLowerCase();

      if (tagLower.startsWith('<br')) {
        spans.add(const TextSpan(text: '\n'));
      } else if (tagLower.startsWith('<strong') || tagLower.startsWith('<b>') || tagLower.startsWith('<b ')) {
        final inner = _extractInnerHtml(tag, tagLower.startsWith('<strong') ? 'strong' : 'b');
        final text = _decodeHtmlEntities(_stripUnknownTags(inner));
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: AppFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: height,
              color: textColor,
              fontStyle: fontStyle,
            ),
          ));
        }
      } else if (tagLower.startsWith('<em') || tagLower.startsWith('<i>') || tagLower.startsWith('<i ')) {
        final inner = _extractInnerHtml(tag, tagLower.startsWith('<em') ? 'em' : 'i');
        final text = _decodeHtmlEntities(_stripUnknownTags(inner));
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: AppFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height,
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
          ));
        }
      } else if (tagLower.startsWith('<u>') || tagLower.startsWith('<u ')) {
        final inner = _extractInnerHtml(tag, 'u');
        final text = _decodeHtmlEntities(_stripUnknownTags(inner));
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: AppFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height,
              color: textColor,
              fontStyle: fontStyle,
              decoration: TextDecoration.underline,
            ),
          ));
        }
      } else if (tagLower.startsWith('<s>') || tagLower.startsWith('<del')) {
        final inner = _extractInnerHtml(tag, tagLower.startsWith('<s>') ? 's' : 'del');
        final text = _decodeHtmlEntities(_stripUnknownTags(inner));
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: AppFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height,
              color: textColor.withValues(alpha: 0.6),
              fontStyle: fontStyle,
              decoration: TextDecoration.lineThrough,
            ),
          ));
        }
      } else if (tagLower.startsWith('<code')) {
        final inner = _extractInnerHtml(tag, 'code');
        final text = _decodeHtmlEntities(_stripUnknownTags(inner));
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: ' $text ',
            style: TextStyle(
              fontSize: fontSize * 0.9,
              fontFamily: 'monospace',
              color: const Color(0xFFC7254E),
              backgroundColor: const Color(0xFFF9F2F4),
            ),
          ));
        }
      } else if (tagLower.startsWith('<a')) {
        final inner = _extractInnerHtml(tag, 'a');
        final text = _decodeHtmlEntities(_stripUnknownTags(inner));
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: AppFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height,
              color: const Color(0xFF1565C0),
              decoration: TextDecoration.underline,
            ),
          ));
        }
      } else {
        // Tag lainnya: bersihkan tag dan tampilkan teks dengan style saat ini
        final inner = _stripUnknownTags(tag);
        final text = _decodeHtmlEntities(inner);
        if (text.isNotEmpty) {
          spans.add(TextSpan(
            text: text,
            style: AppFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: height,
              color: textColor,
              fontStyle: fontStyle,
            ),
          ));
        }
      }

      lastEnd = match.end;
    }

    if (lastEnd < html.length) {
      final rawSlice = html.substring(lastEnd);
      final cleanText = _decodeHtmlEntities(_stripUnknownTags(rawSlice));
      if (cleanText.isNotEmpty) {
        spans.add(TextSpan(
          text: cleanText,
          style: AppFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: textColor,
            fontStyle: fontStyle,
          ),
        ));
      }
    }

    if (spans.isEmpty) {
      final plain = _decodeHtmlEntities(_stripUnknownTags(html));
      if (plain.trim().isNotEmpty) {
        spans.add(TextSpan(
          text: plain,
          style: AppFonts.plusJakartaSans(
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: height,
            color: textColor,
            fontStyle: fontStyle,
          ),
        ));
      }
    }

    return spans;
  }

  /// Menghilangkan tag HTML yang tidak dikenal agar tidak bocor sebagai teks mentah
  String _stripUnknownTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]+>'), '');
  }

  String _extractInnerHtml(String tag, String tagName) {
    final pattern = RegExp(
      '<$tagName[^>]*>([\\s\\S]*?)<\\/$tagName>',
      caseSensitive: false,
    );
    return pattern.firstMatch(tag)?.group(1)?.trim() ?? '';
  }

  String _extractAttr(String tag, String attr) {
    final mQuoted = RegExp(
      '\\b$attr\\s*=\\s*["\']([^"\']*)["\']',
      caseSensitive: false,
    ).firstMatch(tag);
    if (mQuoted != null) {
      return mQuoted.group(1)?.trim() ?? '';
    }

    final mUnquoted = RegExp(
      '\\b$attr\\s*=\\s*([^\\s>]+)',
      caseSensitive: false,
    ).firstMatch(tag);
    return mUnquoted?.group(1)?.trim() ?? '';
  }

  String _decodeHtmlEntities(String text) {
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&hellip;', '...')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&bull;', '•')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        .replaceAll('&laquo;', '«')
        .replaceAll('&raquo;', '»');

    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '');
      if (code != null && code > 0 && code < 0x10FFFF) {
        return String.fromCharCode(code);
      }
      return m.group(0)!;
    });

    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '', radix: 16);
      if (code != null && code > 0 && code < 0x10FFFF) {
        return String.fromCharCode(code);
      }
      return m.group(0)!;
    });

    return text;
  }
}
