class ReportModel {
  final String id;
  final String reporterName;
  final String? phone;
  final String category;
  final String title;
  final String description;
  final String? location;
  final String? imageUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ReportModel({
    required this.id,
    required this.reporterName,
    required this.category,
    required this.title,
    required this.description,
    this.phone,
    this.location,
    this.imageUrl,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  /// Convert dari JSON (Supabase response)
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterName: json['reporter_name'] as String,
      phone: json['phone'] as String?,
      category: json['category'] as String? ?? 'umum',
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  /// Convert ke JSON untuk upload ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_name': reporterName,
      'phone': phone,
      'category': category,
      'title': title,
      'description': description,
      'location': location,
      'image_url': imageUrl,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Status label untuk UI
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  /// Kategori laporan yang tersedia
  static List<String> get categories => [
    'Guguran Lava',
    'Hujan Abu',
    'Lahar Dingin',
    'Lahar Panas',
    'Getaran/Gempa',
    'Banjir Lahar',
    'Kerusakan Infrastruktur',
    'Kebutuhan Evakuasi',
    'Lainnya',
  ];

  @override
  String toString() =>
      'ReportModel(id: $id, reporterName: $reporterName, category: $category, status: $status)';
}
