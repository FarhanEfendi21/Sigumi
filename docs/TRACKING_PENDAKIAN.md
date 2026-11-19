# Fitur Tracking Pendakian SIGUMI

Dokumen ini menjelaskan cara menggunakan tracking pendakian SIGUMI dan bagaimana aplikasi menangani lokasi, rute, sesi, sinkronisasi, SOS, serta informasi cuaca. Nilai dan perilaku di bawah merujuk pada implementasi aplikasi dan migrasi Supabase yang tersedia saat dokumen ini ditulis.

## Ringkasan

Tracking pendakian merekam posisi GPS selama sesi aktif, menghitung durasi dan jarak, serta menampilkan posisi dan perpindahan terbaru pada peta. Area tracking yang didukung adalah:

| Wilayah aplikasi | Gunung | Pusat area tracking |
| --- | --- | --- |
| Bali | Gunung Agung | `-8.3433, 115.5071` |
| Lombok | Gunung Rinjani | `-8.4111, 116.4573` |

Sesi hanya dapat dimulai dengan GPS nyata yang masih baru dan berada dalam radius 15 km dari pusat gunung pada wilayah yang dipilih. Jika koneksi ke Supabase tidak tersedia, aplikasi tetap dapat merekam sesi secara lokal dan mengantrekan data untuk sinkronisasi.

## Panduan Penggunaan

### Membuka tracking

- Pengguna harus masuk ke akun SIGUMI. Pengguna tamu akan diarahkan ke layar masuk.
- Pilih wilayah Bali untuk Gunung Agung atau Lombok untuk Gunung Rinjani, lalu buka menu **Tracking Pendakian**.
- Layar tracking tersedia ketika wilayah dan lokasi GPS sesuai dengan area yang didukung, atau ketika aplikasi memulihkan sesi aktif/terjeda yang sudah ada.

### Memulai sesi

1. Aktifkan layanan lokasi/GPS dan izinkan akses lokasi yang diminta perangkat.
2. Pastikan GPS memperoleh posisi nyata terbaru di radius 15 km dari pusat Gunung Agung atau Rinjani.
3. Tekan **Mulai Tracking**. Aplikasi memulai sesi untuk wilayah terpilih, menampilkan statistik, peta, dan kontrol sesi.

GPS harus tersedia dan berada di area yang benar saat mulai. Batas akurasi maksimal 100 m digunakan untuk menerima titik selama sesi; syarat mulai memeriksa kesegaran posisi dan radius area.

### Mengelola sesi

- **Jeda Tracking** menghentikan pembaruan lokasi dan menghentikan hitungan durasi selama jeda.
- **Lanjutkan Tracking** memulai ulang GPS setelah aplikasi memperoleh posisi yang layak di dalam area. Titik sebelum dan sesudah jeda menjadi segmen rute terpisah.
- **Selesaikan Pendakian** meminta konfirmasi, merekam posisi terakhir yang masih valid bila tersedia, lalu mengakhiri sesi.
- **Reset Riwayat Tracking** meminta konfirmasi, membatalkan sesi aktif bila ada, dan menghapus riwayat tracking lokal sesi tersebut termasuk jarak, durasi, rute, serta titik yang belum terkirim.
- Menutup panel SOS tidak menghentikan sesi dan tidak membatalkan sinyal SOS.

## Beranda dan Layar Tracking

### Kartu tracking di beranda

Status kartu mengikuti wilayah yang dipilih dan wilayah sesi aktif:

- Jika wilayah terpilih sama dengan wilayah sesi, kartu menampilkan status aktif, durasi berjalan `jam:menit:detik`, dan jarak sesi.
- Jika sesi berjalan di wilayah lain, kartu tetap memakai tampilan normal/nonaktif dan memberi keterangan bahwa sesi masih aktif di Gunung Agung atau Gunung Rinjani. Berpindah wilayah tidak menghentikan sesi asal.
- Jika tidak ada sesi aktif, kartu menampilkan subtitle normal.

Jarak di bawah 1 km ditampilkan dalam meter bulat. Jarak 1 km atau lebih ditampilkan dalam kilometer dengan dua angka desimal. Tampilan ini berlaku pada statistik tracking; nilai penyimpanan tetap berupa kilometer.

### Peta dan statistik

Layar tracking menampilkan peta, titik posisi pengguna, penanda jalur/titik pendakian yang tersedia pada peta, serta statistik durasi dan jarak. Garis merah perpindahan pengguna adalah segmen bergerak antara dua titik tracking GPS terbaru yang diterima. Garis tersebut bukan keseluruhan jejak dari titik awal sesi. Garis tidak menghubungkan titik melintasi jeda, kehilangan GPS, atau pemisah segmen lainnya.

Durasi ditampilkan dengan jam, menit, dan detik. Durasi sesi tetap berjalan ketika GPS bermasalah atau saat menunggu toleransi geofence; durasi tidak menghitung waktu ketika sesi dijeda.

## GPS, Pencatatan, dan Geofence

### Kelayakan titik GPS

Titik untuk tracking diproses jika berasal dari GPS nyata, berumur maksimal 2 menit, dan akurasinya 100 m atau lebih baik. Pada tracking pendakian, filter jarak GPS adalah 5 m; pada Android interval permintaan posisi disetel sekitar 5 detik. Waktu kedatangan titik tetap dipengaruhi perangkat, kondisi sinyal, dan sistem operasi, sehingga interval tersebut bukan jaminan pembaruan tepat setiap 5 detik.

Titik duplikat dan timestamp yang tidak lebih baru dari titik sesi sebelumnya tidak dihitung ulang. Perpindahan yang mengimplikasikan kecepatan di atas 10 m/s ditolak agar lonjakan GPS tidak menambah jarak atau merusak garis rute. Jarak dihitung dari perpindahan antar titik tracking yang valid dan berurutan dalam segmen yang sama.

### Status area tracking

Radius area adalah 15 km. Penilaian memperhitungkan akurasi sebagai margin di sekitar batas:

- Aplikasi menyatakan posisi di luar jika jarak terukur melewati radius ditambah margin akurasi.
- Aplikasi menyatakan posisi di dalam jika jarak terukur berada di dalam radius dikurangi margin akurasi.
- Posisi di pita margin antara kedua batas tersebut belum meyakinkan dan tidak mengubah status area terakhir.

Sebelum beralih ke status luar area, aplikasi menunggu 3 fix layak berturut-turut yang mengonfirmasi posisi di luar. Setelah itu:

- Status menjadi **Di luar radius pendakian**, pencatatan titik ditahan, dan pengguna mendapat peringatan.
- Masa toleransi berlangsung hingga 2 menit. Jika 2 fix layak berturut-turut mengonfirmasi pengguna kembali ke dalam area, tracking dilanjutkan otomatis dan rute dimulai sebagai segmen baru.
- Jika toleransi habis sebelum pengguna kembali, sesi diakhiri otomatis.

### Status GPS

GPS tidak tersedia, fix sudah basi, atau akurasinya lebih buruk dari 100 m menghasilkan status **Sinyal GPS tidak tersedia atau tidak akurat**. Sesi dan durasinya tetap berjalan, tetapi pencatatan titik dan pembaruan garis ditahan sampai GPS pulih. Kondisi ini berbeda dari posisi yang dipastikan berada di luar radius: kehilangan GPS sendiri tidak memulai penghentian otomatis karena geofence.

Layar menampilkan alasan status; pada status luar area juga menampilkan jarak terhadap batas dan waktu toleransi tersisa. Saat aplikasi berada di latar belakang, perubahan status dapat menghasilkan notifikasi lokal jika notifikasi diaktifkan dan izin perangkat mengizinkannya. Android juga memakai notifikasi foreground selama tracking lokasi berjalan.

## Sesi, Rute, dan Pemulihan

- Sesi aktif, statistik, titik rute, segmen rute, dan informasi yang diperlukan untuk melanjutkan sesi disimpan lokal menggunakan `SharedPreferences`.
- Jeda, kehilangan GPS, posisi di luar radius, atau pemulihan dari gangguan memisahkan segmen rute. Jarak tidak ditambahkan melintasi jeda tersebut.
- Sesi yang dipulihkan saat aplikasi dibuka kembali mempertahankan durasi/riwayat, status toleransi luar area, jarak, dan segmen rute. Ketika GPS belum pulih, sesi tetap dapat dibuka dengan status yang sesuai.
- Data rute versi lama yang hanya berisi satu daftar titik dibaca sebagai satu segmen agar tetap kompatibel.
- Riwayat lokal dan antrean upload memungkinkan data sesi bertahan saat perangkat offline atau backend sementara gagal.

## Supabase dan Sinkronisasi

Tracking menggunakan tabel berikut:

| Tabel | Fungsi |
| --- | --- |
| `hiking_sessions` | Identitas, pemilik, status, waktu mulai/selesai, jarak, dan posisi terakhir sesi. |
| `hiking_track_points` | Titik GPS dengan waktu rekam, koordinat, dan akurasi. |
| `hiking_sos_alerts` | Sinyal SOS yang dikirim pengguna, status, sesi terkait, dan koordinatnya. |

Sesi dan titik yang belum tersinkron tetap berada pada antrean lokal. Aplikasi mencoba mengunggah sesi dan titik saat koneksi tersedia, menggunakan `client_session_id` dan `client_point_id` untuk mencegah duplikasi akibat retry. Kegagalan upload tidak seharusnya menghapus data lokal. Sesi lokal dapat dibuat menjadi sesi remote ketika autentikasi dan koneksi tersedia.

Migrasi menerapkan Row Level Security: sesi hanya dapat dibaca/dibuat/diperbarui oleh pemiliknya; titik hanya dapat dibaca atau dibuat jika terkait dengan sesi milik pengguna tersebut. Kredensial `service_role` tidak boleh ditempatkan di aplikasi klien.

## SOS Pendakian

Tombol SOS tersedia selama sesi aktif. Pengguna mengonfirmasi pengiriman sebelum panel bantuan dibuka. Sinyal dikaitkan dengan akun serta sesi aktif dan menyertakan lokasi GPS yang tersedia beserta waktu dan akurasi:

- Lokasi diambil dari GPS nyata terbaru jika tersedia di wilayah sesi; jika tidak, aplikasi menggunakan titik tracking terakhir yang tersimpan.
- Pengiriman memerlukan akun aktif, sesi tracking aktif, wilayah sesi yang diketahui, dan lokasi yang tersedia.
- Jika jaringan gagal, alert disimpan lokal untuk dicoba lagi. ID alert dipakai agar retry tidak membuat alert duplikat.
- Panel memperlihatkan status tersimpan di server atau menunggu pengiriman, waktu/umur lokasi, akurasi, serta koordinat.
- Pengguna dapat membagikan pesan SOS beserta koordinat dan tautan peta melalui fitur berbagi perangkat.

**Tersimpan di server tidak berarti petugas telah menerima atau mengonfirmasi SOS.** Gunakan kanal bantuan darurat yang tersedia secara langsung jika situasi membutuhkan pertolongan segera.

## Cuaca dan Peringatan

Layar tracking menyertakan kartu prakiraan cuaca BMKG berdasarkan posisi/wilayah yang didukung. Data prakiraan menggunakan wilayah desa sumber, bukan pengukuran langsung di jalur, kawah, atau ketinggian pendaki. Cuaca di ketinggian dapat berbeda. Ketersediaan data memerlukan layanan cuaca backend yang dikonfigurasi; aplikasi dapat menampilkan data cache atau pesan data tidak tersedia ketika permintaan gagal.

Backend juga dapat mengirim peringatan cuaca untuk sesi aktif jika posisi terakhir sesi memenuhi aturan alert dan cakupan poligonnya. Pengiriman berkala memerlukan Edge Function dan scheduler yang dikonfigurasi. Petunjuk deployment terpisah tersedia di [Panduan setup cuaca pendakian](./HIKING_WEATHER_SETUP.md).

## Izin dan Pemecahan Masalah

| Gejala | Kemungkinan penyebab | Langkah yang disarankan |
| --- | --- | --- |
| Tombol tracking gagal memulai | Wilayah bukan Bali/Lombok, GPS mati, posisi belum segar, atau posisi lebih dari 15 km dari pusat gunung | Aktifkan lokasi, pilih wilayah yang sesuai, tunggu GPS mendapatkan fix, lalu coba kembali di area yang didukung. |
| Status GPS bermasalah | GPS hilang, fix lebih tua dari 2 menit, atau akurasi lebih buruk dari 100 m | Pastikan layanan lokasi aktif, beri waktu perangkat mendapatkan sinyal yang lebih baik, dan hindari menutup izin lokasi aplikasi. Sesi tetap berjalan sementara titik ditahan. |
| Status luar radius dan hitung mundur muncul | Beberapa fix layak mengonfirmasi posisi di luar radius dengan margin akurasi | Kembali ke dalam area tracking. Dua fix di dalam area akan melanjutkan pencatatan otomatis; jika tidak, sesi berakhir setelah toleransi 2 menit. |
| Tracking berhenti saat aplikasi di latar belakang | Foreground service terhenti, notifikasi diblokir, atau batasan hemat baterai sistem operasi | Pastikan izin lokasi saat aplikasi digunakan serta notifikasi aktif agar Foreground Service Android (`FOREGROUND_SERVICE_LOCATION`) tetap berjalan selama sesi tracking. Di iOS, aplikasi meminta izin lokasi **Always** untuk tracking latar belakang. |
| Sesi terlihat aktif tetapi belum ada titik baru | GPS belum menghasilkan fix layak, belum ada perpindahan yang melewati filter perangkat, atau status pencatatan sedang ditahan | Periksa banner GPS/geofence dan tunggu fix berikutnya. Posisi hanya dicatat saat lolos pemeriksaan kualitas dan area. |
| Jarak belum berubah | Belum ada dua titik valid dalam segmen yang sama atau perpindahan tidak lolos validasi waktu/kecepatan | Tunggu beberapa pembaruan GPS yang valid. Jarak tidak diperbarui oleh titik basi, duplikat, lonjakan, atau titik saat pencatatan ditahan. |
| Data belum tampak di server | Perangkat offline, sesi lokal belum dapat dipasangkan ke akun, atau layanan Supabase gagal | Biarkan aplikasi aktif ketika koneksi kembali agar antrean dicoba sinkron. Data lokal/antrean digunakan sebagai penyangga selama gangguan koneksi. |
| SOS tertunda | Tidak ada jaringan atau lokasi tidak tersedia | Periksa koordinat/waktu lokasi di panel, coba kirim ulang saat online, atau bagikan lokasi melalui aplikasi lain. Status server tetap bukan konfirmasi penerimaan petugas. |
| Cuaca belum tersedia | Backend cuaca belum dikonfigurasi, koneksi gagal, atau wilayah tidak didukung | Periksa koneksi dan deployment Edge Function sesuai [panduan setup cuaca](./HIKING_WEATHER_SETUP.md). Jangan mengandalkan kartu sebagai pengamatan cuaca langsung di ketinggian. |

## Referensi Implementasi

- Logika sesi, geofence, pencatatan, antrean, pemulihan, dan SOS: `lib/services/hiking_tracking_service.dart`.
- GPS dan konfigurasi stream lokasi: `lib/services/location_service.dart`.
- Layar peta, status, kontrol sesi, dan statistik: `lib/screens/hiking/hiking_tracking_screen.dart`.
- Kartu tracking di beranda: `lib/screens/home/home_screen.dart`.
- Panel SOS dan berbagi lokasi: `lib/widgets/hiking_sos_panel.dart`.
- Skema sesi dan titik tracking: `supabase/migrations/20260915_create_hiking_tracking.sql`.
- Idempotensi titik dan skema alert SOS: `supabase/migrations/20261027_hiking_sos_and_idempotent_points.sql`.
- Skema cuaca: `supabase/migrations/20261028_hiking_weather.sql`.
