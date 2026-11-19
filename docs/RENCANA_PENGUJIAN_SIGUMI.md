# Rencana Pengujian SIGUMI

Dokumen ini adalah daftar cakupan dan panduan pengujian aplikasi SIGUMI sebelum rilis. Cakupan utamanya adalah aplikasi Flutter dan layanan backend yang dipakai aplikasi. Dokumen mencakup pengujian fungsi, integrasi, keamanan, aksesibilitas, ketahanan jaringan, serta load/stress test.

> **Penting:** Semua pengujian yang membuat data, mengirim notifikasi, atau menghubungi layanan eksternal harus memakai environment staging dan data sintetis. Jangan kirim SOS, laporan, atau pesan uji ke petugas dan pengguna nyata.

## 1. Tujuan

- Memastikan alur utama berjalan pada perangkat Android/iOS yang didukung.
- Memastikan data pengguna dan data keselamatan tetap benar saat jaringan buruk, aplikasi ditutup, atau request dicoba ulang.
- Mengetahui kapasitas backend pada beban normal, beban puncak, lonjakan mendadak, dan pemakaian berkelanjutan.
- Menemukan batas kapasitas serta komponen yang menjadi bottleneck sebelum rilis.
- Memastikan kegagalan layanan eksternal ditampilkan dengan jelas dan tidak membuat aplikasi macet atau mengklaim tindakan berhasil padahal belum tersimpan.

## 2. Cakupan Sistem

SIGUMI adalah aplikasi Flutter. Repository menunjukkan integrasi dengan Supabase Auth, Postgres/RPC, Edge Functions dan Storage; Firebase Cloud Messaging/notifikasi lokal; layanan chatbot Ollama; cuaca BMKG; data status gunung dari MAGMA; GPS dan peta; serta fitur suara/aksesibilitas.

Fitur yang masuk cakupan:

- Splash, onboarding, pemilihan bahasa, navigasi utama, pengaturan, dan profil/preferensi.
- Registrasi, OTP registrasi, login, logout, lupa/reset kata sandi, dan sesi autentikasi.
- Beranda, berita, ringkasan/status gunung, peta, lokasi, zona risiko, dan detail zona.
- Lokasi pengungsian/evakuasi serta kontak darurat.
- Pengiriman laporan termasuk unggah foto.
- Chatbot, percakapan, pemilihan bahasa, dan fallback.
- Edukasi, visual Merapi, informasi pascabencana, serta pariwisata.
- Tracking pendakian, GPS, sesi, titik rute, sinkronisasi tertunda, cuaca pendakian, dan SOS.
- Notifikasi push/lokal, text-to-speech, speech-to-text, audio guidance, dan fitur audio lain yang aktif pada build.
- Aksesibilitas: ukuran teks, kontras/warna, bahasa, dan navigasi dengan teknologi bantu.

Pengujian antarmuka backoffice bukan cakupan utama aplikasi mobile, tetapi alur yang bergantung padanya—misalnya alert SOS tampil di dashboard SAR—harus diuji ujung ke ujung bila sistem backoffice staging tersedia.

## 3. Prioritas Pengujian

| Prioritas | Arti | Contoh |
|---|---|---|
| P0 — Keselamatan | Kegagalan dapat menghilangkan atau menyesatkan informasi keselamatan | SOS, status bahaya gunung, lokasi, shelter, tracking dan pemulihan data |
| P1 — Alur utama | Fitur penting untuk penggunaan rutin atau akses akun | Login, beranda, peta, laporan, berita, cuaca |
| P2 — Pendukung | Fitur edukasi, kenyamanan, dan preferensi | Chatbot, edukasi, wisata, tema/bahasa, audio guidance |

Prioritas tidak menggantikan pengujian keamanan atau aksesibilitas. Risiko tinggi pada salah satu aspek harus ditangani sesuai dampaknya.

## 4. Jenis Pengujian

1. **Unit test:** logika model, validasi input, perhitungan jarak, status, retry, format tanggal/bahasa, dan transformasi respons.
2. **Widget/UI test:** status loading, kosong, sukses, gagal, validasi form, perpindahan layar, dan perubahan preferensi.
3. **Integration test aplikasi:** Flutter terhubung ke Supabase/Firebase/layanan uji untuk satu alur penuh.
4. **API/database test:** kontrak request/response, otorisasi, RLS, RPC, Edge Function, Storage, idempotensi, indeks, dan konsistensi data.
5. **End-to-end test:** alur pengguna pada perangkat fisik atau emulator, termasuk lifecycle aplikasi dan izin OS.
6. **Load/performance test:** kapasitas pada beban yang diperkirakan.
7. **Stress test:** beban dinaikkan melewati target secara bertahap untuk mengetahui titik degradasi; hentikan sesuai batas keselamatan yang sudah ditetapkan.
8. **Spike test:** beban melonjak dengan cepat lalu turun.
9. **Soak test:** beban dipertahankan cukup lama untuk menemukan kebocoran resource, antrean menumpuk, atau penurunan performa bertahap.
10. **Recovery/resilience test:** jaringan atau layanan diputus sementara, lalu dipulihkan untuk memeriksa retry, antrean lokal, dan konsistensi data.

## 5. Checklist Fitur dan Alur

### 5.1 Startup, onboarding, bahasa, dan navigasi

- [ ] Aplikasi dapat dibuka dari kondisi cold start dan warm start.
- [ ] Alur onboarding hanya tampil sesuai status penyelesaian dan dapat dilanjutkan/dilewati sesuai rancangan.
- [ ] Pilihan bahasa tersimpan setelah aplikasi ditutup dan dibuka kembali.
- [ ] Teks penting, pesan gagal, label status, tanggal, serta angka mengikuti bahasa yang dipilih.
- [ ] Navigasi tab dan tombol kembali tidak membuat layar ganda atau kehilangan status penting.
- [ ] Deep link/notifikasi (jika dikonfigurasi) menuju layar yang benar, termasuk ketika aplikasi mati atau berjalan di latar belakang.
- [ ] Tampilan tetap layak pada layar kecil/besar, orientasi yang didukung, dan ukuran teks besar.

### 5.2 Registrasi, login, sesi, dan reset kata sandi

- [ ] Registrasi dengan nomor telepon, kata sandi, dan data wajib yang valid.
- [ ] Nomor telepon diterima dalam format yang didukung dan dinormalisasi konsisten.
- [ ] Nomor duplikat, format salah, kata sandi terlalu pendek, atau field kosong ditolak dengan pesan yang jelas.
- [ ] Verifikasi OTP registrasi: kode benar, salah, kedaluwarsa, dikirim ulang, dan batas percobaan.
- [ ] Login benar/salah, logout, token kedaluwarsa, sesi dipulihkan setelah restart, serta akses tanpa sesi.
- [ ] Profil/preferences tertaut ke UUID pengguna yang sama setelah registrasi dan login.
- [ ] Reset kata sandi diuji untuk nomor/email pemulihan yang memenuhi syarat dan yang tidak memenuhi syarat.
- [ ] Respons reset tidak membocorkan apakah suatu akun terdaftar.
- [ ] OTP/tiket reset tidak dapat dipakai ulang; percobaan salah, kedaluwarsa, dan rate limit tidak mengubah kata sandi.
- [ ] Gangguan jaringan saat OTP diminta atau diverifikasi menampilkan status yang akurat dan tidak membuat akun/challenge ganda.

### 5.3 Beranda, status gunung, berita, dan informasi

- [ ] Beranda menampilkan status gunung, informasi terbaru, berita, dan kartu fitur dengan data yang sesuai.
- [ ] Kondisi loading, data kosong, data lama, respons rusak, dan kegagalan server ditangani.
- [ ] Waktu pembaruan/freshness terlihat atau dapat dibedakan dari data terbaru bila tersedia.
- [ ] Membuka berita, kembali, dan membuka berita lain tidak menampilkan konten yang tertukar.
- [ ] Pembaruan status berulang tidak membuat notifikasi atau item duplikat.
- [ ] Setelah lonjakan pembacaan, data yang disimpan server tetap konsisten dan UI tidak membeku.

### 5.4 Peta, GPS, zona risiko, dan evakuasi

- [ ] Izin lokasi diberikan, ditolak, ditolak permanen, layanan lokasi dimatikan, atau izin berubah dari Settings.
- [ ] Lokasi tidak tersedia, basi, tidak akurat, berubah cepat, atau berada di luar area layanan.
- [ ] Peralihan dari lokasi manual ke GPS nyata serta sebaliknya menampilkan sumber lokasi dengan benar.
- [ ] Penentuan gunung terdekat, jarak, zona risiko, status, dan detail zona sesuai titik uji yang diketahui.
- [ ] Koordinat batas zona dan koordinat yang berada tepat di sekitar batas diuji untuk kesalahan pembulatan/geometri.
- [ ] RPC shelter terdekat mengembalikan shelter yang benar berdasarkan radius dan urutan jarak; kondisi tanpa hasil juga diuji.
- [ ] Peta menangani tile lambat/gagal, zoom/pan berulang, kehilangan koneksi, dan pergantian lokasi tanpa freeze.
- [ ] Panggilan ke tile server atau layanan peta pada test beban mengikuti izin dan batas penggunaan penyedia; gunakan cache atau endpoint staging bila tersedia.

### 5.5 Kontak darurat dan laporan pengguna

- [ ] Daftar kontak darurat tampil saat online dan memberi status yang jelas saat data gagal dimuat.
- [ ] Tombol telepon membuka dialer dengan nomor yang benar; pengujian tidak melakukan panggilan nyata.
- [ ] Laporan valid tersimpan dengan kategori, judul, deskripsi, lokasi, dan identitas yang sesuai.
- [ ] Validasi laporan untuk field kosong/panjang berlebih dan lokasi tidak tersedia.
- [ ] Foto laporan: izin kamera/galeri, batal memilih, format/ukuran file, upload sukses, timeout, gagal upload, serta submit tanpa foto jika didukung.
- [ ] Retry setelah timeout tidak membuat laporan duplikat; bila idempotensi belum ada, catat sebagai risiko untuk diputuskan sebelum rilis.
- [ ] Periksa akses baca/tulis laporan menggunakan akun berbeda dan role yang berbeda.
- [ ] Pastikan log aplikasi tidak mencatat nomor telepon, koordinat rinci, token, atau isi laporan sensitif secara berlebihan.

### 5.6 Chatbot dan fitur bahasa

- [ ] Mengirim pesan, menerima jawaban, menampilkan loading, mengirim pesan berurutan, dan memulihkan percakapan sesuai perilaku yang dirancang.
- [ ] Jawaban kosong, format JSON tidak valid, status HTTP bukan sukses, timeout, koneksi putus, dan kredensial salah ditangani.
- [ ] Fallback lokal/rule-based digunakan bila layanan cloud gagal dan tidak menyatakan bahwa jawaban berasal dari sumber resmi bila bukan.
- [ ] Uji bahasa yang didukung, percakapan panjang, prompt/payload besar, dan batas panjang jawaban.
- [ ] Uji beban Ollama secara terpisah dari Postgres/Supabase karena komputasi generasi model memiliki kapasitas dan bottleneck sendiri.
- [ ] Pastikan prompt, kata sandi Basic Auth, dan kredensial tidak dicetak ke log atau artefak build.

### 5.7 Edukasi, visual, pascabencana, dan pariwisata

- [ ] Daftar dan detail edukasi terbuka, kuis/interaksi tersimpan atau kembali sesuai desain, dan konten mock/remote dibedakan.
- [ ] Visual Merapi/webview menangani loading, konten tidak tersedia, koneksi lambat, orientasi, dan keluar dari layar.
- [ ] Informasi pascabencana serta pariwisata dapat dibuka, digulir, dan diterjemahkan sesuai bahasa.
- [ ] Gambar/konten berat tidak membuat penggunaan memori meningkat terus atau layar lama tidak responsif.
- [ ] Ketika sumber konten eksternal gagal, aplikasi menampilkan fallback atau status yang jelas.

### 5.8 Tracking pendakian, cuaca, dan SOS

- [ ] Sesi tracking hanya dapat dimulai oleh akun yang sesuai, dengan GPS nyata yang baru dan posisi dalam radius area yang ditetapkan.
- [ ] Izin GPS, GPS mati, timestamp basi, akurasi buruk, titik duplikat, timestamp mundur, lonjakan GPS, dan lokasi yang bergerak di luar area diuji.
- [ ] Jeda, lanjutkan, selesai, auto-stop, pemulihan sesi setelah force close/restart, serta perpindahan wilayah diuji.
- [ ] Perhitungan jarak dan waktu tidak bertambah saat pause atau melintasi segmen yang terputus.
- [ ] Titik dan sesi yang dibuat saat offline tetap tersimpan lokal dan tersinkron saat jaringan kembali.
- [ ] Retry upload memakai `client_session_id` dan `client_point_id` sehingga data tidak berlipat; pastikan jumlah titik unik sama dengan titik uji.
- [ ] Gangguan saat sebagian titik berhasil dan sebagian gagal tidak menghapus antrean yang belum berhasil.
- [ ] SOS membutuhkan konfirmasi sesuai UI, terkait dengan sesi/pengguna dan lokasi yang tepat, serta membuat satu alert untuk satu `client_alert_id`.
- [ ] SOS offline ditandai sebagai antrean lokal, bukan sukses diterima server; status sukses baru tampil setelah server mengonfirmasi.
- [ ] Uji event SOS muncul pada dashboard SAR staging, reconnect/reload, status acknowledgment/resolved, dan event duplikat.
- [ ] Lokasi stale atau akurasi lemah ditandai secara jujur pada tampilan penerima SOS.
- [ ] Cuaca pendakian menguji cache, timezone/label wilayah, respons BMKG lambat/gagal, dan data forecast kosong.
- [ ] Notifikasi foreground tracking berjalan sesuai izin OS dan berhenti setelah sesi selesai.

### 5.9 Notifikasi, audio, dan aksesibilitas

- [ ] Izin notifikasi ditolak/diizinkan, token FCM baru, token berubah, logout, dan token gagal tersimpan.
- [ ] Notifikasi foreground/background/terminated membuka tujuan yang benar dan tidak membuat navigasi rusak.
- [ ] Notifikasi uji hanya dikirim ke perangkat/token staging.
- [ ] TTS, speech-to-text, wake word, dan klasifikasi audio diuji pada perangkat yang didukung, termasuk izin mikrofon, tanpa izin, lingkungan bising, dan tanpa koneksi bila model lokal digunakan.
- [ ] Pengguna dapat menghentikan audio; tidak ada rekaman yang tertinggal aktif tanpa indikator.
- [ ] Ukuran huruf, kontras, mode buta warna, pembaca layar, fokus keyboard, label tombol, dan target sentuh diperiksa.
- [ ] Perubahan preferensi tetap tersimpan setelah restart dan tidak membuat layout terpotong.

### 5.10 Pengaturan dan privasi akun

- [ ] Bahasa, wilayah, ukuran font, kontras, audio guidance, dan preferensi notifikasi disimpan konsisten.
- [ ] Preferensi lokal tetap berfungsi saat Supabase sementara tidak tersedia; perubahan tersinkron saat koneksi pulih bila memang dirancang begitu.
- [ ] Logout menghapus akses sesi dari UI dan mencegah akun berikutnya melihat data lokal pribadi yang tidak semestinya.
- [ ] Sesi/data pribadi tidak muncul pada akun berbeda, termasuk cache, data profil, laporan, tracking, dan notifikasi.

## 6. Rencana Load dan Stress Test

### 6.1 Bentuk workload realistis

Jangan mengulang satu request yang sama untuk semua virtual user. Bentuk campuran alur dan pola tunggu (think time) yang mendekati penggunaan nyata. Gunakan akun sintetis yang berbeda agar uji tidak hanya mengukur cache atau sesi yang sama.

| Profil trafik | Aktivitas yang disimulasikan | Komponen yang perlu diamati |
|---|---|---|
| Hari biasa | Membuka beranda, membaca status/berita, melihat peta/shelter, mengubah bahasa | Supabase Postgres/RPC, gateway, cache, layanan peta |
| Peringatan gunung | Banyak pengguna membuka beranda dan peta hampir bersamaan, lalu melihat zona/shelter | Burst read, koneksi database, query lokasi, push delivery terpisah |
| Pendaki aktif | Banyak sesi GPS berjalan dan mengirim titik berkala | Insert titik, update sesi, pool koneksi, ukuran antrean, baterai/performa perangkat |
| Banyak laporan | Pengguna mengirim laporan dan sebagian mengunggah foto | Database insert, Storage, ukuran payload, timeout dan retry |
| Chatbot ramai | Pengguna mengirim pertanyaan dengan panjang percakapan berbeda | CPU/GPU dan antrean Ollama, waktu jawaban, timeout, batas concurrency |
| Pemulihan koneksi | Banyak perangkat kembali online dan menguras antrean lokal | Lonjakan upload, deduplikasi, durasi drain antrean, error berulang |

Dokumentasi tracking repo menyebut interval lokasi Android sekitar 5 detik. Dengan asumsi setiap fix valid diterima dan tersinkron, satu perangkat dapat menghasilkan hingga sekitar 12 titik per menit. Maka 100 pendaki aktif berpotensi menghasilkan sekitar 1.200 titik per menit; implementasi juga memperbarui baris sesi setelah unggah titik. Gunakan angka ini sebagai model awal untuk mengukur beban tulis, lalu sesuaikan dengan perilaku aktual GPS, filter titik, dan batching.

### 6.2 Profil pelaksanaan

Sebelum uji, pemilik produk/backend harus mengisi target kapasitas (pengguna aktif dan pendaki aktif) serta ambang lulus. Jangan memilih jumlah virtual user tanpa menghubungkannya dengan proyeksi trafik.

1. **Smoke:** satu sampai beberapa pengguna virtual untuk memastikan skrip dan data uji valid.
2. **Baseline:** beban rendah untuk mengambil waktu respons awal dan memeriksa metrik sistem.
3. **Ramp-up/load:** naikkan beban perlahan ke target pengguna puncak dan tahan cukup lama untuk melihat kestabilan.
4. **Stress:** naikkan beban bertahap di atas target hingga ambang kegagalan yang ditetapkan atau batas operasional staging tercapai.
5. **Spike:** lonjakan cepat ke beban puncak yang disepakati; amati apakah layanan pulih setelah trafik turun.
6. **Soak:** pertahankan beban realistis selama beberapa jam untuk mengamati memori, koneksi, antrean, dan degradasi performa.
7. **Recovery:** hentikan beban/putuskan dependensi staging secara terkontrol, lalu pulihkan dan ukur durasi hingga sistem normal.

Untuk tiap profil, jalankan fitur berat secara terpisah terlebih dahulu, kemudian jalankan skenario gabungan. Jangan lakukan stress test ke MAGMA, BMKG, FCM, tile server publik, atau layanan produksi pihak ketiga tanpa izin dan batas trafik yang disepakati. Gunakan mock/stub atau endpoint staging bila tersedia.

Postman CLI dapat menjalankan performance test dari collection dengan virtual users dan pola ramp-up. Collection yang ada di `postman/` dapat dijadikan dasar kontrak API; skenario harus diperluas dengan request dan data unik untuk alur Supabase, tracking, SOS, laporan, dan layanan lain. Jalankan load test dari mesin yang kapasitasnya memadai agar generator beban tidak menjadi bottleneck. [Dokumentasi performance test Postman CLI](https://learning.postman.com/docs/postman-cli/postman-cli-run-performance-test/).

## 7. Metrik yang Dicatat

### Backend/API

- Throughput (request/detik dan operasi database/detik) per alur.
- Latensi p50, p95, dan p99; pisahkan waktu gateway, query/database, Edge Function, Storage, dan Ollama bila instrumentasi tersedia.
- Tingkat timeout, HTTP error, retry, koneksi putus, dan respons parsial.
- CPU, memori, koneksi aktif/pool, query lambat, lock, disk/IO, dan antrean.
- Jumlah event/titik/laporan/SOS yang benar-benar tersimpan dibandingkan jumlah unik yang dikirim.
- Waktu drain antrean setelah koneksi pulih dan jumlah duplikasi yang dicegah.

### Aplikasi/perangkat

- Waktu cold start dan waktu layar kritis siap digunakan.
- Frame drop/jank, crash, ANR, penggunaan memori, CPU, baterai, dan penggunaan data.
- Frekuensi kegagalan GPS, izin, geofence, background execution, dan notifikasi.
- Perilaku UI saat loading/error/offline serta akurasi status yang disampaikan ke pengguna.

### Ambang kelulusan

Sebelum pelaksanaan, isi nilai target bersama tim produk, backend, dan operasi. Tentukan minimal:

- Beban target: `_____ pengguna bersamaan`, termasuk `_____ pendaki aktif`.
- Latensi p95/p99 untuk baca, tulis laporan, tracking, cuaca, dan SOS: `_____`.
- Error/timeout maksimal pada beban target: `_____%`.
- Waktu maksimal alert SOS sampai terlihat di backoffice staging: `_____`.
- Persentase data hilang/duplikat yang dapat diterima: untuk titik dan alert keselamatan targetnya **0 data hilang dan 0 alert duplikat** setelah retry yang valid.
- Waktu pemulihan layanan dan pengurasan antrean: `_____`.
- Ambang stop test: error/latensi/CPU/koneksi yang melampaui batas operasional staging.

Jangan menyatakan sistem siap berdasarkan rata-rata latensi saja. Evaluasi p95/p99, error, integritas data, dan perilaku pemulihan bersama-sama.

## 8. Matriks Perangkat dan Kondisi Jaringan

Uji setidaknya satu perangkat Android kelas menengah dengan OS minimum yang didukung dan satu perangkat kelas lebih baru; tambahkan iOS bila build iOS termasuk rilis. Catat model perangkat, versi OS, versi aplikasi, izin, dan kondisi baterai.

| Kondisi | Yang perlu diverifikasi |
|---|---|
| Wi-Fi stabil | Baseline alur normal dan pemuatan peta/konten |
| Jaringan seluler dengan latensi tinggi | Loading, timeout, retry, dan umpan balik UI |
| Bandwidth rendah | Payload besar, gambar, peta, dan chatbot |
| Jaringan putus saat baca/tulis | Data lokal, pesan error, tidak ada klaim sukses palsu |
| Jaringan pulih | Retry, antrean, deduplikasi, dan durasi sinkronisasi |
| Aplikasi background/force close | Tracking, notifikasi OS, sesi aktif, dan pemulihan saat dibuka kembali |
| GPS lemah/tidak ada | Status lokasi, titik invalid, dan pesan keselamatan yang jujur |

Virtual user menguji layanan server; virtual user tidak menguji konsumsi baterai, GPS nyata, atau kelancaran Flutter. Pengujian perangkat tetap diperlukan.

## 9. Keamanan dan Perlindungan Data Uji

- [ ] Gunakan environment, database, akun, bucket Storage, dan kredensial staging terpisah dari produksi.
- [ ] Pakai akun serta koordinat sintetis; batasi akses log dan hapus data uji sesuai prosedur.
- [ ] Verifikasi RLS: pengguna tidak dapat membaca/mengubah profil, laporan, sesi tracking, titik, atau SOS milik pengguna lain.
- [ ] Pastikan service-role key, password Ollama, token, OTP, dan data sensitif tidak masuk source client, log, screenshot, atau hasil CI.
- [ ] Uji rate limit pada login, reset OTP, chatbot, dan endpoint yang dapat disalahgunakan.
- [ ] Pastikan error tidak mengungkap token, stack trace, query rahasia, atau keberadaan akun.
- [ ] Jangan menguji layanan eksternal atau alamat produksi dengan traffic besar tanpa izin tertulis dan rencana rollback.

**Catatan konfigurasi repo:** README saat ini mencantumkan gateway Supabase VPS dengan HTTP. Karena HTTP tidak mengenkripsi kredensial dan token sesi, pengujian dengan akun nyata atau penggunaan rilis harus menunggu penggunaan HTTPS/TLS. Untuk stress test, gunakan staging; jangan mengirim kredensial nyata lewat koneksi HTTP.

## 10. Rencana Bukti dan Pelaporan

Untuk setiap run, simpan:

- ID run, tanggal/waktu dan zona waktu, commit/build aplikasi, environment, konfigurasi server, serta versi OS/perangkat.
- Skenario, jumlah akun/virtual user, ramp-up, durasi, think time, volume data, dan batas stop.
- Grafik latensi p50/p95/p99, throughput, error, CPU/memori/database, antrean, serta catatan perangkat.
- Jumlah data unik yang dibuat, jumlah yang terlihat pada database/backoffice, duplikasi, dan kehilangan data.
- Gangguan yang sengaja disimulasikan dan waktu pemulihan.
- Defect, severity, langkah reproduksi, bukti tanpa data pribadi, pemilik, dan hasil retest.

Jangan menyimpan nomor telepon, token, OTP, isi pesan pribadi, atau koordinat pendaki nyata pada laporan uji.

## 11. Kriteria Siap Rilis

- Seluruh test P0 lulus pada staging, termasuk skenario offline/retry untuk tracking dan SOS.
- Tidak ada kehilangan/duplikasi data keselamatan pada pengujian retry dan pemulihan.
- RLS dan otorisasi terverifikasi dengan akun berbeda.
- Beban target yang disepakati tercapai tanpa melewati ambang latensi/error/kapasitas.
- Hasil spike/soak menunjukkan layanan pulih dan tidak mengalami degradasi berkelanjutan.
- Alur utama diuji pada perangkat fisik dan kondisi jaringan yang mewakili pengguna.
- Semua masalah P0/P1 diperbaiki atau memiliki keputusan risiko tertulis dari pemilik produk/operasi.
- Build yang diuji menggunakan konfigurasi aman untuk rilis; tidak memakai endpoint HTTP untuk autentikasi/token.

## 12. Status Pengujian

Isi tabel ini setiap kali pengujian dijalankan.

| Area | Status | Tanggal/build | Bukti atau tiket | Catatan |
|---|---|---|---|---|
| Startup, onboarding, bahasa, navigasi | Diuji sebagian (smoke) | 2026-11-13 | `test/widget_test.dart` | Smoke startup lulus |
| Registrasi, OTP, login, sesi, reset | Belum diuji |  |  |  |
| Beranda, berita, status gunung | Belum diuji |  |  |  |
| Peta, lokasi, zona risiko, shelter | Diuji (stress kalkulasi & lifecycle) | 2026-11-13 | `test/mobile_stress_test.dart` (P1 Stress 4) | 1.000 transisi batas zona (5/10/15/40 km), singleton tahan `dispose()`, RPC location throttled |
| Laporan dan unggah foto | Diperkuat (kode) | 2026-11-13 | `lib/screens/report/report_screen.dart`, `lib/repositories/report_repository.dart` | Guard double-tap submit, cache URL foto saat retry, sanitasi log sensitif |
| Kontak darurat | Belum diuji |  |  |  |
| Chatbot dan fallback | Diuji (API + stress fallback) | 2026-11-13 | `docs/REKAP_PENGUJIAN_CHATBOT_POSTMAN.md`, `test/mobile_stress_test.dart` (P2 Stress 5) | 25 uji Postman (rata-rata 68,87 s) + 25 request konkuren (503/timeout/JSON rusak) lulus fallback ke `RuleBasedFallback` |
| Edukasi, visual, pascabencana, wisata | Belum diuji |  |  |  |
| Tracking pendakian dan recovery offline | Diuji (stress & recovery) | 2026-11-13 | `test/hiking_tracking_service_test.dart`, `test/mobile_stress_test.dart` (P0 Stress 1 & 3) | 1.440 titik offline (~128 ms rekam), cold-start restore, koneksi putus mid-batch, batch drain 100 titik/request (~23 ms, 15 batch, 0 hilang, 0 duplikat) |
| SOS dan alur SAR staging | Diuji (stress client & dedup) | 2026-11-13 | `test/mobile_stress_test.dart` (P0 Stress 2) | 50 rapid-tap SOS offline + 20 retry konkuren menghasilkan tepat 1 alert unik (`0 alert duplikat`); uji E2E dashboard SAR menunggu staging |
| Cuaca, notifikasi, audio | Diuji sebagian (cache cuaca) | 2026-11-13 | `test/hiking_weather_test.dart` | Cache & fallback stale cuaca lulus |
| Aksesibilitas dan perangkat | Belum diuji |  |  |  |
| Keamanan/RLS/privasi | Diperkuat sebagian | 2026-11-13 | `lib/repositories/report_repository.dart`, `postman/sigumi_chatbot_collection.json` | Log laporan disanitasi; kredensial hardcoded dihapus dari collection Postman |
| Load, stress, spike, soak, recovery | Diuji (mobile) & Siap (backend staging) | 2026-11-13 | `test/mobile_stress_test.dart`, `postman/sigumi_mobile_backend_stress_collection.json` | Stress test on-device/service lulus; collection beban Supabase staging siap dijalankan via Postman CLI |

## 13. Catatan Cakupan Otomasi Saat Ini

Repository memiliki pengujian otomatis Flutter dan kontrak Postman:
- `test/mobile_stress_test.dart`: Suite stress & ketahanan aplikasi mobile (burst 1.440 titik GPS offline + recovery mid-batch + cold-start restore, 50x rapid-tap SOS offline & 20x retry konkuren, fluktuasi sinyal GPS ekstrem/timestamp mundur/geofence grace period, ketahanan singleton `LocationService` pada 1.000 kalkulasi zona risiko, serta 25 request konkuren `ChatbotEngine` dengan injeksi kegagalan HTTP 503/timeout/JSON rusak).
- `test/hiking_tracking_service_test.dart` & `test/hiking_weather_test.dart`: Unit test pergerakan real-time, recovery sinyal GPS, serta model/cache cuaca.
- `postman/sigumi_mobile_backend_stress_collection.json`: Collection uji beban backend Supabase staging (burst baca beranda/shelter/cuaca, upsert sesi & batch 12 titik/menit dengan verifikasi idempotensi `client_point_id`, serta SOS/laporan sintetis).
- `postman/sigumi_chatbot_collection.json` & `docs/REKAP_PENGUJIAN_CHATBOT_POSTMAN.md`: Pengujian 5 bahasa ke server Ollama.

Sebelum jadwal rilis, jalankan `postman/sigumi_mobile_backend_stress_collection.json` terhadap environment staging menggunakan `postman performance run`, lalu tambahkan verifikasi RLS antar-akun dan E2E dashboard SAR pada staging.

Dokumen ini adalah rencana cakupan, bukan bukti bahwa semua test sudah dijalankan atau bahwa backend produksi siap menerima traffic uji. Catat konfigurasi environment dan hasil aktual pada bagian Status Pengujian.
