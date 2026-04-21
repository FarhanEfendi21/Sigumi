import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/education_model.dart';

class EducationMockData {
  // =============================================================================
  // UMUM / GENERAL EDUCATION
  // =============================================================================
  static final List<EducationTopic> generalTopics = [
    const EducationTopic(
      title: 'Mengenal Gunung Berapi',
      subtitle: 'Pahami dasar gunung berapi dan status bencananya',
      emoji: '🌋',
      icon: Icons.terrain,
      color: Color(0xFF5D4037),
      imagePath: 'assets/images/education/volcano.png',
      sections: [
        EducationSection(
          emoji: '🌍',
          title: 'Apa Itu Gunung Berapi?',
          description:
              'Gunung berapi adalah bukaan kerak bumi tempat keluarnya magma cair dan gas (erupsi). Indonesia memiliki tingkat aktivitas tertinggi karena dilintasi Cincin Api Pasifik (Ring of Fire).',
          bulletPoints: [
            'Magma: lelehan batu panas di dalam bumi.',
            'Lava: magma yang telah keluar ke permukaan.',
          ],
        ),
        EducationSection(
          emoji: '📊',
          title: '4 Tingkat Status Aktivitas',
          description:
              'Selalu perhatikan peringatan pemerintah (PVMBG) berdasarkan 4 level ini:',
          bulletPoints: [
            'Level I (Normal - Hijau): Aman, tidak ada ancaman.',
            'Level II (Waspada - Kuning): Ada aktivitas di atas normal.',
            'Level III (Siaga - Oranye): Berpotensi letusan, siap-siap evakuasi.',
            'Level IV (Awas - Merah): Erupsi besar berlangsung. WAJIB EVAKUASI segera.',
          ],
        ),
      ],
    ),
    const EducationTopic(
      title: 'Tanda-Tanda Erupsi',
      subtitle: 'Kemampuan membaca peringatan alam',
      emoji: '⚠️',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFE65100),
      imagePath: 'assets/images/education/volcano_eruption_guide.png',
      sections: [
        EducationSection(
          emoji: '🔊',
          title: 'Gejala Alam',
          description:
              'Gunung yang akan meletus umumnya memberikan "sinyal peringatan". Jika Anda berada di dekatnya, waspadai hal berikut:',
          bulletPoints: [
            'Gempa bumi vulkanik berskala kecil namun terjadi terus-menerus.',
            'Terdengar suara gemuruh menderu dari arah kawah.',
            'Sumber air tiba-tiba mengering atau suhu udara sekitar memanas.',
            'Hewan-hewan liar berlarian turun menuruni gunung.',
          ],
          warning:
              'Jika tanda-tanda masif muncul, segera bergerak ke zona aman tanpa harus menunggu instruksi resmi.',
        ),
      ],
    ),
    const EducationTopic(
      title: 'Persiapan & Tas Siaga',
      subtitle: 'Tindakan berjaga-jaga sebelum bencana pecah',
      emoji: '🎒',
      icon: Icons.backpack,
      color: Color(0xFF1565C0),
      imagePath: 'assets/images/education/emergency_bag_contents.png',
      sections: [
        EducationSection(
          emoji: '📋',
          title: 'Manajemen Keluarga',
          description:
              'Siapkan rencana keselamatan secara matang sebelum bencana terjadi.',
          bulletPoints: [
            'Hafalkan rute evakuasi dan sepakati titik kumpul keluarga.',
            'Siapkan Tas Siaga dalam rumah yang mudah dijangkau saat lari.',
          ],
        ),
        EducationSection(
          emoji: '🔦',
          title: 'Isi Tas Siaga Bencana',
          description:
              'Pastikan tas siaga berisi kebutuhan pokok bertahan hidup (untuk 3 hari):',
          bulletPoints: [
            'Dokumen penting dalam map kedap air.',
            'Air minum dan logistik instan (biskuit/makanan kaleng).',
            'Senter, baterai, peluit, dan obat-obatan pribadi (P3K).',
            'Masker N95/Kain tebal pelindung hidung.',
          ],
        ),
      ],
    ),
    const EducationTopic(
      title: 'Saat & Pasca Erupsi',
      subtitle: 'SOP Evakuasi dan Penanganan Abu',
      emoji: '🔥',
      icon: Icons.local_fire_department,
      color: SigumiTheme.statusAwas,
      imagePath: 'assets/images/education/volcano_eruption_guide.png',
      sections: [
        EducationSection(
          emoji: '🏃',
          title: 'Ketika Erupsi Terjadi',
          description:
              'Abaikan harta benda, utamakan nyawa Anda dan keluarga.',
          bulletPoints: [
            'Jangan panik. Lindungi kepala & jalur napas menggunakan jaket/masker.',
            'Lari menjauhi arah letusan. JANGAN mengikuti lembah atau aliran sungai karena itu jalur bebas lahar.',
          ],
          warning:
              'Awan panas (Wedhus Gembel) kecepatannya ratusan Km/Jam dan bersuhu mematikan. Dilarang keras merekam kedekatan awan panas, segera menjauh!',
        ),
        EducationSection(
          emoji: '🌫️',
          title: 'Penanganan Abu Vulkanik',
          description:
              'Debu vulkanik sangat tajam bak serpihan mikroskopis kaca.',
          bulletPoints: [
            'Tutup semua jendela dan matikan ventilasi.',
            'Gunakan kacamata dan masker saat harus keluar rumah.',
            'Bersihkan tumpukan abu atap JANGAN DISIRAM AIR. Abu akan menjadi berat layaknya semen dan berisiko merobohkan rumah.',
          ],
        ),
      ],
    ),
  ];

  // =============================================================================
  // ANAK-ANAK / CHILDREN EDUCATION
  // =============================================================================
  static final List<Map<String, dynamic>> childrenTopics = [
    {
      'emoji': '🎒',
      'title': 'Tas Ajaib Penyelamat!',
      'intro': 'Aku adalah tas yang sangat penting dan harus selalu siap sedia! Jika gunung berapi mulai batuk-batuk dan mengeluarkan banyak asap, kamu harus langsung menggendongku. Di dalam perutku sudah ada air minum, senter, kotak P3K, dan biskuit kesukaanmu.',
      'color': Colors.orange,
      'tip': 'Titipkan tas siaga bencanamu di posisi yang mudah diraih, seperti di dekat pintu keluarmu.',
      'quizQuestion': 'Benda apakah aku?',
      'quizAnswers': ['Tas Sekolah', 'Tas Siaga Bencana', 'Kantong Belanja'],
      'correctAnswerIndex': 1,
      'explanation': 'Tepat sekali! Tas Siaga Bencana adalah teman pahlawanmu yang berisi alat keselamatan darurat.',
    },
    {
      'emoji': '🦸‍♂️',
      'title': 'Tameng Wajah Anti-Debu!',
      'intro': 'Saat gunung meletus, hujan yang turun kadang bukan air, melainkan debu dan abu yang bisa bikin kita batuk-batuk. Supaya paru-parumu tetap sehat dan pernapasanmu aman, kamu harus memakainya untuk menutupi hidung dan mulutmu dengan rapat.',
      'color': Colors.blue,
      'tip': 'Gunakan sampai benar-benar tertutup rapat, debu gunung itu tajam dan tidak seperti debu biasa di jalanan.',
      'quizQuestion': 'Benda apakah yang harus kamu pakai?',
      'quizAnswers': ['Masker', 'Kacamata Renang', 'Topi Pesta'],
      'correctAnswerIndex': 0,
      'explanation': 'Luar biasa! Masker yang rapat akan menjadi tameng super untuk saluran napasmu.',
    },
    {
      'emoji': '📢',
      'title': 'Suara Panggilan Pahlawan!',
      'intro': 'Suaraku bisa sangat keras! Bunyiku bisa seperti "Nging... Nging..." yang panjang, atau suara pukulan "Tong... Tong... Tong..." berkali-kali. Kalau kamu mendengar suaraku bersahutan saat ada bahaya gunung meletus, itu artinya kamu dan keluargamu harus segera berkumpul dan pergi ke tempat yang aman.',
      'color': Colors.red,
      'tip': 'Jangan panik jika mendengar suara ini! Carilah ayah, ibu, atau orang dewasa terdekat dan ikuti aba-aba mereka.',
      'quizQuestion': 'Suara apakah itu?',
      'quizAnswers': ['Bel Sekolah', 'Musik Konser', 'Sirine/Kentongan'],
      'correctAnswerIndex': 2,
      'explanation': 'Benar! Sirine atau kentongan yang bertalu-talu adalah pesan darurat supaya kita cepat berkumpul.',
    },
    {
      'emoji': '⛺',
      'title': 'Markas Rahasia Super Aman!',
      'intro': 'Aku adalah tempat yang lapang, aman, dan jauh dari bahaya letusan. Pak Kepala Desa dan Tim Penyelamat akan menyuruh kalian berjalan mengikuti papan petunjuk panah berwarna hijau untuk menemuiku.',
      'color': Colors.green,
      'tip': 'Simbol markas rahasia ini berwarna HIJAU bergambar beberapa orang dengan tanda panah ke dalam.',
      'quizQuestion': 'Disebut apakah tempat aman ini?',
      'quizAnswers': ['Titik Kumpul Evakuasi', 'Taman Bermain', 'Tempat Parkir'],
      'correctAnswerIndex': 0,
      'explanation': 'Pintar! Titik Kumpul Evakuasi adalah tempat paling aman untuk berlindung bersama orang-orang.',
    },
    {
      'emoji': '🌋',
      'title': 'Sungai Api Merah Menyala!',
      'intro': 'Aku bersembunyi jauh di dalam perut bumi. Warnaku merah dan kuning terang, sangat panas melebihi nyala api kompor! Saat gunung meletus, aku akan keluar dari puncak dan mengalir pelan-pelan ke bawah. Kita tidak boleh menyentuhku sama sekali!',
      'color': Colors.deepOrange,
      'tip': 'Lava bergerak seperti lumpur panas. Jauhi lembah atau aliran sungai tempat lava mengalir.',
      'quizQuestion': 'Disebut apakah cairan panas ini?',
      'quizAnswers': ['Air Terjun Panas', 'Lava (atau Lahar)', 'Sirup Stroberi Raksasa'],
      'correctAnswerIndex': 1,
      'explanation': 'Hebat! Lava adalah batuan super pijar yang meleleh dan sangat berbahaya.',
    },
    {
      'emoji': '☁️',
      'title': 'Awan Raksasa yang Mengebut!',
      'intro': 'Aku terlihat seperti gulungan asap abu-abu tebal yang turun dari puncak gunung. Walaupun dari jauh terlihat empuk seperti bantal kapas, aku sangat panas dan bergerak jauh lebih cepat dari mobil balap! Kalau melihatku dari kejauhan, kamu harus cepat-cepat menjauh.',
      'color': Colors.blueGrey,
      'tip': 'Awan panas ini sering disebut Wedhus Gembel (Kambing Biri-biri) karena bentuknya keriting.',
      'quizQuestion': 'Apakah nama awan berbahaya ini?',
      'quizAnswers': ['Awan Mendung Hujan', 'Awan Panas (Wedhus Gembel)', 'Awan Permen Kapas'],
      'correctAnswerIndex': 1,
      'explanation': 'Benar sekali! Awan panas sangat mematikan karena suhunya tinggi dan sangat cepat.',
    },
    {
      'emoji': '🫨',
      'title': 'Bumi yang Menari-nari!',
      'intro': 'Sebelum gunung berapi meletus, ia biasanya akan memberikan peringatan dengan menggoyangkan tanah tempat kita berpijak. Kaca jendela rumah bisa ikut bergetar, dan air di dalam gelas bisa bergoyang-goyang tumpah karenaku.',
      'color': Colors.brown,
      'tip': 'Jika tanah bergoyang, segera lindungi kepalamu dengan tas atau berlindung di bawah meja yang kuat.',
      'quizQuestion': 'Peristiwa tanah bergoyang ini disebut apa?',
      'quizAnswers': ['Gempa Bumi (Vulkanik)', 'Angin Topan Puting Beliung', 'Tanah Longsor'],
      'correctAnswerIndex': 0,
      'explanation': 'Tepat! Gempa vulkanik adalah "tarian" peringatan bahwa gunung berapi akan meletus.',
    },
    {
      'emoji': '🥣',
      'title': 'Mangkuk Raksasa di Puncak!',
      'intro': 'Kalau kamu terbang dengan helikopter dan melihat gunung berapi dari atas, puncaknya ternyata tidak runcing seperti segitiga, lho! Bagian atasku malah berlubang besar seperti mangkuk raksasa tempat keluarnya asap putih.',
      'color': Colors.amber,
      'tip': 'Hanya tim ahli dan saintis yang boleh mendekati mangkuk raksasa ini demi keselamatan.',
      'quizQuestion': 'Apakah nama mangkuk raksasa di puncak gunung ini?',
      'quizAnswers': ['Danau Buatan', 'Kawah Gunung', 'Kolam Renang Puncak'],
      'correctAnswerIndex': 1,
      'explanation': 'Luar biasa! Kawah adalah mulut gunung berapi tempat ia bisa memuntahkan isinya.',
    },
  ];

  // =============================================================================
  // DIFABEL / DISABILITY EDUCATION
  // =============================================================================
  static const List<Map<String, dynamic>> disabilityTopics = [
    {
      'icon': 'hearing',
      'title': 'Gangguan Pendengaran',
      'subtitle': 'Panduan khusus untuk teman tuli dan sulit mendengar',
      'color': 0xFF1565C0,
      'tips': [
        'Aktifkan notifikasi visual di HP: lampu flash berkedip untuk peringatan darurat',
        'Pasang alarm getar khusus di bawah bantal untuk peringatan malam hari',
        'Gunakan aplikasi SIGUMI dalam mode visual penuh (tanpa suara)',
        'Selalu siapkan pendamping dengar yang memahami bahasa isyarat',
        'Pasang lampu darurat berputar di rumah yang menyala saat ada sirene',
        'Koordinasi dengan ketua RT/RW agar diutamakan saat evakuasi',
        'Bawa alat bantu dengar cadangan dan baterai ekstra di tas siaga',
        'Simpan kartu keterangan "saya tuli" untuk ditunjukkan saat darurat',
      ],
    },
    {
      'icon': 'visibility_off',
      'title': 'Gangguan Penglihatan',
      'subtitle': 'Panduan khusus untuk teman tunanetra dan low vision',
      'color': 0xFF2E7D32,
      'tips': [
        'Aktifkan fitur audio guidance dan text-to-speech di SIGUMI',
        'Hafal jalur evakuasi dengan cara meraba dinding, pagar, dan penanda taktil',
        'Latih berjalan di jalur evakuasi minimal 3 kali agar hafal tiap belokan',
        'Siapkan tongkat lipat cadangan dan kacamata di tas siaga',
        'Minta pendamping tetap yang bisa memberikan instruksi verbal saat evakuasi',
        'Kenali suara-suara penting: sirene, peluit evakuasi, dan alarm darurat',
        'Gunakan tali penghubung ke pendamping saat evakuasi massal (agar tidak terpisah)',
        'Bawa peluit atau alat suara agar bisa meminta bantuan jika terpisah',
      ],
    },
    {
      'icon': 'accessible',
      'title': 'Pengguna Kursi Roda',
      'subtitle':
          'Panduan khusus untuk pengguna kursi roda dan mobilitas terbatas',
      'color': 0xFFE65100,
      'tips': [
        'Kenali jalur evakuasi yang ramah kursi roda (hindari tangga dan jalan berbatu)',
        'Siapkan minimal 2 pendamping yang bersedia membantu saat evakuasi',
        'Latih proses evakuasi menggunakan kursi roda bersama pendamping secara berkala',
        'Siapkan kursi roda manual cadangan (kursi roda listrik bisa mati saat bencana)',
        'Koordinasi dengan tim BPBD tentang kebutuhan mobilitas khusus Anda',
        'Pastikan kendaraan evakuasi bisa menampung kursi roda',
        'Simpan alat bantu mobilitas tambahan (kruk, walker) di tas siaga',
        'Beri tahu tetangga terdekat lokasi kamar Anda agar bisa dijemput saat darurat',
      ],
    },
    {
      'icon': 'elderly',
      'title': 'Lansia',
      'subtitle': 'Panduan khusus untuk warga senior',
      'color': 0xFF6A1B9A,
      'tips': [
        'Koordinasi dengan anak, cucu, atau tetangga untuk bantuan evakuasi',
        'Siapkan obat-obatan rutin dalam jumlah 7 hari di dalam tas siaga',
        'Simpan catatan riwayat medis, golongan darah, dan alergi di dompet',
        'Aktifkan fitur audio dengan suara jelas dan volume tinggi di SIGUMI',
        'Gunakan sandal atau sepatu yang nyaman dan tidak licin untuk evakuasi',
        'Latih rute evakuasi secara perlahan bersama pendamping',
        'Pasang nomor darurat di layar utama handphone dengan ukuran besar',
        'Simpan foto seluruh anggota keluarga di HP (untuk identifikasi jika terpisah)',
      ],
    },
  ];
}
