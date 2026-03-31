import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

class PostDisasterScreen extends StatelessWidget {
  const PostDisasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Penanganan Pasca Bencana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Important notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SigumiTheme.statusAwas.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SigumiTheme.statusAwas.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: SigumiTheme.statusAwas, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Jangan kembali ke rumah sebelum ada arahan resmi dari BPBD/BNPB. Keselamatan Anda adalah prioritas utama.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 20),

            _Section(
              icon: Icons.checklist,
              title: 'Checklist Kembali ke Rumah',
              color: Colors.blue,
              items: const [
                'Pastikan status bahaya sudah diturunkan oleh BPBD',
                'Periksa struktur bangunan: retakan, kemiringan, fondasi',
                'Bersihkan abu vulkanik dari atap (risiko runtuh jika tebal)',
                'Periksa instalasi listrik sebelum menyalakan',
                'Periksa instalasi gas sebelum menyalakan',
                'Bersihkan saluran air dan drainase dari material vulkanik',
              ],
            ),

            _Section(
              icon: Icons.water_drop,
              title: 'Keamanan Air & Makanan',
              color: Colors.teal,
              items: const [
                'Jangan langsung menggunakan air sumur/PDAM, periksa dahulu',
                'Buang makanan yang terkontaminasi abu vulkanik',
                'Masak air hingga mendidih sebelum dikonsumsi',
                'Bersihkan tandon/bak air dari endapan abu',
                'Gunakan air kemasan jika ragu dengan kualitas air',
              ],
            ),

            _Section(
              icon: Icons.medical_services,
              title: 'Kesehatan',
              color: Colors.red,
              items: const [
                'Periksa ke fasilitas kesehatan jika mengalami gangguan pernapasan',
                'Tetap gunakan masker saat membersihkan abu',
                'Waspadai iritasi mata akibat abu halus',
                'Perhatikan gejala ISPA pada anak-anak dan lansia',
                'Minum air putih yang cukup untuk membersihkan saluran pernapasan',
              ],
            ),

            _Section(
              icon: Icons.psychology,
              title: 'Kesehatan Mental',
              color: Colors.purple,
              items: const [
                'Wajar jika merasa cemas, takut, atau sedih setelah bencana',
                'Bicara dengan keluarga atau teman tentang perasaan Anda',
                'Jika stress berlebih, hubungi psikolog di posko pengungsian',
                'Bantu anak-anak mengekspresikan perasaan melalui gambar/cerita',
                'Jaga rutinitas harian untuk kestabilan emosi',
                'Hotline kesehatan jiwa: 119 ext 8',
              ],
            ),

            _Section(
              icon: Icons.home_repair_service,
              title: 'Pelaporan Kerusakan',
              color: Colors.brown,
              items: const [
                'Dokumentasikan kerusakan dengan foto untuk klaim asuransi',
                'Laporkan kerusakan ke BPBD melalui posko atau aplikasi',
                'Catat semua kerugian material untuk pendataan',
                'Koordinasi dengan RT/RW untuk bantuan rehabilitasi',
                'Ikuti program rekonstruksi dari pemerintah daerah',
              ],
            ),

            _Section(
              icon: Icons.agriculture,
              title: 'Pemulihan Lahan',
              color: Colors.green,
              items: const [
                'Abu vulkanik mengandung mineral yang menyuburkan tanah',
                'Tunggu minimal 2-4 minggu sebelum mengolah lahan',
                'Bersihkan tanaman dari abu sebelum dipanen',
                'Konsultasi dengan Dinas Pertanian untuk jadwal tanam',
                'Perhatikan potensi lahar jika musim hujan',
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  const _Section({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
                delay: Duration(milliseconds: 50 * e.key),
                duration: 300.ms,
              );
        }),
        const Divider(height: 24),
      ],
    );
  }
}
