/// Model data untuk agenda/event kegiatan wisata.
class TourismEvent {
  final String id;
  final String? destinationId;
  final String region;
  final String title;
  final String description;
  final String eventType; // 'Festival', 'Pertunjukan', 'Ritual', 'Pameran'
  final DateTime startDate;
  final DateTime? endDate;
  final String? time; // e.g. '18.00 WITA'
  final String locationName;
  final int price; // 0 = gratis
  final bool isRecurring; // true = event rutin (bukan tanggal tetap)

  const TourismEvent({
    required this.id,
    this.destinationId,
    required this.region,
    required this.title,
    required this.description,
    required this.eventType,
    required this.startDate,
    this.endDate,
    this.time,
    required this.locationName,
    this.price = 0,
    this.isRecurring = false,
  });

  factory TourismEvent.fromJson(Map<String, dynamic> json) {
    return TourismEvent(
      id: json['id']?.toString() ?? '',
      destinationId: json['destination_id']?.toString(),
      region: json['region'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      eventType: json['event_type'] ?? 'Festival',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      time: json['time'],
      locationName: json['location_name'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      isRecurring: json['is_recurring'] ?? false,
    );
  }

  /// Apakah event masih akan datang atau sedang berlangsung
  bool get isUpcoming {
    final now = DateTime.now();
    final end = endDate ?? startDate;
    return end.isAfter(now) || isRecurring;
  }

  /// Hitung sisa hari hingga event dimulai
  int get daysUntilEvent {
    if (isRecurring) return 0;
    final now = DateTime.now();
    final diff = startDate.difference(DateTime(now.year, now.month, now.day));
    return diff.inDays < 0 ? 0 : diff.inDays;
  }

  /// Label countdown yang informatif
  String get countdownLabel {
    if (isRecurring) return 'Rutin';
    final days = daysUntilEvent;
    if (days == 0) return 'Hari ini';
    if (days == 1) return 'Besok';
    if (days <= 7) return '$days hari lagi';
    return '$days hari lagi';
  }

  /// Format harga yang readable
  String get formattedPrice {
    if (price == 0) return 'Gratis';
    if (price >= 1000) {
      return 'Rp ${(price / 1000).toStringAsFixed(0)}.000';
    }
    return 'Rp $price';
  }

  // ── Mock Data ──────────────────────────────────────────────

  static List<TourismEvent> mockYogyakarta() {
    final now = DateTime.now();
    return [
      TourismEvent(
        id: 'ev-yk-1',
        region: 'Yogyakarta',
        title: 'Sekaten',
        description:
            'Perayaan Maulid Nabi Muhammad SAW dengan pasar malam, gamelan sekaten, dan iring-iringan grebeg yang meriah di alun-alun Keraton.',
        eventType: 'Festival',
        startDate: DateTime(now.year, now.month + 1, 5),
        endDate: DateTime(now.year, now.month + 1, 12),
        time: '09.00 - 22.00 WIB',
        locationName: 'Alun-alun Utara Keraton Yogyakarta',
        price: 0,
        isRecurring: false,
      ),
      TourismEvent(
        id: 'ev-yk-2',
        region: 'Yogyakarta',
        title: 'Sendratari Ramayana',
        description:
            'Pertunjukan tari Ramayana dengan latar belakang Candi Prambanan yang megah. Cerita epik yang dipersembahkan oleh ratusan penari terlatih.',
        eventType: 'Pertunjukan',
        startDate: DateTime(now.year, now.month, now.day + 3),
        time: '19.30 WIB',
        locationName: 'Panggung Terbuka Prambanan',
        price: 125000,
        isRecurring: true,
      ),
      TourismEvent(
        id: 'ev-yk-3',
        region: 'Yogyakarta',
        title: 'Karnaval Malioboro',
        description:
            'Parade budaya tahunan yang meriah di sepanjang Jalan Malioboro dengan kostum tradisional, musik gamelan, dan tarian daerah.',
        eventType: 'Festival',
        startDate: DateTime(now.year, now.month, now.day + 10),
        time: '15.00 - 21.00 WIB',
        locationName: 'Jalan Malioboro, Yogyakarta',
        price: 0,
        isRecurring: false,
      ),
    ];
  }

  static List<TourismEvent> mockBali() {
    final now = DateTime.now();
    return [
      TourismEvent(
        id: 'ev-bl-1',
        region: 'Bali',
        title: 'Tari Kecak Uluwatu',
        description:
            'Pertunjukan tari Kecak dramatis dengan latar matahari terbenam di tepi tebing Pura Uluwatu. Menceritakan kisah Ramayana tanpa musik, hanya suara "cak" ratusan penari.',
        eventType: 'Pertunjukan',
        startDate: DateTime(now.year, now.month, now.day + 1),
        time: '18.00 WITA',
        locationName: 'Pura Uluwatu, Badung',
        price: 100000,
        isRecurring: true,
      ),
      TourismEvent(
        id: 'ev-bl-2',
        region: 'Bali',
        title: 'Nyepi — Hari Raya Senyap',
        description:
            'Tahun Baru Saka yang dirayakan dengan keheningan total selama 24 jam. Sehari sebelumnya, parade Ogoh-Ogoh raksasa mengelilingi desa.',
        eventType: 'Ritual',
        startDate: DateTime(now.year + 1, 3, 20),
        time: '06.00 WITA (24 jam)',
        locationName: 'Seluruh Bali',
        price: 0,
        isRecurring: false,
      ),
      TourismEvent(
        id: 'ev-bl-3',
        region: 'Bali',
        title: 'Festival Seni Ubud',
        description:
            'Festival seni dan budaya bergengsi tahunan di Ubud dengan pertunjukan tari, musik tradisional, pameran lukisan, dan workshop seni.',
        eventType: 'Festival',
        startDate: DateTime(now.year, now.month, now.day + 14),
        endDate: DateTime(now.year, now.month, now.day + 21),
        time: '10.00 - 22.00 WITA',
        locationName: 'Ubud Palace & Arjuna Stage',
        price: 50000,
        isRecurring: false,
      ),
    ];
  }

  static List<TourismEvent> mockLombok() {
    final now = DateTime.now();
    return [
      TourismEvent(
        id: 'ev-lbk-1',
        region: 'Lombok',
        title: 'Festival Bau Nyale',
        description:
            'Ritual tahunan Suku Sasak menangkap cacing nyale (cacing laut) di pantai selatan Lombok. Diiringi atraksi presean (silat Sasak) dan hiburan tradisional.',
        eventType: 'Festival',
        startDate: DateTime(now.year + 1, 2, 19),
        time: '03.00 WITA',
        locationName: 'Pantai Seger, Mandalika',
        price: 0,
        isRecurring: false,
      ),
      TourismEvent(
        id: 'ev-lbk-2',
        region: 'Lombok',
        title: 'Pertunjukan Gendang Beleq',
        description:
            'Pertunjukan musik tradisional Lombok dengan gendang raksasa (beleq) yang biasanya mengiringi upacara adat, perang, dan pernikahan Sasak.',
        eventType: 'Pertunjukan',
        startDate: DateTime(now.year, now.month, now.day + 5),
        time: '16.00 WITA',
        locationName: 'Desa Sade, Lombok Tengah',
        price: 0,
        isRecurring: true,
      ),
      TourismEvent(
        id: 'ev-lbk-3',
        region: 'Lombok',
        title: 'Lombok Sumbawa Expo',
        description:
            'Pameran produk unggulan, kuliner, dan kerajinan tangan dari Lombok dan Sumbawa. Ajang promosi wisata dan investasi daerah.',
        eventType: 'Pameran',
        startDate: DateTime(now.year, now.month, now.day + 20),
        endDate: DateTime(now.year, now.month, now.day + 27),
        time: '09.00 - 21.00 WITA',
        locationName: 'Lombok Epicentrum Mall',
        price: 0,
        isRecurring: false,
      ),
    ];
  }

  static List<TourismEvent> byRegion(String region) {
    switch (region) {
      case 'Bali':
        return mockBali();
      case 'Lombok':
        return mockLombok();
      default:
        return mockYogyakarta();
    }
  }
}
