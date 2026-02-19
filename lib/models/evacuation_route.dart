class EvacuationRoute {
  final String id;
  final String name;
  final String description;
  final double distance;
  final int estimatedMinutes;
  final double safetyScore;
  final String congestionLevel;
  final List<String> waypoints;
  final bool isRecommended;

  EvacuationRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.distance,
    required this.estimatedMinutes,
    required this.safetyScore,
    required this.congestionLevel,
    this.waypoints = const [],
    this.isRecommended = false,
  });

  static List<EvacuationRoute> mockRoutes() {
    return [
      EvacuationRoute(
        id: 'route_1',
        name: 'Jalur Selatan - Pakem ke Stadion Maguwoharjo',
        description: 'Melalui Jl. Kaliurang → Jl. Ring Road Utara → Stadion Maguwoharjo. Jalur utama dengan akses kendaraan lebar.',
        distance: 18.5,
        estimatedMinutes: 35,
        safetyScore: 0.92,
        congestionLevel: 'Rendah',
        waypoints: ['Pakem', 'Jl. Kaliurang KM8', 'Jl. Ring Road Utara', 'Stadion Maguwoharjo'],
        isRecommended: true,
      ),
      EvacuationRoute(
        id: 'route_2',
        name: 'Jalur Barat - Turi ke Sleman Kota',
        description: 'Melalui Jl. Magelang → Sleman Kota. Jalur alternatif jika jalur selatan padat.',
        distance: 22.0,
        estimatedMinutes: 45,
        safetyScore: 0.85,
        congestionLevel: 'Sedang',
        waypoints: ['Turi', 'Tempel', 'Jl. Magelang', 'Sleman Kota'],
      ),
      EvacuationRoute(
        id: 'route_3',
        name: 'Jalur Timur - Dukun ke Muntilan',
        description: 'Melalui Dukun → Sawangan → Muntilan. Cocok untuk warga lereng timur.',
        distance: 15.0,
        estimatedMinutes: 30,
        safetyScore: 0.78,
        congestionLevel: 'Rendah',
        waypoints: ['Dukun', 'Sawangan', 'Muntilan'],
      ),
      EvacuationRoute(
        id: 'route_4',
        name: 'Jalur Tenggara - Cangkringan ke Prambanan',
        description: 'Melalui Cangkringan → Kalasan → Prambanan. Jalur evakuasi zona tenggara.',
        distance: 25.0,
        estimatedMinutes: 50,
        safetyScore: 0.72,
        congestionLevel: 'Tinggi',
        waypoints: ['Cangkringan', 'Kalasan', 'Prambanan'],
      ),
    ];
  }
}
