import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edukasi Bencana'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Umum', icon: Icon(Icons.menu_book, size: 18)),
              Tab(text: 'Anak-Anak', icon: Icon(Icons.child_care, size: 18)),
              Tab(text: 'Difabel', icon: Icon(Icons.accessibility_new, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GeneralEducation(),
            _ChildrenEducation(),
            _DisabilityEducation(),
          ],
        ),
      ),
    );
  }
}

class _GeneralEducation extends StatelessWidget {
  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Sebelum Erupsi',
      'icon': Icons.schedule,
      'color': SigumiTheme.statusWaspada,
      'items': [
        'Kenali tanda-tanda erupsi: gempa vulkanik, suara gemuruh, bau belerang menyengat',
        'Siapkan tas siaga berisi dokumen, obat, air, makanan, masker, senter, radio',
        'Hafal jalur evakuasi terdekat dari rumah Anda',
        'Simpan nomor darurat BNPB (117) dan BPBD daerah',
        'Ikuti briefing dari petugas BPBD setempat',
        'Pastikan kendaraan siap digunakan dengan bahan bakar penuh',
      ],
    },
    {
      'title': 'Saat Erupsi',
      'icon': Icons.warning_amber,
      'color': SigumiTheme.statusAwas,
      'items': [
        'SEGERA evakuasi mengikuti jalur resmi BPBD',
        'Gunakan masker atau kain basah untuk menutup hidung dan mulut',
        'Lindungi kepala dari material jatuhan',
        'Jauhi lembah dan aliran sungai dari arah gunung',
        'Jangan kembali ke zona bahaya meskipun letusan mereda',
        'Tetap pantau informasi dari BMKG dan PVMBG',
      ],
    },
    {
      'title': 'Sesudah Erupsi',
      'icon': Icons.health_and_safety,
      'color': SigumiTheme.statusNormal,
      'items': [
        'Tunggu arahan resmi sebelum kembali ke rumah',
        'Bersihkan abu vulkanik dari atap (risiko runtuh)',
        'Periksa sumber air sebelum dikonsumsi',
        'Waspadai aliran lahar dingin saat hujan',
        'Pantau kondisi kesehatan, terutama gangguan pernapasan',
        'Laporkan kerusakan ke BPBD untuk pendataan',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'] as IconData,
                  color: item['color'] as Color, size: 22),
            ),
            title: Text(
              item['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            initiallyExpanded: index == 0,
            children: (item['items'] as List<String>).asMap().entries.map((e) {
              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      (item['color'] as Color).withOpacity(0.1),
                  child: Text(
                    '${e.key + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item['color'] as Color,
                    ),
                  ),
                ),
                title: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.4)),
                dense: true,
              );
            }).toList(),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: 400.ms,
            );
      },
    );
  }
}

class _ChildrenEducation extends StatelessWidget {
  final List<Map<String, dynamic>> _cards = [
    {
      'emoji': '🌋',
      'title': 'Apa itu Gunung Berapi?',
      'desc':
          'Gunung berapi adalah gunung yang bisa mengeluarkan lava panas, abu, dan gas dari dalam bumi. Seperti bumi sedang "batuk"!',
      'color': Colors.orange,
    },
    {
      'emoji': '⚠️',
      'title': 'Tanda-tanda Bahaya',
      'desc':
          'Jika tanah bergetar, terdengar suara keras dari gunung, atau tercium bau seperti telur busuk, segera beritahu orang dewasa!',
      'color': Colors.red,
    },
    {
      'emoji': '🏃',
      'title': 'Apa yang Harus Dilakukan?',
      'desc':
          'Ikuti arahan orang tua atau guru. Jangan panik! Lari menjauhi gunung, bukan mendekat. Gunakan masker atau tutup hidung dengan kain.',
      'color': Colors.blue,
    },
    {
      'emoji': '🎒',
      'title': 'Tas Siaga Kamu',
      'desc':
          'Siapkan tas berisi: botol air, makanan ringan, baju ganti, senter, dan obat-obatan. Simpan di tempat yang mudah dijangkau.',
      'color': Colors.green,
    },
    {
      'emoji': '📞',
      'title': 'Nomor Penting',
      'desc':
          'Hafal nomor telepon orang tua dan nomor darurat 117 (BNPB). Jika terpisah, minta bantuan petugas berseragam.',
      'color': Colors.purple,
    },
    {
      'emoji': '🤝',
      'title': 'Bantu Teman',
      'desc':
          'Jika temanmu takut, pegang tangannya dan bilang "Jangan takut, kita pasti selamat." Tetap tenang dan saling membantu.',
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (card['color'] as Color).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: (card['color'] as Color).withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card['emoji'] as String,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: card['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card['desc'] as String,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: 400.ms,
            );
      },
    );
  }
}

class _DisabilityEducation extends StatelessWidget {
  final List<Map<String, dynamic>> _items = [
    {
      'icon': Icons.hearing,
      'title': 'Gangguan Pendengaran',
      'tips': [
        'Aktifkan notifikasi visual (lampu berkedip) untuk peringatan',
        'Gunakan aplikasi SIGUMI dengan mode visual penuh',
        'Siapkan teman/keluarga yang bisa memberikan isyarat bahaya',
        'Pasang alarm getar di samping tempat tidur',
      ],
    },
    {
      'icon': Icons.visibility_off,
      'title': 'Gangguan Penglihatan',
      'tips': [
        'Aktifkan audio guidance di pengaturan SIGUMI',
        'Hafal jalur evakuasi dengan cara meraba jalur',
        'Siapkan tongkat dan perlengkapan pribadi dalam tas siaga',
        'Minta pendamping saat evakuasi',
      ],
    },
    {
      'icon': Icons.accessible,
      'title': 'Pengguna Kursi Roda',
      'tips': [
        'Kenali jalur evakuasi yang ramah kursi roda',
        'Siapkan rencana evakuasi dengan bantuan orang lain',
        'Koordinasi dengan tim SAR tentang kebutuhan mobilitas',
        'Pastikan kursi roda dalam kondisi baik dan siap digunakan',
      ],
    },
    {
      'icon': Icons.elderly,
      'title': 'Lansia',
      'tips': [
        'Aktifkan audio panduan di SIGUMI dengan suara jelas',
        'Siapkan obat-obatan rutin dalam tas siaga',
        'Koordinasi dengan tetangga untuk bantuan evakuasi',
        'Simpan informasi medis penting di dompet',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SigumiTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'] as IconData,
                  color: SigumiTheme.primaryBlue, size: 22),
            ),
            title: Text(
              item['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            initiallyExpanded: index == 0,
            children: (item['tips'] as List<String>)
                .map((tip) => ListTile(
                      leading: const Icon(Icons.check_circle,
                          color: SigumiTheme.statusNormal, size: 18),
                      title: Text(tip, style: const TextStyle(fontSize: 13)),
                      dense: true,
                    ))
                .toList(),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: 400.ms,
            );
      },
    );
  }
}
