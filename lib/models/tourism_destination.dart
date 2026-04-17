/// Model data untuk destinasi wisata.
class TourismDestination {
  final String id;
  final String region;
  final String name;
  final String category; // 'Alam', 'Budaya', 'Pantai', 'Kuliner'
  final String description;
  final String address;
  final double? lat;
  final double? lng;
  final String? photoUrl;
  final int entryFee; // dalam rupiah, 0 = gratis
  final String openHours;
  final double rating;

  const TourismDestination({
    required this.id,
    required this.region,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    this.lat,
    this.lng,
    this.photoUrl,
    this.entryFee = 0,
    this.openHours = '08.00 - 17.00',
    this.rating = 4.5,
  });

  factory TourismDestination.fromJson(Map<String, dynamic> json) {
    return TourismDestination(
      id: json['id']?.toString() ?? '',
      region: json['region'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Alam',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      photoUrl: json['photo_url'],
      entryFee: (json['entry_fee'] as num?)?.toInt() ?? 0,
      openHours: json['open_hours'] ?? '08.00 - 17.00',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
    );
  }

  /// Format harga tiket yang readable
  String get formattedFee {
    if (entryFee == 0) return 'Gratis';
    if (entryFee >= 1000) {
      return 'Rp ${(entryFee / 1000).toStringAsFixed(0)}.000';
    }
    return 'Rp $entryFee';
  }

  // ── Mock Data ──────────────────────────────────────────────

  static List<TourismDestination> mockYogyakarta() => [
        const TourismDestination(
          id: 'yk-1',
          region: 'Yogyakarta',
          name: 'Candi Borobudur',
          category: 'Budaya',
          description:
              'Candi Buddha terbesar di dunia, dibangun pada abad ke-8 oleh Dinasti Syailendra. '
              'Situs Warisan Dunia UNESCO yang menjadi kebanggaan Indonesia dengan arsitektur stupa yang megah dan relief yang menakjubkan.',
          address: 'Jl. Badrawati, Borobudur, Magelang, Jawa Tengah',
          lat: -7.6079,
          lng: 110.2038,
          entryFee: 50000,
          openHours: '06.00 - 17.00',
          rating: 4.9,
        ),
        const TourismDestination(
          id: 'yk-2',
          region: 'Yogyakarta',
          name: 'Candi Prambanan',
          category: 'Budaya',
          description:
              'Kompleks candi Hindu terbesar di Indonesia, didedikasikan untuk Trimurti: Brahma, Wisnu, dan Siwa. '
              'Terletak di perbatasan Yogyakarta dan Jawa Tengah dengan arsitektur yang menawan.',
          address: 'Jl. Raya Solo - Yogyakarta, Prambanan, Sleman',
          lat: -7.7520,
          lng: 110.4914,
          entryFee: 50000,
          openHours: '06.00 - 17.00',
          rating: 4.8,
        ),
        const TourismDestination(
          id: 'yk-3',
          region: 'Yogyakarta',
          name: 'Pantai Parangtritis',
          category: 'Pantai',
          description:
              'Pantai ikonik Yogyakarta dengan pasir hitam dan ombak yang besar. '
              'Dikenal dengan legenda Nyi Roro Kidul dan pemandangan matahari terbenam yang memukau.',
          address: 'Parangtritis, Kretek, Bantul, Yogyakarta',
          lat: -8.0257,
          lng: 110.3325,
          entryFee: 10000,
          openHours: '24 Jam',
          rating: 4.5,
        ),
        const TourismDestination(
          id: 'yk-4',
          region: 'Yogyakarta',
          name: 'Malioboro',
          category: 'Kuliner',
          description:
              'Jantung kota Yogyakarta — pusat perbelanjaan, kuliner, dan budaya. '
              'Nikmati gudeg, bakpia, dan berbagai kuliner khas Jogja sambil menikmati suasana kota yang hidup.',
          address: 'Jl. Malioboro, Gedong Tengen, Yogyakarta',
          lat: -7.7929,
          lng: 110.3659,
          entryFee: 0,
          openHours: '24 Jam',
          rating: 4.7,
        ),
        const TourismDestination(
          id: 'yk-5',
          region: 'Yogyakarta',
          name: 'Gunung Merapi Tour',
          category: 'Alam',
          description:
              'Wisata jeep off-road mengelilingi sisi gunung berapi paling aktif di Indonesia. '
              'Saksikan sisa-sisa erupsi 2010, lava tour malam hari, dan pemandangan Merapi dari dekat.',
          address: 'Kaliurang, Pakem, Sleman, Yogyakarta',
          lat: -7.5407,
          lng: 110.4457,
          entryFee: 300000,
          openHours: '05.00 - 17.00',
          rating: 4.8,
        ),
      ];

  static List<TourismDestination> mockBali() => [
        const TourismDestination(
          id: 'bl-1',
          region: 'Bali',
          name: 'Pura Tanah Lot',
          category: 'Budaya',
          description:
              'Pura Hindu yang berdiri di atas batu karang di tengah laut. '
              'Salah satu objek wisata paling ikonik di Bali dengan pemandangan matahari terbenam yang spektakuler.',
          address: 'Beraban, Kediri, Tabanan, Bali',
          lat: -8.6211,
          lng: 115.0868,
          entryFee: 60000,
          openHours: '07.00 - 19.00',
          rating: 4.8,
        ),
        const TourismDestination(
          id: 'bl-2',
          region: 'Bali',
          name: 'Tegalalang Rice Terrace',
          category: 'Alam',
          description:
              'Sawah terasering yang indah di dataran tinggi Ubud. '
              'UNESCO mengakui subak (sistem irigasi tradisional Bali) sebagai Warisan Budaya Dunia.',
          address: 'Tegallalang, Gianyar, Bali',
          lat: -8.4312,
          lng: 115.2786,
          entryFee: 15000,
          openHours: '08.00 - 18.00',
          rating: 4.6,
        ),
        const TourismDestination(
          id: 'bl-3',
          region: 'Bali',
          name: 'Pantai Kuta',
          category: 'Pantai',
          description:
              'Pantai paling terkenal di Bali dengan hamparan pasir putih dan ombak yang cocok untuk surfing. '
              'Ramai dengan wisatawan, pedagang, dan kehidupan malam yang meriah.',
          address: 'Kuta, Badung, Bali',
          lat: -8.7184,
          lng: 115.1686,
          entryFee: 0,
          openHours: '24 Jam',
          rating: 4.5,
        ),
        const TourismDestination(
          id: 'bl-4',
          region: 'Bali',
          name: 'Pura Uluwatu',
          category: 'Budaya',
          description:
              'Pura suci di tepi tebing setinggi 70 meter di ujung selatan Bali. '
              'Terkenal dengan pertunjukan Tari Kecak saat matahari terbenam yang memukau.',
          address: 'Pecatu, Kuta Selatan, Badung, Bali',
          lat: -8.8291,
          lng: 115.0849,
          entryFee: 50000,
          openHours: '09.00 - 19.00',
          rating: 4.9,
        ),
        const TourismDestination(
          id: 'bl-5',
          region: 'Bali',
          name: 'Ubud Monkey Forest',
          category: 'Alam',
          description:
              'Hutan suci seluas 12,5 hektar yang dihuni ratusan monyet ekor panjang. '
              'Terdapat tiga pura kuno di dalamnya dengan nuansa mistis dan asri.',
          address: 'Jl. Monkey Forest, Ubud, Gianyar, Bali',
          lat: -8.5188,
          lng: 115.2592,
          entryFee: 80000,
          openHours: '09.00 - 17.30',
          rating: 4.6,
        ),
      ];

  static List<TourismDestination> mockLombok() => [
        const TourismDestination(
          id: 'lbk-1',
          region: 'Lombok',
          name: 'Pantai Mandalika',
          category: 'Pantai',
          description:
              'Kawasan wisata premium di selatan Lombok dengan pantai pasir putih yang panjang. '
              'Tuan rumah MotoGP Mandalika Circuit, menjadikannya destinasi kelas dunia.',
          address: 'Kuta, Pujut, Lombok Tengah, NTB',
          lat: -8.8836,
          lng: 116.2955,
          entryFee: 10000,
          openHours: '24 Jam',
          rating: 4.8,
        ),
        const TourismDestination(
          id: 'lbk-2',
          region: 'Lombok',
          name: 'Gili Trawangan',
          category: 'Pantai',
          description:
              'Pulau kecil paling populer dari Tiga Gili di Lombok Barat. '
              'Bebas kendaraan bermotor, kaya terumbu karang, dan destinasi favorit snorkeling & diving.',
          address: 'Gili Indah, Pemenang, Lombok Utara, NTB',
          lat: -8.3529,
          lng: 116.0247,
          entryFee: 0,
          openHours: '24 Jam',
          rating: 4.7,
        ),
        const TourismDestination(
          id: 'lbk-3',
          region: 'Lombok',
          name: 'Air Terjun Sendang Gile',
          category: 'Alam',
          description:
              'Air terjun bertingkat yang menakjubkan di kaki Gunung Rinjani. '
              'Dua air terjun bertumpuk dengan pemandangan hutan tropis yang hijau dan menyejukkan.',
          address: 'Senaru, Bayan, Lombok Utara, NTB',
          lat: -8.3211,
          lng: 116.4247,
          entryFee: 10000,
          openHours: '07.00 - 17.00',
          rating: 4.7,
        ),
        const TourismDestination(
          id: 'lbk-4',
          region: 'Lombok',
          name: 'Desa Sade',
          category: 'Budaya',
          description:
              'Desa adat Suku Sasak yang masih mempertahankan tradisi leluhur. '
              'Rumah tradisional dari lumpur kerbau, tenun Sasak, dan tarian tradisional yang autentik.',
          address: 'Rembitan, Pujut, Lombok Tengah, NTB',
          lat: -8.8471,
          lng: 116.2637,
          entryFee: 0,
          openHours: '08.00 - 17.00',
          rating: 4.5,
        ),
        const TourismDestination(
          id: 'lbk-5',
          region: 'Lombok',
          name: 'Gunung Rinjani',
          category: 'Alam',
          description:
              'Gunung berapi aktif tertinggi kedua di Indonesia (3.726 mdpl). '
              'Surga para pendaki dengan danau kawah Segara Anak yang indah dan panorama 360 derajat yang luar biasa.',
          address: 'Sembalun, Lombok Timur, NTB',
          lat: -8.4111,
          lng: 116.4573,
          entryFee: 150000,
          openHours: '05.00 - 17.00',
          rating: 4.9,
        ),
      ];

  static List<TourismDestination> byRegion(String region) {
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
