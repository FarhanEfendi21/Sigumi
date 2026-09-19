import 'package:flutter/material.dart';

class EducationSection {
  final String emoji;
  final String title;
  final String description;
  final List<String> bulletPoints;
  final String? funFact;
  final String? warning;

  const EducationSection({
    required this.emoji,
    required this.title,
    required this.description,
    this.bulletPoints = const [],
    this.funFact,
    this.warning,
  });
}

class EducationTopic {
  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
  final Color color;
  final String imagePath;
  final List<EducationSection> sections;

  const EducationTopic({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.imagePath,
    required this.sections,
  });
}

class EducationItem {
  final String id;
  final String title;
  final String? category;
  final String content;
  final String? imageUrl;
  final String? lokasi;
  final String? audience;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EducationItem({
    required this.id,
    required this.title,
    this.category,
    required this.content,
    this.imageUrl,
    this.lokasi,
    this.audience,
    this.createdAt,
    this.updatedAt,
  });

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      id: json['id'] as String,
      title: _stripHtml(json['title'] as String? ?? ''),
      category: json['category'] != null
          ? _stripHtml(json['category'] as String)
          : null,
      content: _stripHtml(json['content'] as String? ?? ''),
      imageUrl: json['image_url'] as String?,
      lokasi: json['lokasi'] as String?,
      audience: json['audience'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  static String _stripHtml(String html) {
    if (html.isEmpty) return '';
    String text = html;
    // Replace breaks and paragraph/block closing tags with newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(
        RegExp(r'</?(p|div|li|h[1-6])\b[^>]*>', caseSensitive: false), '\n');
    // Strip all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    // Decode common HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    // Normalize newlines and whitespace
    text = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n');
    return text.trim();
  }
}
