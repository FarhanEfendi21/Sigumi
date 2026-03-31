import 'package:flutter/material.dart';

enum NewsCategory { erupsi, gempa, status, evakuasi, info }

class NewsItem {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String source;
  final DateTime publishedAt;
  final NewsCategory category;

  const NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.source,
    required this.publishedAt,
    required this.category,
  });

  IconData get categoryIcon {
    switch (category) {
      case NewsCategory.erupsi:
        return Icons.volcano;
      case NewsCategory.gempa:
        return Icons.vibration;
      case NewsCategory.status:
        return Icons.info_outline;
      case NewsCategory.evakuasi:
        return Icons.directions_run;
      case NewsCategory.info:
        return Icons.newspaper;
    }
  }

  Color get categoryColor {
    switch (category) {
      case NewsCategory.erupsi:
        return const Color(0xFFF44336);
      case NewsCategory.gempa:
        return const Color(0xFFFF9800);
      case NewsCategory.status:
        return const Color(0xFF2196F3);
      case NewsCategory.evakuasi:
        return const Color(0xFF4CAF50);
      case NewsCategory.info:
        return const Color(0xFF9C27B0);
    }
  }

  String get categoryLabel {
    switch (category) {
      case NewsCategory.erupsi:
        return 'Erupsi';
      case NewsCategory.gempa:
        return 'Gempa';
      case NewsCategory.status:
        return 'Status';
      case NewsCategory.evakuasi:
        return 'Evakuasi';
      case NewsCategory.info:
        return 'Info';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${(diff.inDays / 7).floor()} minggu lalu';
    }
  }

  static List<NewsItem> mockNews() {
    final now = DateTime.now();
    return [
      NewsItem(
        id: 'news_001',
        title: 'Guguran Lava Pijar Merapi Meluncur 1.8 Km ke Barat Daya',
        summary:
            'BPPTKG melaporkan guguran lava pijar teramati meluncur sejauh 1.8 km ke arah barat daya Gunung Merapi pada dini hari tadi.',
        content:
            'Balai Penyelidikan dan Pengembangan Teknologi Kebencanaan Geologi (BPPTKG) melaporkan guguran lava pijar Gunung Merapi teramati pada pukul 02.15 WIB dini hari tadi. Guguran meluncur sejauh 1.8 km ke arah barat daya menuju hulu Kali Bebeng.\n\nMenurut Kepala BPPTKG, aktivitas ini masih dalam batas normal untuk level Waspada (Level II). Masyarakat diminta tetap waspada dan tidak beraktivitas dalam radius 3 km dari puncak Gunung Merapi.\n\nVolume kubah lava saat ini diperkirakan mencapai 2.7 juta meter kubik. Potensi guguran lava dan awan panas masih mungkin terjadi terutama ke arah barat daya.',
        source: 'BPPTKG',
        publishedAt: now.subtract(const Duration(hours: 2)),
        category: NewsCategory.erupsi,
      ),
      NewsItem(
        id: 'news_002',
        title: 'Tercatat 45 Kali Gempa Guguran dalam 24 Jam Terakhir',
        summary:
            'Pos Pengamatan Gunung Merapi mencatat 45 kali gempa guguran dan 12 kali gempa vulkanik dalam periode pengamatan terakhir.',
        content:
            'Pos Pengamatan Gunung Merapi (PGM) Babadan mencatat peningkatan aktivitas seismik dalam 24 jam terakhir. Tercatat 45 kali gempa guguran, 12 kali gempa vulkanik dalam (VTA), dan 3 kali gempa tektonik lokal.\n\nKepala Seksi Mitigasi Gunung Api menjelaskan bahwa peningkatan gempa guguran berkorelasi dengan aktivitas ekstrusi lava di kubah lava Merapi. Gempa vulkanik dalam menunjukkan adanya pergerakan magma di kedalaman.\n\nMasyarakat di wilayah radius 3-5 km diminta tetap memantau informasi resmi dan menyiapkan rencana evakuasi.',
        source: 'PVMBG',
        publishedAt: now.subtract(const Duration(hours: 5)),
        category: NewsCategory.gempa,
      ),
      NewsItem(
        id: 'news_003',
        title: 'Status Merapi Tetap Waspada Level II',
        summary:
            'PVMBG memutuskan status Gunung Merapi tetap pada level Waspada (Level II) setelah evaluasi rutin mingguan.',
        content:
            'Pusat Vulkanologi dan Mitigasi Bencana Geologi (PVMBG) memutuskan untuk mempertahankan status Gunung Merapi pada Level II (Waspada) setelah melakukan evaluasi rutin mingguan.\n\nMeskipun terjadi peningkatan aktivitas seismik dan guguran lava, parameter keseluruhan masih berada dalam batas Level II. Deformasi tubuh gunung menunjukkan tren inflasi yang belum signifikan.\n\nRekomendasi: Masyarakat dilarang beraktivitas dalam radius 3 km dari puncak. Potensi bahaya utama berupa guguran lava, awan panas guguran, dan lahar hujan di sungai-sungai yang berhulu di Merapi.',
        source: 'PVMBG',
        publishedAt: now.subtract(const Duration(hours: 12)),
        category: NewsCategory.status,
      ),
      NewsItem(
        id: 'news_004',
        title: 'BPBD Sleman Gelar Simulasi Evakuasi di Desa Cangkringan',
        summary:
            'BPBD Kabupaten Sleman menggelar simulasi evakuasi mandiri bersama warga di tiga desa rawan bencana Gunung Merapi.',
        content:
            'Badan Penanggulangan Bencana Daerah (BPBD) Kabupaten Sleman bersama FPRB (Forum Pengurangan Risiko Bencana) menggelar simulasi evakuasi mandiri di Desa Cangkringan, Kepuharjo, dan Glagaharjo.\n\nSimulasi ini melibatkan sekitar 500 warga dan mencakup skenario erupsi eksplosif Level IV (Awas). Jalur evakuasi menuju Barak Pengungsian di Stadion Maguwoharjo telah diuji dan berjalan lancar.\n\nKepala BPBD Sleman mengingatkan warga untuk selalu menyiapkan tas siaga bencana (go bag) berisi dokumen penting, obat-obatan, pakaian ganti, dan makanan ringan.\n\nJadwal simulasi berikutnya akan dilaksanakan pada bulan depan di wilayah Kecamatan Turi dan Pakem.',
        source: 'BPBD Sleman',
        publishedAt: now.subtract(const Duration(days: 1)),
        category: NewsCategory.evakuasi,
      ),
      NewsItem(
        id: 'news_005',
        title: 'BMKG: Cuaca Cerah Berawan, Waspadai Lahar Hujan Sore Hari',
        summary:
            'BMKG memprakirakan cuaca di wilayah Merapi cerah berawan pagi hari dengan potensi hujan ringan-sedang sore hingga malam.',
        content:
            'Badan Meteorologi, Klimatologi, dan Geofisika (BMKG) Stasiun Klimatologi Yogyakarta memprakirakan kondisi cuaca di wilayah lereng Gunung Merapi cerah berawan pada pagi hingga siang hari.\n\nNamun, potensi hujan ringan hingga sedang diperkirakan terjadi pada sore hingga malam hari. Masyarakat di bantaran sungai yang berhulu di Merapi diminta mewaspadai potensi lahar hujan.\n\nSungai-sungai yang perlu diwaspadai antara lain: Kali Gendol, Kali Kuning, Kali Boyong, Kali Bebeng, dan Kali Putih. Masyarakat diimbau untuk segera menjauhi bantaran sungai apabila hujan deras terjadi di kawasan puncak Merapi.',
        source: 'BMKG',
        publishedAt: now.subtract(const Duration(days: 1, hours: 6)),
        category: NewsCategory.info,
      ),
    ];
  }
}
