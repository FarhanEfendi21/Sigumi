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
      'intro':
          'Aku adalah tas yang sangat penting dan harus selalu siap sedia! Jika gunung berapi mulai batuk-batuk dan mengeluarkan banyak asap, kamu harus langsung menggendongku. Di dalam perutku sudah ada air minum, senter, kotak P3K, dan biskuit kesukaanmu.',
      'color': Colors.orange,
      'tip':
          'Titipkan tas siaga bencanamu di posisi yang mudah diraih, seperti di dekat pintu keluarmu.',
      'quizQuestions': [
        {
          'question': 'Benda apakah yang harus kamu siapkan sebelum bencana?',
          'answers': ['Tas Sekolah', 'Tas Siaga Bencana', 'Kantong Belanja'],
          'correctIndex': 1,
          'explanation':
              'Tepat sekali! Tas Siaga Bencana adalah teman pahlawanmu yang berisi alat keselamatan darurat.',
        },
        {
          'question': 'Berapa hari kebutuhan yang ada di dalam tas siaga?',
          'answers': ['1 hari', '3 hari', '7 hari'],
          'correctIndex': 1,
          'explanation':
              'Benar! Tas siaga harus berisi kebutuhan bertahan hidup untuk 3 hari.',
        },
        {
          'question': 'Di mana sebaiknya tas siaga disimpan?',
          'answers': [
            'Di dalam lemari tertutup',
            'Di dekat pintu keluar',
            'Di bawah tempat tidur'
          ],
          'correctIndex': 1,
          'explanation':
              'Betul! Tas siaga harus mudah dijangkau, jadi simpan di dekat pintu keluar agar cepat diambil.',
        },
        {
          'question': 'Benda apa yang TIDAK perlu ada di tas siaga?',
          'answers': ['Senter dan baterai', 'Mainan favorit', 'Masker pelindung'],
          'correctIndex': 1,
          'explanation':
              'Tepat! Tas siaga diisi benda-benda keselamatan, bukan mainan. Prioritaskan barang yang benar-benar dibutuhkan.',
        },
        {
          'question': 'Kapan kamu harus menggendong tas siaga?',
          'answers': [
            'Saat pergi ke sekolah',
            'Saat gunung mulai mengeluarkan banyak asap',
            'Saat pergi bermain'
          ],
          'correctIndex': 1,
          'explanation':
              'Betul sekali! Tas siaga harus langsung digendong saat ada tanda-tanda bahaya gunung berapi.',
        },
      ],
    },
    {
      'emoji': '🦸‍♂️',
      'title': 'Tameng Wajah Anti-Debu!',
      'intro':
          'Saat gunung meletus, hujan yang turun kadang bukan air, melainkan debu dan abu yang bisa bikin kita batuk-batuk. Supaya paru-parumu tetap sehat dan pernapasanmu aman, kamu harus memakainya untuk menutupi hidung dan mulutmu dengan rapat.',
      'color': Colors.blue,
      'tip':
          'Gunakan sampai benar-benar tertutup rapat, debu gunung itu tajam dan tidak seperti debu biasa di jalanan.',
      'quizQuestions': [
        {
          'question': 'Apa yang harus kamu pakai untuk melindungi hidung dari abu?',
          'answers': ['Masker', 'Kacamata Renang', 'Topi Pesta'],
          'correctIndex': 0,
          'explanation':
              'Luar biasa! Masker yang rapat akan menjadi tameng super untuk saluran napasmu.',
        },
        {
          'question': 'Mengapa abu vulkanik berbahaya bagi tubuh kita?',
          'answers': [
            'Karena berbau harum',
            'Karena tajam seperti serpihan kaca kecil',
            'Karena berwarna abu-abu'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Abu vulkanik sangat tajam seperti serpihan kaca mikroskopis dan bisa melukai paru-paru.',
        },
        {
          'question': 'Bagaimana cara memakai masker yang benar saat ada abu vulkanik?',
          'answers': [
            'Diletakkan di leher saja',
            'Menutupi hidung dan mulut dengan rapat',
            'Dipakai di kepala seperti topi'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Masker harus menutupi hidung dan mulut dengan rapat agar abu tidak masuk ke saluran napas.',
        },
        {
          'question': 'Selain masker, apa lagi yang bisa melindungi matamu dari abu?',
          'answers': ['Kacamata pelindung', 'Kacamata hitam biasa', 'Tidak perlu pakai apapun'],
          'correctIndex': 0,
          'explanation':
              'Betul! Kacamata pelindung membantu melindungi mata dari abu vulkanik yang tajam.',
        },
        {
          'question': 'Abu vulkanik berbeda dengan debu biasa karena...',
          'answers': [
            'Abu vulkanik lebih ringan',
            'Abu vulkanik lebih tajam dan berbahaya',
            'Abu vulkanik berwarna putih'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Abu vulkanik jauh lebih tajam dan berbahaya dibanding debu jalanan biasa.',
        },
      ],
    },
    {
      'emoji': '📢',
      'title': 'Suara Panggilan Pahlawan!',
      'intro':
          'Suaraku bisa sangat keras! Bunyiku bisa seperti "Nging... Nging..." yang panjang, atau suara pukulan "Tong... Tong... Tong..." berkali-kali. Kalau kamu mendengar suaraku bersahutan saat ada bahaya gunung meletus, itu artinya kamu dan keluargamu harus segera berkumpul dan pergi ke tempat yang aman.',
      'color': Colors.red,
      'tip':
          'Jangan panik jika mendengar suara ini! Carilah ayah, ibu, atau orang dewasa terdekat dan ikuti aba-aba mereka.',
      'quizQuestions': [
        {
          'question': 'Suara apa yang menandakan ada bahaya dan kita harus evakuasi?',
          'answers': ['Bel Sekolah', 'Musik Konser', 'Sirine/Kentongan'],
          'correctIndex': 2,
          'explanation':
              'Benar! Sirine atau kentongan yang bertalu-talu adalah pesan darurat supaya kita cepat berkumpul.',
        },
        {
          'question': 'Apa yang harus kamu lakukan saat mendengar sirine bahaya?',
          'answers': [
            'Terus bermain dan abaikan',
            'Cari orang dewasa dan ikuti aba-aba evakuasi',
            'Berlari sejauh mungkin sendirian'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Saat mendengar sirine, segera cari orang dewasa dan ikuti aba-aba evakuasi bersama.',
        },
        {
          'question': 'Bunyi kentongan yang bertalu-talu artinya...',
          'answers': [
            'Ada pesta di kampung',
            'Saatnya makan siang',
            'Ada bahaya dan semua harus berkumpul'
          ],
          'correctIndex': 2,
          'explanation':
              'Betul! Kentongan bertalu-talu adalah tanda bahaya tradisional yang berarti semua orang harus segera berkumpul.',
        },
        {
          'question': 'Saat mendengar sirine darurat, kamu TIDAK boleh...',
          'answers': [
            'Memberitahu anggota keluarga lain',
            'Panik dan berlari sendirian tanpa tujuan',
            'Mengambil tas siaga'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Jangan panik dan berlari sendiri. Tetap tenang, cari keluarga, dan evakuasi bersama.',
        },
        {
          'question': 'Siapa yang biasanya membunyikan sirine atau kentongan tanda bahaya?',
          'answers': [
            'Anak-anak yang sedang bermain',
            'Petugas atau warga yang mengetahui ada bahaya',
            'Orang yang iseng'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Sirine atau kentongan dibunyikan oleh petugas atau warga yang mengetahui adanya bahaya.',
        },
      ],
    },
    {
      'emoji': '⛺',
      'title': 'Markas Rahasia Super Aman!',
      'intro':
          'Aku adalah tempat yang lapang, aman, dan jauh dari bahaya letusan. Pak Kepala Desa dan Tim Penyelamat akan menyuruh kalian berjalan mengikuti papan petunjuk panah berwarna hijau untuk menemuiku.',
      'color': Colors.green,
      'tip':
          'Simbol markas rahasia ini berwarna HIJAU bergambar beberapa orang dengan tanda panah ke dalam.',
      'quizQuestions': [
        {
          'question': 'Disebut apakah tempat aman berkumpul saat bencana?',
          'answers': ['Titik Kumpul Evakuasi', 'Taman Bermain', 'Tempat Parkir'],
          'correctIndex': 0,
          'explanation':
              'Pintar! Titik Kumpul Evakuasi adalah tempat paling aman untuk berlindung bersama orang-orang.',
        },
        {
          'question': 'Warna apa yang biasanya digunakan pada papan petunjuk evakuasi?',
          'answers': ['Merah', 'Hijau', 'Kuning'],
          'correctIndex': 1,
          'explanation':
              'Benar! Papan petunjuk evakuasi biasanya berwarna hijau dengan gambar orang dan tanda panah.',
        },
        {
          'question': 'Apa ciri-ciri tempat evakuasi yang baik?',
          'answers': [
            'Dekat dengan kawah gunung berapi',
            'Lapang, aman, dan jauh dari bahaya letusan',
            'Di dalam gedung tinggi'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Tempat evakuasi harus lapang, aman, dan jauh dari bahaya letusan.',
        },
        {
          'question': 'Siapa yang menentukan titik kumpul evakuasi di desa?',
          'answers': [
            'Anak-anak',
            'Kepala Desa dan Tim Penyelamat',
            'Pedagang di pasar'
          ],
          'correctIndex': 1,
          'explanation':
              'Betul! Kepala Desa dan Tim Penyelamat yang menentukan dan mengumumkan titik kumpul evakuasi.',
        },
        {
          'question': 'Apa yang harus kamu lakukan setelah sampai di titik kumpul evakuasi?',
          'answers': [
            'Langsung pulang ke rumah',
            'Tetap di sana dan tunggu instruksi petugas',
            'Pergi bermain di sekitar area'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Setelah sampai di titik kumpul, tetaplah di sana dan tunggu instruksi dari petugas.',
        },
      ],
    },
    {
      'emoji': '🌋',
      'title': 'Sungai Api Merah Menyala!',
      'intro':
          'Aku bersembunyi jauh di dalam perut bumi. Warnaku merah dan kuning terang, sangat panas melebihi nyala api kompor! Saat gunung meletus, aku akan keluar dari puncak dan mengalir pelan-pelan ke bawah. Kita tidak boleh menyentuhku sama sekali!',
      'color': Colors.deepOrange,
      'tip':
          'Lava bergerak seperti lumpur panas. Jauhi lembah atau aliran sungai tempat lava mengalir.',
      'quizQuestions': [
        {
          'question': 'Disebut apakah cairan panas yang keluar dari gunung berapi?',
          'answers': ['Air Terjun Panas', 'Lava (atau Lahar)', 'Sirup Stroberi Raksasa'],
          'correctIndex': 1,
          'explanation':
              'Hebat! Lava adalah batuan super pijar yang meleleh dan sangat berbahaya.',
        },
        {
          'question': 'Di mana lava berasal sebelum keluar dari gunung?',
          'answers': [
            'Dari langit saat hujan',
            'Dari dalam perut bumi',
            'Dari danau di sekitar gunung'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Lava berasal dari magma yang ada jauh di dalam perut bumi dan keluar saat gunung meletus.',
        },
        {
          'question': 'Mengapa kita tidak boleh mendekati aliran lava?',
          'answers': [
            'Karena lava berwarna merah',
            'Karena lava sangat panas dan bisa membakar segalanya',
            'Karena lava berbau tidak enak'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Lava sangat panas, jauh melebihi suhu api kompor, sehingga sangat berbahaya untuk didekati.',
        },
        {
          'question': 'Jalur mana yang harus DIHINDARI saat ada lava mengalir?',
          'answers': [
            'Jalur yang menanjak ke bukit',
            'Lembah dan aliran sungai',
            'Jalan raya yang lebar'
          ],
          'correctIndex': 1,
          'explanation':
              'Betul! Lava mengalir mengikuti lembah dan sungai, jadi hindari jalur tersebut saat evakuasi.',
        },
        {
          'question': 'Bagaimana lava bergerak setelah keluar dari gunung?',
          'answers': [
            'Terbang ke udara seperti balon',
            'Mengalir ke bawah mengikuti lereng seperti lumpur panas',
            'Langsung membeku di tempat'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Lava mengalir ke bawah mengikuti lereng gunung seperti lumpur yang sangat panas.',
        },
      ],
    },
    {
      'emoji': '☁️',
      'title': 'Awan Raksasa yang Mengebut!',
      'intro':
          'Aku terlihat seperti gulungan asap abu-abu tebal yang turun dari puncak gunung. Walaupun dari jauh terlihat empuk seperti bantal kapas, aku sangat panas dan bergerak jauh lebih cepat dari mobil balap! Kalau melihatku dari kejauhan, kamu harus cepat-cepat menjauh.',
      'color': Colors.blueGrey,
      'tip':
          'Awan panas ini sering disebut Wedhus Gembel (Kambing Biri-biri) karena bentuknya keriting.',
      'quizQuestions': [
        {
          'question': 'Apakah nama awan berbahaya yang turun dari gunung berapi?',
          'answers': ['Awan Mendung Hujan', 'Awan Panas (Wedhus Gembel)', 'Awan Permen Kapas'],
          'correctIndex': 1,
          'explanation':
              'Benar sekali! Awan panas sangat mematikan karena suhunya tinggi dan bergerak sangat cepat.',
        },
        {
          'question': 'Mengapa awan panas disebut "Wedhus Gembel"?',
          'answers': [
            'Karena berbau seperti kambing',
            'Karena bentuknya keriting seperti bulu kambing',
            'Karena warnanya putih seperti kambing'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Awan panas disebut Wedhus Gembel karena bentuknya yang keriting-keriting seperti bulu kambing.',
        },
        {
          'question': 'Seberapa cepat awan panas bergerak?',
          'answers': [
            'Lambat seperti orang berjalan',
            'Lebih cepat dari mobil balap',
            'Secepat angin sepoi-sepoi'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Awan panas bergerak ratusan km/jam, jauh lebih cepat dari mobil balap manapun.',
        },
        {
          'question': 'Apa yang harus kamu lakukan jika melihat awan panas dari kejauhan?',
          'answers': [
            'Mendekat untuk melihat lebih jelas',
            'Merekam video untuk diunggah',
            'Segera berlari menjauh secepatnya'
          ],
          'correctIndex': 2,
          'explanation':
              'Tepat! Jika melihat awan panas, segera berlari menjauh. Jangan buang waktu untuk merekam atau berfoto!',
        },
        {
          'question': 'Meskipun awan panas terlihat seperti kapas, sebenarnya awan panas...',
          'answers': [
            'Lembut dan tidak berbahaya',
            'Sangat panas dan mematikan',
            'Dingin seperti salju'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Jangan tertipu penampilannya. Awan panas sangat panas dan sangat mematikan.',
        },
      ],
    },
    {
      'emoji': '🫨',
      'title': 'Bumi yang Menari-nari!',
      'intro':
          'Sebelum gunung berapi meletus, ia biasanya akan memberikan peringatan dengan menggoyangkan tanah tempat kita berpijak. Kaca jendela rumah bisa ikut bergetar, dan air di dalam gelas bisa bergoyang-goyang tumpah karenaku.',
      'color': Colors.brown,
      'tip':
          'Jika tanah bergoyang, segera lindungi kepalamu dengan tas atau berlindung di bawah meja yang kuat.',
      'quizQuestions': [
        {
          'question': 'Peristiwa tanah bergoyang sebelum gunung meletus disebut apa?',
          'answers': ['Gempa Bumi (Vulkanik)', 'Angin Topan Puting Beliung', 'Tanah Longsor'],
          'correctIndex': 0,
          'explanation':
              'Tepat! Gempa vulkanik adalah tanda peringatan bahwa gunung berapi akan meletus.',
        },
        {
          'question': 'Apa yang terjadi pada air di dalam gelas saat ada gempa kecil?',
          'answers': [
            'Air menjadi panas',
            'Air bergoyang-goyang dan bisa tumpah',
            'Air berubah warna'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Getaran dari gempa membuat air di dalam gelas ikut bergoyang bahkan bisa tumpah.',
        },
        {
          'question': 'Apa yang harus dilindungi pertama kali saat terjadi gempa?',
          'answers': ['Kaki', 'Kepala', 'Tangan'],
          'correctIndex': 1,
          'explanation':
              'Tepat! Kepala adalah bagian tubuh paling penting untuk dilindungi saat terjadi gempa.',
        },
        {
          'question': 'Di mana tempat paling aman saat terjadi gempa di dalam rumah?',
          'answers': [
            'Di dekat jendela kaca',
            'Di bawah meja yang kuat',
            'Di tengah ruangan terbuka'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Berlindung di bawah meja yang kuat dapat melindungimu dari benda-benda yang jatuh saat gempa.',
        },
        {
          'question': 'Gempa vulkanik adalah tanda bahwa...',
          'answers': [
            'Cuaca akan berubah menjadi hujan',
            'Gunung berapi kemungkinan akan meletus',
            'Ada badai besar yang datang'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Gempa vulkanik terjadi karena aktivitas magma di dalam gunung, pertanda gunung berapi bisa meletus.',
        },
      ],
    },
    {
      'emoji': '🥣',
      'title': 'Mangkuk Raksasa di Puncak!',
      'intro':
          'Kalau kamu terbang dengan helikopter dan melihat gunung berapi dari atas, puncaknya ternyata tidak runcing seperti segitiga, lho! Bagian atasku malah berlubang besar seperti mangkuk raksasa tempat keluarnya asap putih.',
      'color': Colors.amber,
      'tip':
          'Hanya tim ahli dan saintis yang boleh mendekati mangkuk raksasa ini demi keselamatan.',
      'quizQuestions': [
        {
          'question': 'Apakah nama mangkuk raksasa di puncak gunung berapi?',
          'answers': ['Danau Buatan', 'Kawah Gunung', 'Kolam Renang Puncak'],
          'correctIndex': 1,
          'explanation':
              'Luar biasa! Kawah adalah mulut gunung berapi tempat ia bisa memuntahkan isinya.',
        },
        {
          'question': 'Bagaimana bentuk puncak gunung berapi jika dilihat dari atas?',
          'answers': [
            'Runcing seperti segitiga sempurna',
            'Berlubang besar seperti mangkuk',
            'Datar seperti lapangan sepak bola'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Puncak gunung berapi memiliki kawah yang berlubang besar seperti mangkuk raksasa.',
        },
        {
          'question': 'Siapa yang boleh mendekati kawah gunung berapi?',
          'answers': [
            'Semua orang yang penasaran',
            'Hanya tim ahli dan ilmuwan gunung berapi',
            'Anak-anak yang berani'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Hanya tim ahli dan ilmuwan yang boleh mendekati kawah karena sangat berbahaya.',
        },
        {
          'question': 'Apa yang biasanya keluar dari kawah gunung berapi?',
          'answers': [
            'Air hujan dan angin',
            'Asap, gas, dan material vulkanik',
            'Pelangi dan awan putih biasa'
          ],
          'correctIndex': 1,
          'explanation':
              'Benar! Kawah gunung berapi mengeluarkan asap, gas berbahaya, dan material vulkanik seperti lava.',
        },
        {
          'question': 'Kawah gunung berapi terbentuk karena...',
          'answers': [
            'Digali oleh para petani',
            'Aktivitas letusan yang menciptakan lubang di puncak',
            'Terkena hujan sangat deras'
          ],
          'correctIndex': 1,
          'explanation':
              'Tepat! Kawah terbentuk dari aktivitas letusan berulang yang menciptakan lubang besar di puncak gunung.',
        },
      ],
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