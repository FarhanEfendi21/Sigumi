# PRD: Reset Kata Sandi SIGUMI

| Atribut | Nilai |
|---|---|
| Status | Draft untuk ditinjau |
| Tanggal | 5 Oktober 2026 |
| Pemilik | Tim Produk SIGUMI |
| Audiens | Produk, Flutter, backend, operasi Supabase, dan backoffice |
| Cakupan | Pendaftaran email pemulihan, verifikasi, reset kata sandi, dan pengelolaan status |

## 1. Ringkasan

SIGUMI menampilkan nomor telepon sebagai identitas pengguna. Saat ini nomor tersebut dipetakan secara internal ke email sintetis dengan domain sigumi.app untuk Supabase Auth. Email sintetis tidak dapat menerima pesan, sehingga tidak dapat menjadi tujuan reset kata sandi.

Fitur ini menambahkan email aktif sebagai kanal pemulihan saja. Pengguna tetap mendaftar dan masuk menggunakan nomor telepon serta kata sandi. Email dikumpulkan dan diverifikasi saat pendaftaran, tetapi bukan username atau metode login. Saat lupa kata sandi, pengguna memvalidasi kode enam digit yang dikirim ke email terverifikasi, lalu menetapkan kata sandi baru.

Email pemulihan berbeda dari email sintetis Auth, jadi verifikasi dan pengubahan kata sandi harus dimediasi backend tepercaya. Semua perubahan akun mempertahankan UUID Auth yang menjadi penghubung profil dan data pengguna.

## 2. Masalah dan Tujuan

### Masalah

- Pengguna tidak memiliki cara pemulihan kata sandi mandiri.
- Alamat sintetis internal tidak dapat diakses pengguna.
- Tombol Lupa Kata Sandi? pada Login dan Reset Kata Sandi pada Profil belum terhubung ke alur pemulihan.
- Akun lama belum tentu memiliki kanal pemulihan terverifikasi.

### Tujuan

1. Pengguna baru menyelesaikan pendaftaran dengan nomor telepon, kata sandi, dan email pemulihan terverifikasi.
2. Pengguna yang lupa kata sandi dapat memulihkannya sendiri melalui email tersebut.
3. Login tetap berbasis nomor telepon; email hanya untuk recovery.
4. Profil, laporan, tracking, dan data terkait tetap tertaut ke UUID pengguna yang sama.
5. Backoffice dapat melihat status kanal pemulihan tanpa melihat kata sandi atau kode OTP.

### Ukuran keberhasilan

- Tingkat penyelesaian dan waktu verifikasi email saat pendaftaran.
- Persentase OTP yang berhasil dikirim dan diterima.
- Tingkat penyelesaian proses reset.
- Jumlah permintaan bantuan dari akun lama tanpa email pemulihan.
- Jumlah permintaan yang dibatasi karena abuse, serta insiden enumerasi akun.

### Bukan tujuan rilis ini

- Mengubah login dari nomor telepon menjadi email.
- Login tanpa kata sandi atau pemulihan melalui SMS.
- Admin mengatur atau melihat kata sandi pengguna.
- Menghapus dan membuat ulang akun Auth yang sudah ada.
- Fitur ubah kata sandi rutin ketika pengguna masih ingat kata sandi lama.

## 3. Pengguna dan Prinsip Pengalaman

### Pengguna utama

- Pendaftar baru yang menambahkan email untuk pemulihan.
- Pengguna yang lupa kata sandi tetapi masih dapat membuka email pemulihannya.
- Pengguna lama yang perlu menambahkan email sebelum reset mandiri tersedia.
- Admin yang memantau status kontak pemulihan.

### Prinsip UX

- Jelaskan bahwa email hanya digunakan untuk verifikasi dan pemulihan, bukan login.
- Gunakan bahasa ramah, ringkas, dan aksesibel sesuai bahasa aplikasi.
- Jangan mengungkap apakah nomor telepon terdaftar atau apakah kode terkirim.
- Jangan tampilkan alamat email lengkap pada layar reset.
- Berikan status kirim ulang, waktu tunggu, kode salah, kode kedaluwarsa, serta kegagalan jaringan dengan instruksi yang dapat ditindaklanjuti.

## 4. Kondisi Saat Ini dan Batasan

- Form login dan pendaftaran menggunakan nomor telepon; repository memetakannya ke email sintetis untuk Supabase Auth.
- Tabel profiles memakai UUID yang sama dengan auth.users.id. Data pendakian juga mengacu ke UUID tersebut.
- Trigger pembuatan profil mengambil nama dan nomor telepon dari metadata/Auth.
- Tombol Lupa Kata Sandi? di Login dan Reset Kata Sandi di Profil saat ini hanya tampilan tanpa aksi.
- resetPasswordForEmail bawaan Supabase mengirim ke alamat email yang melekat pada akun Auth. Metode itu tidak cocok untuk email pemulihan yang disimpan terpisah.
- Supabase berjalan di VPS. Produksi membutuhkan SMTP transaksional, domain pengirim terverifikasi, HTTPS/TLS, dan pemantauan pengiriman.

## 5. Alur Produk

### 5.1 Pendaftaran dan verifikasi email pemulihan

1. Form meminta nama, nomor telepon, kata sandi, dan email pemulihan.
2. UI menerangkan bahwa email tidak digunakan untuk login.
3. Backend memulai challenge dan mengirim OTP enam digit.
4. Pengguna memasukkan OTP pada aplikasi.
5. Setelah backend memverifikasi OTP, pengguna dapat menyelesaikan pendaftaran.
6. Akun tidak boleh memiliki akses authenticated sebelum email pemulihan terverifikasi.
7. Pengguna kemudian masuk menggunakan nomor telepon dan kata sandi.

Verifikasi harus ditegakkan backend, bukan hanya disembunyikan di UI. Akun tidak boleh dapat dibuat melalui jalur alternatif tanpa bukti verifikasi yang sah.

### 5.2 Reset dari Login

1. Pengguna memilih Lupa Kata Sandi? dan memasukkan nomor telepon.
2. Backend mencari akun dan email pemulihan secara server-side.
3. Jika akun memiliki email terverifikasi, backend mengirim OTP ke alamat tersebut.
4. UI selalu menampilkan respons generik yang sama, misalnya: “Jika akun memiliki email pemulihan terverifikasi, instruksi akan dikirim.”
5. UI tidak memperlihatkan apakah nomor terdaftar maupun email tujuan lengkap.

### 5.3 Verifikasi kode dan perubahan kata sandi

1. Pengguna memasukkan kode enam digit.
2. Backend memvalidasi kode dan menerbitkan otorisasi reset singkat, sekali pakai, dan terikat ke satu UUID.
3. Pengguna mengisi kata sandi baru dan konfirmasi.
4. Backend memvalidasi kebijakan kata sandi, mengubah kata sandi Auth, mengonsumsi otorisasi reset, dan membatalkan sesi lama sesuai kemampuan konfigurasi Auth.
5. Aplikasi menampilkan sukses dan mengarahkan pengguna ke Login dengan nomor telepon.

Kode yang salah, kedaluwarsa, atau sudah dipakai tidak boleh mengubah kata sandi. Otorisasi reset tidak boleh menjadi sesi login normal.

### 5.4 Reset dari Profil

Baris Reset Kata Sandi di bagian Keamanan Akun membuka alur reset yang sama seperti Login. Kepemilikan email tetap harus diverifikasi meskipun pengguna sedang login.

### 5.5 Perubahan email pemulihan

- Profil menampilkan email dalam bentuk tersamarkan dan status verifikasinya.
- Perubahan email memerlukan OTP yang dikirim ke alamat baru.
- Email lama tetap menjadi kanal aktif sampai email baru berhasil diverifikasi.
- Setelah perubahan, kirim notifikasi keamanan ke email lama bila tersedia.
- Backend mengambil UUID dari sesi tervalidasi, bukan dari UUID yang dikirim klien.

### 5.6 Akun lama

- Pengguna lama tetap dapat login dengan nomor telepon selama masa transisi.
- Saat masih login, pengguna diminta menambahkan serta memverifikasi email di Profil sebelum dapat memakai reset mandiri.
- Reset mandiri tidak tersedia untuk akun lama tanpa email terverifikasi. Pesan menjelaskan cara menambahkannya ketika masih dapat login.
- Jika pengguna sudah terkunci, tampilkan kanal bantuan resmi SIGUMI. Bantuan harus memverifikasi kepemilikan akun; admin tidak meminta kata sandi atau OTP.
- Peluncuran memerlukan kanal bantuan yang aktif untuk akun lama yang terkunci.

## 6. Persyaratan Fungsional

| ID | Persyaratan |
|---|---|
| FR-01 | Pendaftaran meminta nomor telepon, kata sandi, dan email pemulihan yang valid. |
| FR-02 | Pendaftaran belum lengkap sampai email pemulihan diverifikasi. |
| FR-03 | Email pemulihan bukan metode login; UI login tetap meminta nomor telepon dan kata sandi. |
| FR-04 | OTP pendaftaran dan reset berupa kode numerik enam digit. |
| FR-05 | Reset dapat dimulai dari Login maupun Profil. |
| FR-06 | Respons publik reset tidak membedakan akun tidak ada, belum memenuhi syarat, atau OTP terkirim. |
| FR-07 | Kode valid menghasilkan otorisasi terbatas untuk mengubah kata sandi, bukan sesi login. |
| FR-08 | Kata sandi hanya dapat diubah setelah kode serta otorisasi reset divalidasi backend. |
| FR-09 | Email pemulihan dapat diganti di Profil; email baru aktif setelah diverifikasi. |
| FR-10 | Backoffice menampilkan email pemulihan dan status verifikasi sesuai hak akses. |
| FR-11 | Perubahan email/kata sandi mempertahankan UUID Auth. |
| FR-12 | Kegagalan email dapat dicoba ulang sesuai rate limit dan tidak membocorkan keberadaan akun. |

## 7. Antarmuka dan Data Backend

Operasi administratif Auth berjalan pada Supabase Edge Function atau backend tepercaya SIGUMI. Tidak ada service-role key di Flutter atau browser.

Operasi yang diperlukan:

1. Mulai verifikasi email pendaftaran: membuat challenge, mengirim OTP, dan mengembalikan challenge ID.
2. Verifikasi OTP pendaftaran: memvalidasi kode dan menerbitkan otorisasi sekali pakai untuk menyelesaikan pendaftaran.
3. Minta reset: menerima nomor telepon, mencari kanal pemulihan di server, dan mengirim OTP jika memenuhi syarat.
4. Verifikasi reset: memvalidasi challenge dan menerbitkan tiket reset sekali pakai yang terikat UUID.
5. Tetapkan kata sandi: memvalidasi tiket dan kata sandi baru, memperbarui Auth, lalu mengonsumsi tiket.
6. Tambah/ganti email pemulihan: memerlukan sesi sah, mengirim OTP, dan menandai verified hanya setelah kode sah.

Model data perlu menyimpan email pemulihan serta waktu/status verifikasi pada profil atau penyimpanan terkontrol. Challenge dan tiket reset disimpan server-side, tidak dapat diakses role anon/pengguna lain, dan hanya mengacu ke UUID akun. Nama field final mengikuti konvensi skema proyek.

## 8. Keamanan dan Operasional

### OTP dan tiket reset

- OTP enam digit dibuat dengan sumber acak kriptografis.
- OTP berlaku 10 menit.
- Maksimum 5 percobaan salah untuk satu challenge; setelah itu challenge dibatalkan.
- Cooldown kirim ulang minimum 60 detik.
- Batas awal: 3 pengiriman per 15 menit per akun/kontak dan 20 permintaan per jam per IP; backend dapat memperketatnya saat terdeteksi abuse.
- OTP disimpan sebagai hash/HMAC dan tidak dicatat dalam log.
- Tiket reset berlaku maksimum 10 menit, sekali pakai, terikat ke UUID dan hanya untuk perubahan kata sandi.
- Rate limit diterapkan server-side dan tetap berlaku lintas sesi/perangkat.

### Kata sandi, sesi, dan privasi

- Kebijakan minimum kata sandi v1 mengikuti aplikasi saat ini: 6 karakter; validasi dilakukan di klien dan backend.
- Setelah reset, tiket dibatalkan dan sesi lama diinvalidasi sesuai kemampuan Supabase Auth yang aktif. Keterbatasannya harus diverifikasi sebelum rilis.
- Respons serta waktu respons permintaan reset dibuat seragam untuk mencegah enumerasi.
- Log mencatat event dan hasil tanpa OTP, kata sandi, tiket utuh, atau email penuh yang tidak diperlukan.
- Kredensial SMTP dan service-role key disimpan sebagai secret server, bukan dalam source atau artefak klien.
- Semua koneksi memakai HTTPS/TLS.

### SMTP VPS

- Gunakan SMTP transaksional produksi, bukan konfigurasi uji/default.
- Verifikasi domain pengirim melalui SPF dan DKIM; DMARC direkomendasikan.
- Pantau accepted/rejected/bounced, kegagalan Auth, dan latensi email.
- Uji inbox serta spam setidaknya pada Gmail dan satu provider lain sebelum peluncuran.
- Email memuat nama pengirim SIGUMI, instruksi, waktu kedaluwarsa, dan larangan membagikan kode.

## 9. Backoffice Management User

- Tambahkan kolom Email Pemulihan dan Status Verifikasi pada daftar yang menampilkan nama, ID akun, tanggal bergabung, dan role.
- Pencarian dapat mencakup nama, nomor telepon, email pemulihan, dan ID akun sesuai hak akses.
- Email dapat disamarkan pada tabel; akses ke alamat penuh dibatasi bagi admin yang memerlukannya.
- Status minimum: belum ditambahkan, menunggu verifikasi, terverifikasi, atau gagal diperbarui.
- Tidak ada tampilan atau aksi untuk melihat OTP/kata sandi atau menetapkan kata sandi manual.
- Bila ada aksi kirim ulang verifikasi, kirim hanya ke alamat terdaftar, terapkan rate limit, dan catat di audit log.
- Email pemulihan bukan sumber otoritas role admin.

## 10. Validasi dan Kondisi Gagal

| Kondisi | Perilaku |
|---|---|
| Email tidak valid saat daftar | Tampilkan kesalahan format; jangan kirim OTP. |
| OTP pendaftaran sah | Tandai email terverifikasi dan izinkan pendaftaran selesai. |
| OTP salah/kedaluwarsa/dipakai ulang | Tolak dan jangan mengubah status atau kata sandi. |
| Batas percobaan tercapai | Batalkan challenge dan minta proses baru setelah limit mengizinkan. |
| Nomor tidak terdaftar | Respons generik yang sama seperti permintaan reset berhasil. |
| Akun lama tanpa email terverifikasi | Reset mandiri tidak tersedia; tampilkan bantuan generik. |
| SMTP gagal/timeout/bounce | Jangan ungkap status akun; catat error server-side dan izinkan retry sesuai limit. |
| Email baru belum diverifikasi | Email lama tetap menjadi kanal aktif. |
| Kata sandi tidak memenuhi aturan | Tolak perubahan; tiket tetap terikat expiry dan tidak boleh dipakai untuk akun lain. |
| Reset berhasil | Login nomor telepon dengan kata sandi baru berhasil; kata sandi lama ditolak; UUID/data tetap utuh. |

## 11. Kriteria Penerimaan

1. Pendaftaran meminta nomor telepon, kata sandi, dan email pemulihan; akun tidak aktif sebelum verifikasi selesai.
2. Email pemulihan tidak menggantikan nomor telepon pada login.
3. OTP diterima pada inbox pemulihan saat reset dimulai dari Login maupun Profil.
4. Respons reset tidak mengungkap status akun atau email.
5. OTP salah, kedaluwarsa, replay, atau melewati limit tidak dapat mengubah kata sandi.
6. Setelah reset, kata sandi baru bekerja dan kata sandi lama tidak bekerja.
7. Rate limit bertahan setelah aplikasi dimulai ulang dan berlaku lintas perangkat.
8. SMTP gagal menghasilkan pesan aman dan event yang dapat ditindaklanjuti tanpa mencatat rahasia.
9. Akun lama dapat login selama transisi, menambah email, lalu memakai reset setelah verifikasi.
10. Backoffice menampilkan status email sesuai hak akses tanpa OTP/kata sandi.
11. UUID pengguna serta relasi profil/laporan/tracking tidak berubah.
12. Tidak ada service-role key atau secret SMTP dalam kode maupun build klien.

## 12. Rencana Pengujian

### Fungsional

- Pendaftaran email valid, verifikasi berhasil, penyelesaian signup, dan login dengan telepon.
- Email invalid, OTP salah/kedaluwarsa, resend cooldown, batas kirim, serta batas percobaan.
- Reset dari Login dan Profil; nomor tidak dikenal; akun tanpa email terverifikasi.
- Replay OTP, tiket reset dari challenge lain, dan tiket kedaluwarsa.
- Kata sandi pendek, konfirmasi berbeda, reset sukses, login dengan sandi lama gagal dan sandi baru berhasil.
- Ganti email: email lama tetap aktif sebelum verifikasi email baru; email baru aktif setelah kode sah.
- Akun lama dengan profil/laporan/tracking tetap terkait setelah penambahan email dan reset.

### Keamanan dan privasi

- Bandingkan respons nomor terdaftar/tidak terdaftar untuk mencegah enumerasi.
- Coba brute-force, replay, concurrency dua challenge, dan bypass UI melalui request langsung.
- Pastikan OTP/tiket tidak terbaca dari API publik, analytics, log, atau backoffice.
- Pastikan perubahan kata sandi selalu terikat ke UUID pemilik challenge.
- Pastikan kredensial administratif hanya berada di server.

### Operasional

- Uji inbox/spam, SMTP down, timeout, bounce, kredensial SMTP salah, dan pemulihan setelah provider kembali.
- Uji tampilan status dan pembatasan akses di backoffice.
- Uji akun lama tanpa email serta alur bantuan yang sudah dikonfigurasi.

## 13. Peluncuran dan Pemantauan

1. Tambahkan field profil dan storage challenge secara aditif; jangan mengubah UUID atau menghapus akun.
2. Konfigurasikan SMTP, secret server, TLS, SPF/DKIM, template, rate limit, logging, dan alert.
3. Deploy backend terlebih dahulu dan uji dengan akun internal.
4. Aktifkan signup dengan verifikasi email untuk pengguna baru.
5. Komunikasikan kepada pengguna lama bahwa mereka perlu menambahkan email saat masih dapat login.
6. Aktifkan entry point reset dari Login dan Profil, lalu tampilkan email/status di backoffice.
7. Pantau delivery, konversi verifikasi, penyelesaian reset, limit abuse, dan tiket bantuan.
8. Jangan menjadikan reset mandiri jalur pemulihan utama sampai kanal bantuan akun lama aktif.

### Go-live gate

- SMTP produksi dan OTP berhasil diuji pada inbox nyata.
- Backend menegakkan verifikasi, expiry, one-time use, rate limit, dan keterikatan UUID.
- Tidak ada secret administratif di klien.
- Kanal bantuan bagi akun lama tanpa email aktif.
- Backoffice memahami batas akses: tidak pernah meminta OTP atau kata sandi.

## 14. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Email masuk spam/terlambat | Verifikasi domain, pantau bounce, sediakan retry berlimit, dan uji provider utama. |
| Pengguna salah mengetik email | Verifikasi OTP sebelum pendaftaran aktif dan izinkan perbaikan alamat sesuai limit. |
| Akun lama terkunci | Prompt saat pengguna masih login, komunikasi migrasi, dan kanal bantuan terverifikasi. |
| Enumerasi nomor atau abuse OTP | Respons generik, rate limit per nomor/IP, audit event, serta kontrol tambahan bila abuse terdeteksi. |
| Kebocoran service-role/SMTP | Simpan hanya pada server, batasi akses, rotasi secret, audit deployment. |
| OTP/tiket dipakai ulang | Konsumsi atomik, expiry, hash penyimpanan, dan pengujian replay/concurrency. |
| Data lama terputus | Pertahankan UUID dan update akun yang sama; larang delete-and-recreate saat migrasi. |

## 15. Keputusan Produk

- Login dan identitas pada layar login tetap nomor telepon.
- Email aktif diminta dan diverifikasi saat signup, hanya untuk pemulihan.
- Reset diverifikasi dengan OTP email enam digit, bukan reset email Auth bawaan.
- Login dan Profil membuka satu recovery flow yang sama.
- Akun lama dapat menambahkan email dari Profil; reset mandiri aktif setelah verifikasi.
- Backoffice menampilkan email/status, tetapi tidak mengelola OTP atau kata sandi.
- Minimum kata sandi v1 tetap mengikuti aplikasi saat ini, yaitu 6 karakter.
- Akun lama yang sudah terkunci memerlukan kanal bantuan resmi sebelum fitur diluncurkan.

