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
