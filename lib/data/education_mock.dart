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
      subtitle: 'Pahami apa itu gunung berapi dan jenis-jenisnya',
      emoji: '🌋',
      icon: Icons.terrain,
      color: Color(0xFF5D4037),
      imagePath: 'assets/images/education/volcano.png',
      sections: [
        EducationSection(
          emoji: '🌍',
          title: 'Apa Itu Gunung Berapi?',
          description:
              'Gunung berapi (volcano) adalah lubang pada kerak bumi yang memungkinkan magma, gas vulkanik, dan abu keluar dari dalam perut bumi ke permukaan. Proses keluarnya material ini disebut erupsi. Indonesia memiliki sekitar 127 gunung berapi aktif terbanyak di dunia!',
          bulletPoints: [
            'Magma adalah batuan cair yang sangat panas (700-1.200°C) di dalam perut bumi',
            'Ketika magma keluar ke permukaan disebut lava',
            'Erupsi bisa berupa lelehan lava, lontaran material, awan panas, atau letusan eksplosif',
            'Indonesia terletak di Cincin Api Pasifik (Ring of Fire), jalur gunung berapi yang membentang sepanjang 40.000 km',
          ],
          funFact:
              'Gunung Merapi di Yogyakarta adalah salah satu gunung berapi paling aktif di dunia. Rata-rata gunung ini mengalami erupsi setiap 4-5 tahun sekali!',
        ),
        EducationSection(
          emoji: '🔬',
          title: 'Jenis-Jenis Gunung Berapi',
          description:
              'Berdasarkan bentuk dan tipe letusannya, gunung berapi dibagi menjadi beberapa jenis:',
          bulletPoints: [
            'Gunung berapi maar — terbentuk akibat letusan eksplosif dangkal, menghasilkan kawah lebar. Contoh: Danau Kelimutu, NTT',
            'Gunung berapi perisai (shield) — lereng landai, erupsi lava yang mengalir tenang. Contoh: Mauna Loa, Hawaii',
            'Gunung berapi kerucut (stratovolcano) — berbentuk kerucut sempurna, erupsi eksplosif. Contoh: Gunung Merapi, Semeru, Fuji',
            'Gunung berapi kaldera — memiliki kawah besar akibat runtuhnya puncak gunung. Contoh: Gunung Tambora, Krakatau',
          ],
          funFact:
              'Letusan Gunung Tambora tahun 1815 adalah letusan terbesar dalam sejarah modern. Letusannya menyebabkan "Tahun Tanpa Musim Panas" di seluruh dunia!',
        ),
        EducationSection(
          emoji: '📊',
          title: 'Tingkat Status Gunung Berapi',
          description:
              'PVMBG (Pusat Vulkanologi dan Mitigasi Bencana Geologi) menetapkan 4 level status:',
          bulletPoints: [
            'Level I — NORMAL (Hijau): Aktivitas vulkanik dasar, tidak ada ancaman erupsi',
            'Level II — WASPADA (Kuning): Peningkatan aktivitas di atas normal, perlu perhatian',
            'Level III — SIAGA (Oranye): Kecenderungan meningkat ke arah erupsi, siap evakuasi',
            'Level IV — AWAS (Merah): Erupsi segera terjadi atau sedang berlangsung, EVAKUASI!',
          ],
          warning:
              'Selalu pantau status terbaru gunung berapi dari sumber resmi (PVMBG, BMKG, BPBD). Jangan mengandalkan informasi dari media sosial yang belum diverifikasi!',
        ),
      ],
    ),
    const EducationTopic(
      title: 'Tanda-Tanda Erupsi',
      subtitle: 'Kenali gejala awal aktivitas vulkanik',
      emoji: '⚠️',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFE65100),
      imagePath: 'assets/images/education/volcano_eruption_guide.png',
      sections: [
        EducationSection(
          emoji: '🔊',
          title: 'Tanda Peringatan Sebelum Erupsi',
          description:
              'Gunung berapi biasanya memberikan tanda-tanda peringatan sebelum erupsi. Mengenali tanda-tanda ini bisa menyelamatkan nyawa Anda dan keluarga.',
          bulletPoints: [
            'Gempa vulkanik — getaran yang semakin sering dan kuat, berbeda dari gempa tektonik biasa',
            'Suara gemuruh — dentuman atau suara menderu dari dalam gunung',
            'Bau belerang — bau menyengat seperti telur busuk di sekitar gunung',
            'Perubahan suhu — sumber air panas berubah suhu atau muncul mata air baru',
            'Hewan gelisah — hewan liar turun gunung, burung terbang panik menjauhi gunung',
            'Perubahan bentuk — tanah retak, pohon miring, kubah lava tumbuh',
          ],
          warning:
              'Jika Anda merasakan gempa vulkanik yang semakin kuat dan sering, SEGERA evakuasi tanpa menunggu perintah resmi. Keselamatan jiwa adalah prioritas utama!',
        ),
        EducationSection(
          emoji: '🌡️',
          title: 'Monitoring oleh PVMBG',
          description:
              'Pusat Vulkanologi memantau gunung berapi 24/7 menggunakan berbagai instrumen canggih:',
          bulletPoints: [
            'Seismograf — mendeteksi gempa vulkanik dan frekuensinya',
            'GPS dan tiltmeter — mengukur deformasi (perubahan bentuk) tubuh gunung',
            'Kamera CCTV — pemantauan visual secara real-time',
            'Sensor gas — mengukur emisi SO2 (sulfur dioksida) dan gas vulkanik lainnya',
            'Sensor thermal — mendeteksi perubahan suhu di kawah dan sekitarnya',
          ],
          funFact:
              'PVMBG memantau 68 gunung berapi di Indonesia secara terus-menerus melalui 79 pos pengamatan gunung api (PGA) yang tersebar di seluruh Indonesia.',
        ),
      ],
    ),
    const EducationTopic(
      title: 'Persiapan Sebelum Erupsi',
      subtitle: 'Langkah-langkah yang harus dilakukan sedini mungkin',
      emoji: '🎒',
      icon: Icons.backpack,
      color: Color(0xFF1565C0),
      imagePath: 'assets/images/education/emergency_bag_contents.png',
      sections: [
        EducationSection(
          emoji: '📋',
          title: 'Rencana Keluarga',
          description:
              'Setiap keluarga yang tinggal di radius 15 km dari gunung berapi aktif WAJIB memiliki rencana darurat. Buat dan latih rencana ini bersama seluruh anggota keluarga.',
          bulletPoints: [
            'Tentukan titik kumpul keluarga jika terpisah saat evakuasi',
            'Hafal jalur evakuasi dari rumah ke tempat aman (minimal 2 rute alternatif)',
            'Simpan nomor darurat di handphone semua anggota keluarga: BNPB (117), BPBD, Basarnas (115)',
            'Tentukan siapa yang bertanggung jawab membawa tas siaga, anak kecil, dan lansia',
            'Latih evakuasi minimal 2 kali setahun bersama keluarga',
            'Pastikan semua anggota keluarga tahu cara mematikan listrik dan gas di rumah',
          ],
        ),
        EducationSection(
          emoji: '🎒',
          title: 'Isi Tas Siaga Bencana',
          description:
              'Siapkan tas siaga untuk setiap anggota keluarga. Simpan di tempat yang mudah dijangkau dan periksa isinya setiap 6 bulan.',
          bulletPoints: [
            'Dokumen penting (KTP, KK, ijazah, paspor) dalam map plastik anti air',
            'Air minum minimal 3 liter per orang (untuk 3 hari)',
            'Makanan tahan lama: biskuit, mie instan, makanan kaleng, gula',
            'Obat-obatan pribadi dan P3K: perban, betadine, obat diare, parasetamol',
            'Senter + baterai cadangan, peluit, korek api, lilin',
            'Masker N95 atau kain tebal untuk pelindung pernapasan',
            'Baju ganti, selimut tipis, jas hujan',
            'Power bank dan kabel charger handphone',
            'Radio FM portable untuk memantau informasi darurat',
            'Uang tunai secukupnya (ATM mungkin tidak berfungsi saat bencana)',
          ],
          funFact:
              'Menurut BNPB, ideal nya keluarga juga menyiapkan salinan dokumen penting dalam bentuk digital di cloud storage, sehingga tetap aman meskipun dokumen fisik rusak.',
        ),
        EducationSection(
          emoji: '🏠',
          title: 'Persiapan Rumah',
          description:
              'Lindungi rumah Anda dari dampak abu vulkanik dan material letusan:',
          bulletPoints: [
            'Perkuat atap rumah agar mampu menahan beban abu vulkanik (abu basah sangat berat!)',
            'Siapkan plastik atau terpal untuk menutup sumber air (sumur, bak penampungan)',
            'Pastikan saluran air dan selokan bersih untuk mengalirkan air hujan bercat abu',
            'Siapkan peralatan kebersihan: sekop, sapu, ember untuk membersihkan abu',
            'Pastikan kendaraan terisi bahan bakar penuh dan siap digunakan',
          ],
          warning:
              'Abu vulkanik basah bisa mencapai berat 1-2 ton per meter kubik! Atap rumah dengan konstruksi lemah bisa runtuh. Bersihkan abu dari atap secara berkala jika aman dilakukan.',
        ),
      ],
    ),
    EducationTopic(
      title: 'Saat Erupsi Terjadi',
      subtitle: 'Panduan bertahan hidup saat letusan gunung berapi',
      emoji: '🔥',
      icon: Icons.local_fire_department,
      color: SigumiTheme.statusAwas,
      imagePath: 'assets/images/education/volcano_eruption_guide.png',
      sections: const [
        EducationSection(
          emoji: '🏃',
          title: 'Langkah Evakuasi Darurat',
          description:
              'Saat status gunung AWAS atau perintah evakuasi dikeluarkan, lakukan langkah berikut dengan tenang dan cepat:',
          bulletPoints: [
            'TETAP TENANG — panik justru membahayakan diri sendiri dan orang lain',
            'Ambil tas siaga dan evakuasi melalui jalur yang telah disepakati',
            'Evakuasi tegak lurus (menjauhi) arah aliran lava, BUKAN sejajar atau mendekat',
            'Dari jawa: hindari lembah dan aliran sungai yang berhulu di gunung — jalur utama lahar!',
            'Gunakan masker atau kain basah untuk melindungi pernapasan dari abu dan gas',
            'Lindungi kepala dengan helm, topi keras, atau bantal dari material jatuhan',
            'Jangan kembali ke zona bahaya meskipun letusan tampak mereda',
            'Ikuti arahan petugas BPBD, TNI, dan tim SAR di pos evakuasi',
          ],
          warning:
              'JANGAN mencoba menonton atau mendokumentasikan erupsi dari jarak dekat! Awan panas (pyroclastic flow) bergerak dengan kecepatan 100-700 km/jam dan bersuhu hingga 700°C — mustahil untuk berlari menghindar.',
        ),
        EducationSection(
          emoji: '😷',
          title: 'Jika Terjebak Hujan Abu',
          description:
              'Abu vulkanik berbeda dengan debu biasa. Abu vulkanik mengandung partikel kaca tajam yang berbahaya bagi paru-paru dan mata.',
          bulletPoints: [
            'Segera masuk ke dalam bangunan dan tutup semua pintu dan jendela',
            'Gunakan masker N95 atau balut hidung & mulut dengan kain basah berlapis',
            'Lindungi mata dengan kacamata pelindung (bukan lensa kontak!)',
            'Tutup semua wadah makanan dan sumber air',
            'Matikan AC/kipas angin yang mengambil udara dari luar',
            'Jangan mengemudi — jarak pandang bisa kurang dari 1 meter',
            'Jika harus di luar, kenakan pakaian lengan panjang dan celana panjang',
          ],
          funFact:
              'Abu vulkanik bisa menyebar hingga ratusan kilometer. Letusan Gunung Kelud 2014 menyebarkan abu hingga ke Yogyakarta (~200 km) dan menyebabkan bandara ditutup!',
        ),
        EducationSection(
          emoji: '🌊',
          title: 'Bahaya Lahar',
          description:
              'Lahar adalah campuran air, lumpur, dan material vulkanik yang mengalir deras seperti sungai beton cair. Ada dua jenis lahar:',
          bulletPoints: [
            'Lahar panas — langsung mengalir saat erupsi, suhu bisa mencapai 200°C',
            'Lahar dingin — terjadi saat hujan deras menggerus endapan abu vulkanik, bisa terjadi berminggu-minggu setelah erupsi',
            'Jauhi aliran sungai yang berhulu di gunung — lahar mengalir melalui lembah sungai',
            'Jika mendengar suara gemuruh dari arah hulu, SEGERA naik ke tempat tinggi',
            'Jangan menyeberangi jembatan di atas sungai saat atau setelah hujan deras',
          ],
          warning:
              'Lahar dingin masih menjadi ancaman selama berbulan-bulan bahkan bertahun-tahun setelah erupsi! Hujan deras bisa memicu lahar dingin yang menghancurkan jembatan dan permukiman.',
        ),
      ],
    ),
    const EducationTopic(
      title: 'Menghadapi Hujan Abu',
      subtitle: 'Tips lengkap menghadapi hujan abu vulkanik',
      emoji: '🌫️',
      icon: Icons.cloud,
      color: Color(0xFF546E7A),
      imagePath: 'assets/images/education/volcanic_ash_safety.png',
      sections: [
        EducationSection(
          emoji: '🏠',
          title: 'Di Dalam Rumah',
          description:
              'Saat hujan abu terjadi, prioritaskan untuk tetap di dalam ruangan. Berikut langkah-langkah yang harus dilakukan:',
          bulletPoints: [
            'Tutup rapat semua jendela, pintu, dan ventilasi udara',
            'Matikan AC dan kipas angin yang menarik udara dari luar',
            'Basahi kain atau handuk dan letakkan di celah pintu dan jendela',
            'Tutup sumber air (bak mandi, ember, penampungan) dengan plastik atau terpal',
            'Simpan makanan dalam wadah tertutup rapat',
            'Nyalakan radio FM untuk mendapatkan informasi terbaru',
            'Jika memakai lensa kontak, segera lepas dan ganti dengan kacamata biasa',
          ],
        ),
        EducationSection(
          emoji: '🚗',
          title: 'Jika Harus Keluar Rumah',
          description:
              'Jika terpaksa harus beraktivitas di luar saat hujan abu, perhatikan hal berikut:',
          bulletPoints: [
            'Kenakan masker N95 atau minimal kain basah berlapis yang menutupi hidung dan mulut',
            'Gunakan kacamata pelindung (safety goggles), bukan kacamata biasa',
            'Pakai pakaian lengan panjang, celana panjang, dan topi',
            'Jangan mengemudi kecuali mendesak — abu mengurangi jarak pandang drastis',
            'Jika mengemudi, nyalakan lampu, kurangi kecepatan, jaga jarak aman',
            'Ganti filter udara kendaraan sesering mungkin',
            'Setelah masuk rumah, ganti pakaian dan mandi segera',
          ],
          warning:
              'Jangan menyiram abu vulkanik dengan air dari atap atau jalan! Abu vulkanik basah menjadi seperti semen dan jauh lebih sulit dibersihkan. Sapu kering terlebih dahulu.',
        ),
        EducationSection(
          emoji: '🫁',
          title: 'Kesehatan Pernapasan',
          description:
              'Abu vulkanik mengandung partikel silika dan mineral tajam berukuran mikroskopis yang sangat berbahaya bagi paru-paru. Paparan jangka panjang bisa menyebabkan silikosis.',
          bulletPoints: [
            'Gunakan masker N95 (bukan masker kain biasa!) yang bisa menyaring partikel halus',
            'Anak-anak, lansia, dan penderita asma harus tetap di dalam ruangan',
            'Jika mengalami sesak napas, batuk berkepanjangan, atau iritasi mata yang parah — segera ke fasilitas kesehatan',
            'Minum air putih yang banyak untuk menjaga kelembaban saluran pernapasan',
            'Jangan berolahraga di luar ruangan saat ada abu vulkanik',
          ],
          funFact:
              'Abu vulkanik sangat abrasif karena mengandung pecahan kaca dan mineral tajam. Meskipun terlihat seperti debu biasa, partikelnya bisa menggores kaca dan merusak mesin!',
        ),
      ],
    ),
    const EducationTopic(
      title: 'Pasca Erupsi',
      subtitle: 'Langkah-langkah pemulihan setelah letusan',
      emoji: '🏗️',
      icon: Icons.engineering,
      color: Color(0xFF2E7D32),
      imagePath: 'assets/images/education/post_eruption_recovery.png',
      sections: [
        EducationSection(
          emoji: '🏠',
          title: 'Kembali ke Rumah',
          description:
              'Setelah status diturunkan dan petugas menyatakan aman, Anda bisa mulai kembali ke rumah. Namun tetap berhati-hati!',
          bulletPoints: [
            'TUNGGU arahan resmi dari BPBD sebelum kembali — jangan atas inisiatif sendiri',
            'Periksa kondisi bangunan: retakan dinding, atap, dan fondasi sebelum masuk',
            'Bersihkan abu dari atap SEGERA — abu basah bisa mencapai beban 1-2 ton/m² dan meruntuhkan atap',
            'Gunakan masker saat membersihkan abu di dalam dan luar rumah',
            'Periksa instalasi listrik dan gas sebelum menyalakannya kembali',
            'Buang makanan yang terkontaminasi abu',
          ],
          warning:
              'Jangan langsung menghuni rumah yang rusak parah! Minta petugas BPBD atau Dinas PU untuk melakukan asesmen kelayakan bangunan terlebih dahulu.',
        ),
        EducationSection(
          emoji: '💧',
          title: 'Air dan Sanitasi',
          description:
              'Abu vulkanik bisa mengkontaminasi sumber air. Pastikan air yang Anda gunakan aman:',
          bulletPoints: [
            'Cek sumber air (sumur, PAM) — jika keruh atau berbau, JANGAN digunakan untuk minum',
            'Rebus air minimal 3 menit sebelum diminum jika tidak ada air kemasan',
            'Bersihkan bak penampungan air dari endapan abu sebelum diisi ulang',
            'Jangan mandi atau mencuci dengan air yang terkontaminasi abu berat',
            'Laporkan ke Dinas Kesehatan jika sumber air masyarakat tercemar',
          ],
        ),
        EducationSection(
          emoji: '🏥',
          title: 'Kesehatan Pasca Erupsi',
          description:
              'Pantau kondisi kesehatan seluruh anggota keluarga secara berkala, terutama anak-anak dan lansia.',
          bulletPoints: [
            'Periksakan diri ke puskesmas/RS jika mengalami gangguan pernapasan',
            'Waspadai gejala ISPA (Infeksi Saluran Pernapasan Atas): batuk, pilek, sesak napas',
            'Perhatikan kesehatan mental — PTSD (Post-Traumatic Stress Disorder) bisa muncul berminggu-minggu setelah bencana',
            'Anak-anak mungkin mengalami ketakutan, mimpi buruk, dan regresi perilaku — berikan dukungan emosional',
            'Manfaatkan layanan konseling psikologis yang disediakan pemerintah di posko bencana',
          ],
          funFact:
              'WHO menyatakan bahwa dampak psikologis bencana seringkali lebih lama dan lebih sulit ditangani daripada dampak fisiknya. Rata-rata dibutuhkan 1-2 tahun untuk pemulihan psikologis penuh.',
        ),
      ],
    ),
    const EducationTopic(
      title: 'Nomor Darurat & Kontak',
      subtitle: 'Simpan nomor-nomor penting ini!',
      emoji: '📞',
      icon: Icons.phone_in_talk,
      color: Color(0xFF6A1B9A),
      imagePath: 'assets/images/education/emergency_bag_contents.png',
      sections: [
        EducationSection(
          emoji: '🚨',
          title: 'Nomor Darurat Nasional',
          description:
              'Simpan semua nomor berikut di handphone Anda dan hafal minimal 3 nomor terpenting:',
          bulletPoints: [
            '117 — BNPB (Badan Nasional Penanggulangan Bencana)',
            '115 — Basarnas (Badan SAR Nasional)',
            '118 — Ambulans / PSC (Public Safety Center)',
            '119 — Hotline Kementerian Kesehatan',
            '110 — Kepolisian',
            '113 — Pemadam Kebakaran',
            '129 — Palang Merah Indonesia (PMI)',
          ],
        ),
        EducationSection(
          emoji: '📱',
          title: 'Kontak Lokal Khusus Merapi',
          description:
              'Nomor kontak khusus untuk pemantauan dan tanggap darurat Gunung Merapi:',
          bulletPoints: [
            '(0274) 555679 — BPBD DIY (Daerah Istimewa Yogyakarta)',
            '(0274) 896573 — Posko Merapi',
            '(0293) 5502368 — BPBD Kabupaten Magelang',
            '(0272) 322101 — BPBD Kabupaten Klaten',
            '(0274) 514058 — PVMBG BPPTKG (pemantauan Merapi)',
          ],
          funFact:
              'Anda juga bisa memantau aktivitas Merapi secara real-time melalui website resmi BPPTKG (bpptkg.kemdikbud.go.id) dan akun Twitter/X @ABORSI44 dan @ABORSI55.',
        ),
        EducationSection(
          emoji: '📻',
          title: 'Sumber Informasi Terpercaya',
          description:
              'Saat bencana, informasi palsu (hoaks) bisa menyebar lebih cepat dari bencana itu sendiri. Pastikan Anda hanya mengikuti sumber resmi:',
          bulletPoints: [
            'PVMBG — pvmbg.esdm.go.id (status gunung berapi)',
            'BMKG — bmkg.go.id (cuaca, gempa, peringatan dini)',
            'BNPB — bnpb.go.id (informasi bencana nasional)',
            'BPPTKG — bpptkg.kemdikbud.go.id (khusus pemantauan Merapi)',
            'Radio Republik Indonesia (RRI) — frekuensi lokal untuk informasi darurat',
          ],
          warning:
              'Jangan sebarkan informasi yang belum terverifikasi! Hoaks saat bencana bisa menyebabkan kepanikan massal dan menghambat proses evakuasi.',
        ),
      ],
    ),
  ];

  // =============================================================================
  // ANAK-ANAK / CHILDREN EDUCATION
  // =============================================================================
  static final List<Map<String, dynamic>> childrenTopics = [
    {
      'emoji': '🌋',
      'title': 'Cerita si Gunung Berapi',
      'intro': 'Gunung berapi adalah gunung istimewa yang di dalam perutnya sangat paaanas! 🌡️ Dia punya cairan lahar yang bisa keluar saat "batuk".',
      'bullets': [
        'Di dalam perut gunung ada **magma** (batuan panas cair).',
        'Saat mengalir keluar, namanya berubah jadi **lava**.',
        'Meskipun menyeramkan, debunya bikin tanah jadi sangat subur lho!'
      ],
      'color': Colors.orange,
      'tip': 'Jangan pernah bermain di dekat kawah gunung berapi saat sedang "marah" ya!',
      'quizQuestion': 'Apa nama batuan panas cair yang ada di dalam perut gunung?',
      'quizAnswers': ['Sirup Merah', 'Lava', 'Magma'],
      'correctAnswerIndex': 2,
      'explanation': 'Yey benar! Magma itu batuan panas di dalam perut gunung. Kalau sudah keluar baru namanya lava.',
    },
    {
      'emoji': '⚠️',
      'title': 'Kenali Bahasa Gunung! 👂',
      'intro': 'Gunung berapi mirip raksasa tidur. Saat mau bangun, dia pasti kasih tanda-tanda dulu ke kita!',
      'bullets': [
        'Tanah bergoyang-goyang pelan seperti naik bom-bom car.',
        'Terdengar suara dentuman "GRRRR" dari atas awan.',
        'Tiba-tiba tercium bau *telur busuk* (bau gas belerang).',
        'Hewan-hewan lari ketakutan turun ke bawah.',
      ],
      'color': Colors.red,
      'tip': 'Hewan-hewan lebih peka dari kita. Kalau monyet atau burung turun gunung, itu tandanya bahaya.',
      'quizQuestion': 'Tanda apa yang TIDAK diberikan gunung sebelum meletus?',
      'quizAnswers': ['Tanah bergetar', 'Bau wangi bunga', 'Bau telur busuk'],
      'correctAnswerIndex': 1,
      'explanation': 'Pintar! Gunung mengeluarkan gas belerang yang baunya tidak enak, bukan wangi bunga.',
    },
    {
      'emoji': '🏃‍♂️💨',
      'title': 'Jurus Lari Cepat!',
      'intro': 'Kalau ada sirene berbunyi atau instruksi evakuasi, pakailah "jurus lari pahlawan" ini!',
      'bullets': [
        'Tetap *TENANG*, ambil napas dalam-dalam.',
        'Cepat ikuti arahan Ayah, Ibu, atau petugas berseragam.',
        'Tutup hidung dan mulut pakai **masker**.',
        'Pakai helm atau lindungi kepala pakai tasmu.',
      ],
      'color': Colors.blue,
      'tip': 'Hal terpenting adalah CAN (Cepat, Aman, Nurut)! Keselamatanmu jauh lebih penting dari mainan yang tertinggal.',
      'quizQuestion': 'Apa yang harus dilindungi pertama kali dari hujan debu?',
      'quizAnswers': ['Hidung dan mulut', 'Sepatu', 'Tas sekolah'],
      'correctAnswerIndex': 0,
      'explanation': 'Hebat! Debu gunung sangat tajam, berbahaya kalau masuk ke hidung dan paru-paru.',
    },
    {
      'emoji': '🎒✨',
      'title': 'Ransel Pahlawan Cilik',
      'intro': 'Bantu orang tuamu! Kamu juga bisa punya ransel super untuk dibawa saat evakuasi.',
      'bullets': [
        'Senter kecil (agar tidak takut gelap!).',
        'Satu botol air minum dan camilan energi.',
        'Masker dan tisu basah penutup debu.',
        'Pluit pahlawan! (Untuk minta tolong).',
      ],
      'color': Colors.green,
      'tip': 'Simpan ranselmu di dekat pintu kamarmu agar gampang diambil saat terburu-buru.',
      'quizQuestion': 'Benda mungil apa di ransel yang bunyinya nyaring untuk minta tolong?',
      'quizAnswers': ['Senter', 'Peluit', 'Permen'],
      'correctAnswerIndex': 1,
      'explanation': 'Benar! Peluit suaranya sangat keras dan membantu petugas menemukan posisimu.',
    },
    {
      'emoji': '📞',
      'title': 'Nomor Darurat',
      'intro': 'Hayo, pahlawan cilik harus hafal nomor penting ini kalau terpisah saat panik.',
      'bullets': [
        'Coba ingat atau catat **nomor HP Ibu / Ayah**.',
        'Telepon **117** untuk tim penanggulangan bencana.',
        'Telepon **115** untuk panggil Kakak Basarnas.',
      ],
      'color': Colors.purple,
      'tip': 'Tulis semua nomor telepon di selembar kertas kecil dan taruh di dalam sakumu terus ya!',
      'quizQuestion': 'Berapa nomor telepon untuk memanggil Kakak Basarnas?',
      'quizAnswers': ['112', '115', '911'],
      'correctAnswerIndex': 1,
      'explanation': 'Tepat sekali! 115 adalah nomor khusus Badan SAR Nasional (Basarnas).',
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
