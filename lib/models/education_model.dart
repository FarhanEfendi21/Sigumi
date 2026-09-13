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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EducationItem({
    required this.id,
    required this.title,
    this.category,
    required this.content,
    this.imageUrl,
    this.lokasi,
    this.createdAt,
    this.updatedAt,
  });

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      category: json['category'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      lokasi: json['lokasi'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
