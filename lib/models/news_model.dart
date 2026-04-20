class NewsModel {
  final String id;
  final String title;
  final String? content;
  final String? imageUrl;
  final String? status;
  final DateTime? createdAt;

  NewsModel({
    required this.id,
    required this.title,
    this.content,
    this.imageUrl,
    this.status,
    this.createdAt,
  });

  /// Convert dari JSON response Supabase
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
    );
  }

  /// Convert ke JSON untuk Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Copy with untuk update data
  NewsModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
