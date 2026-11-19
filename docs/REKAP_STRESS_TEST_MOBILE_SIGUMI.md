# Dokumen Rekapitulasi Lengkap Stress Test & Optimasi Ketahanan Aplikasi Mobile SIGUMI

Dokumen ini memuat rekapitulasi lengkap pelaksanaan **Stress Test, Resilience/Recovery Test, serta Optimasi Bottleneck** pada aplikasi mobile **SIGUMI (Sistem Informasi Gunung Berapi Mitigasi)** mengacu pada standar di [`docs/RENCANA_PENGUJIAN_SIGUMI.md`](./RENCANA_PENGUJIAN_SIGUMI.md).

---

## 1. Spesifikasi Lingkungan & Cakupan Pengujian

| Parameter | Nilai / Konfigurasi |
| :--- | :--- |
| **Tanggal Pelaksanaan** | 13 November 2026 |
| **Target Pengujian** | Aplikasi Mobile Flutter SIGUMI (`lib/services/`, `lib/screens/`, `lib/repositories/`) & Kontrak API Backend Staging (`postman/`) |
| **Framework & Alat Uji** | `flutter_test` (Automated Stress & Fault-Injection Suite), Dart Analyzer (`dart-mcp-server`), & Postman CLI `v1.87.0` |
| **Mode Data & Keamanan** | 100% Data Sintetis & Simulasi Gateway/Mock Client (0 pengiriman SOS/laporan ke petugas SAR atau server produksi nyata) |
| **File Suite Pengujian** | 1. [`test/mobile_stress_test.dart`](../test/mobile_stress_test.dart) *(5 Skenario Stress P0/P1/P2)*<br>2. [`test/hiking_tracking_service_test.dart`](../test/hiking_tracking_service_test.dart) *(2 Skenario Regresi GPS)*<br>3. [`test/hiking_weather_test.dart`](../test/hiking_weather_test.dart) *(2 Skenario Cache & Fallback Cuaca)*<br>4. [`postman/sigumi_mobile_backend_stress_collection.json`](../postman/sigumi_mobile_backend_stress_collection.json) *(9 Endpoint Kontrak Load/Stress Backend)*<br>5. [`docs/REKAP_PENGUJIAN_CHATBOT_POSTMAN.md`](./REKAP_PENGUJIAN_CHATBOT_POSTMAN.md) *(25 Uji API Chatbot 5 Bahasa)* |
| **Status Akhir Eksekusi** | **100% LULUS (`9/9` Test Suite Flutter Lulus, `0` Analyzer Error)** |

---

## 2. Temuan Bottleneck Kritis & Optimasi Kode Mobile (*Before vs. After*)

Selama penyusunan dan eksekusi awal stress test, ditemukan **6 bottleneck dan *race condition*** pada lapisan layanan mobile yang berpotensi menyebabkan *freeze* UI, duplikasi data, atau kegagalan sinkronisasi saat kondisi darurat. Seluruhnya telah diperbaiki dan diverifikasi:

| No | Komponen / File | Kondisi Sebelum Optimasi (*Before*) | Kondisi Setelah Optimasi (*After*) | Dampak Terukur pada Stress Test |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Sinkronisasi Antrean Titik GPS Offline**<br>[`hiking_tracking_service.dart`](../lib/services/hiking_tracking_service.dart) | Menguras antrean `_pendingPoints` **satu per satu** di dalam loop: untuk 1.440 titik (2 jam pendakian @ 5 detik) melakukan **1.440 HTTP `upsert` titik + 1.440 HTTP `update` sesi = 2.880 HTTP request berurutan** dan 1.440 penulisan disk. | Mengelompokkan titik per `session_id` dan mengirim secara **Batch (`syncBatchSize = 100` titik/request)**, memperbarui `hiking_sessions` dan menyimpan ke `SharedPreferences` hanya **1 kali per batch**. | Jumlah request jaringan turun **~99,5%** (dari 2.880 operasi menjadi **15 batch** untuk 1.440 titik). Waktu kuras antrean hanya **23 ms**. |
| **2** | **Penulisan State Lokal saat Burst GPS**<br>[`hiking_tracking_service.dart`](../lib/services/hiking_tracking_service.dart) | Setiap titik GPS memicu 3 penulisan `SharedPreferences` terpisah (`_persistLocalSessions`, `_persistPendingData`, `_persistSessionState`) dengan kompleksitas serialisasi JSON $O(N^2)$ serta menyimpan duplikat array `route` dan `route_segments`. | Menambahkan **Coalesced Checkpoint (`_persistCheckpoint`)** sehingga burst GPS dalam frame yang sama digabung menjadi satu siklus simpan, menghapus duplikasi field `route`, dan menghentikan penulisan setelah `dispose()`. | Perekaman **1.440 titik GPS berturut-turut** beserta persistensi lokal selesai dalam **128 ms** tanpa memblokir event loop. |
| **3** | **Race Condition `flushPendingData()` & Unik ID**<br>[`hiking_tracking_service.dart`](../lib/services/hiking_tracking_service.dart) | Jika `flushPendingData()` dipanggil tepat saat jaringan pulih sementara flush offline sebelumnya masih menyelesaikan blok `finally`, panggilan baru diabaikan (`if (_isFlushing) return;`). Selain itu `client_point_id` hanya memakai `microsecondsSinceEpoch` yang rawan kembar saat burst. | Mengganti boolean `_isFlushing` dengan antrean siklus `_flushFuture` + `_flushRequestedAgain` agar permintaan flush baru saat transisi jaringan tetap dieksekusi setelah siklus berjalan selesai. Menambahkan *monotonic counter* (`_pointSequence` & `_alertSequence`) serta *in-flight guard* `_uploadingSosAlertIds`. | **0 titik tertinggal** saat transisi offline $\rightarrow$ online cepat, dan **0 tabrakan ID** pada burst ribuan titik per milidetik. |
| **4** | **Lifecycle Singleton & Throttling RPC Lokasi**<br>[`location_service.dart`](../lib/services/location_service.dart) | `LocationService.dispose()` memanggil `super.dispose()` yang merusak *singleton* `ChangeNotifier` secara permanen. Selain itu `_applyLivePosition` memanggil RPC `update_user_location` setiap 2–3 detik tanpa batas antrean (*in-flight*). | Menghapus `super.dispose()` pada singleton `LocationService`, menghitung jarak & zona risiko lokal secara sinkron sebelum `notifyListeners()`, serta menambahkan *in-flight guard* dan *throttling* (`10 detik` / `20 meter`) ke Supabase RPC. | Singleton tetap hidup melewati `dispose()` dan tahan **1.000 pembaruan lokasi cepat** tanpa banjir panggilan RPC. |
| **5** | **Fallback Chatbot saat Server Cloud Gagal**<br>[`chatbot_engine.dart`](../lib/services/chatbot_engine.dart)<br>[`cloud_llm_service.dart`](../lib/services/cloud_llm_service.dart) | Saat server Ollama *timeout* atau mengembalikan HTTP 5xx ketika perangkat masih online, `CloudLlmService` melempar exception dan `ChatbotEngine` mengembalikan teks error statis dengan label `ResponseSource.cloud`. | Saat request cloud gagal/timeout setelah retry, `CloudLlmService` mengembalikan `null` dan `ChatbotEngine` otomatis beralih ke [`RuleBasedFallback`](../lib/services/rule_based_fallback.dart) dengan sumber jujur `ResponseSource.localFallback`. | **100% permintaan gagal/timeout** saat lonjakan trafik tetap mendapat jawaban panduan mitigasi lokal secara instan dengan label sumber yang akurat. |
| **6** | **Double-Submit Laporan, Retry Foto & Privasi Log**<br>[`report_screen.dart`](../lib/screens/report/report_screen.dart)<br>[`report_repository.dart`](../lib/repositories/report_repository.dart) | `_submitReport()` belum memiliki guard awal terhadap tap ganda cepat, mengunggah ulang file foto yang sama ke Storage jika insert DB timeout, dan mencatat isi deskripsi/koordinat rinci ke log. | Menambahkan guard `if (_isSubmitting) return;`, menyimpan cache `_uploadedImageUrl` untuk foto yang sama saat *retry*, menghapus log sensitif pada `ReportRepository`, serta menghapus password hardcoded dari collection Postman. | Mencegah laporan/file gambar duplikat saat jaringan lambat dan mematuhi Checklist Keamanan 5.5 & 5.6. |

---

## 3. Tabel Rekapitulasi Hasil Stress Test Aplikasi Mobile (`test/mobile_stress_test.dart`)

Berikut adalah hasil eksekusi seluruh skenario stress test pada [`test/mobile_stress_test.dart`](../test/mobile_stress_test.dart):

| ID Uji | Prioritas | Skenario Stress & Ketahanan yang Diuji | Parameter Beban | Waktu Eksekusi / Metrik | Hasil & Integritas Data | Status |
| :-: | :-: | :--- | :--- | :---: | :--- | :-: |
| **Stress 1** | **P0** (Keselamatan) | **Burst Offline Tracking, Force-Close Restore & Mid-Batch Network Drop** | **1.440 titik GPS** (setara 2 jam pendakian @ 5 detik) saat offline $\rightarrow$ *cold start restore* $\rightarrow$ koneksi putus setelah batch ke-4 (`400 titik`) $\rightarrow$ reconnect penuh | Rekam: **128 ms**<br>Drain: **23 ms**<br>Batch HTTP: **15 request** | • `1.440 / 1.440` titik tersimpan (`0 data hilang`)<br>• `0` titik duplikat dikirim ulang<br>• `1.040` titik sisa aman saat putus di tengah jalan | **LULUS** |
| **Stress 2** | **P0** (Keselamatan) | **Rapid-Tap SOS Offline & Concurrent Retry Storm** | **50x tap tombol SOS** bersamaan saat offline + **20x panggilan retry & flush konkuren** saat koneksi pulih (latensi simulasi `10 ms`) | Total durasi: **< 100 ms**<br>Alert terkirim: **1 alert** | • Saat offline seluruh 50 tap mengembalikan `queuedOffline` (tidak klaim palsu)<br>• Tepat **1 alert SOS unik** di server (`0 alert duplikat`) | **LULUS** |
| **Stress 3** | **P0** (Keselamatan) | **Fluktuasi Ekstrem Sinyal GPS, Timestamp Mundur & Geofence Grace** | `10` langkah valid $\rightarrow$ **100 sinyal GPS rusak** (`accuracy = 250 m`) $\rightarrow$ pulih di titik baru $\rightarrow$ **50 timestamp mundur** $\rightarrow$ keluar radius 15 km (`3x`) & masuk kembali (`2x`) | **165 event GPS** berurutan | • `0,0000 km` penambahan jarak palsu saat GPS rusak<br>• `50/50` timestamp mundur ditolak<br>• Transisi `tracking` $\leftrightarrow$ `gpsUnavailable` $\leftrightarrow$ `outsideGrace` akurat | **LULUS** |
| **Stress 4** | **P1** (Alur Utama) | **Ketahanan Singleton `LocationService` & Kalkulasi Batas Zona Risiko** | Pemanggilan `dispose()` pada singleton diikuti **1.000 perpindahan koordinat** melintasi batas `5 km`, `10 km`, `15 km`, dan `40 km` | **1.000 iterasi** (`>= 1.000` notifikasi UI) | • `0` error `ChangeNotifier disposed`<br>• Akurasi klasifikasi Zona Level 4 (≤5 km), Level 3 (≤10 km), Level 2 (≤15 km), Level 1 (>15 km) **100%** | **LULUS** |
| **Stress 5** | **P2** (Pendukung) | **Burst 25 Request Konkuren Chatbot (5 Bahasa $\times$ 5 Mode Kegagalan Server)** | **25 request konkuren** (`id`, `en`, `jv`, `ba`, `sas`) dengan injeksi: `200 OK`, `503 Overload`, `JSON rusak`, `payload kosong`, dan `504 Timeout` | **25 request konkuren** (+ retry otomatis) | • `25 / 25` menghasilkan pesan valid (`0 crash/hang`)<br>• Seluruh kegagalan server beralih ke `RuleBasedFallback` (`ResponseSource.localFallback`) | **LULUS** |

---

## 4. Rincian Analisis per Skenario Stress Test

### 4.1. P0 Stress 1 — Offline Tracking 1.440 Titik, Force-Close & Pemulihan Jaringan Bertahap
* **Tujuan:** Memverifikasi persyaratan P0 pada [`docs/RENCANA_PENGUJIAN_SIGUMI.md`](./RENCANA_PENGUJIAN_SIGUMI.md) Bagian 5.8 dan Bagian 7 (*"0 data hilang dan 0 alert duplikat setelah retry yang valid"* serta *"Gangguan saat sebagian titik berhasil dan sebagian gagal tidak menghapus antrean yang belum berhasil"*).
* **Tahapan Uji:**
  1. Memulai sesi pendakian di wilayah `lombok` saat jaringan mati (`local_<timestamp>`).
  2. Mengirimkan **1.440 titik koordinat GPS** secara beruntun.
  3. Mematikan service (`service.dispose()`) untuk mensimulasikan aplikasi ditutup paksa (*force close*), lalu membuat instance `HikingTrackingService` baru yang membaca ulang state dari `SharedPreferences`.
  4. Menghidupkan jaringan dengan injeksi gangguan: koneksi diputus paksa tepat setelah **4 batch (`400 titik`)** berhasil diunggah.
  5. Memastikan `400 titik` sudah tersimpan di server dan `1.040 titik` sisanya masih utuh di antrean lokal perangkat (`pendingPointsCount == 1040`).
  6. Memulihkan jaringan sepenuhnya dan menjalankan `flushPendingData()` kembali.
* **Hasil Akhir:**
  * Seluruh **1.440 titik unik** berhasil tersimpan di server (`trackPointsByClientId.length == 1440`).
  * Jumlah duplikasi: **`0`** (`duplicatePointsPrevented == 0`).
  * Total panggilan batch ke tabel `hiking_track_points`: **`15 panggilan`** (4 batch pada fase pertama + 11 batch pada fase kedua).

### 4.2. P0 Stress 2 — Rapid-Tap 50x Tombol SOS Offline & 20x Retry Konkuren
* **Tujuan:** Memastikan pengguna yang panik menekan tombol SOS berkali-kali saat sinyal hilang tidak menghasilkan laporan darurat ganda ke dashboard SAR dan UI tidak menampilkan klaim sukses palsu sebelum server mengonfirmasi.
* **Tahapan Uji:**
  1. Menjalankan `Future.wait(List.generate(50, (_) => service.sendSos()))` saat jaringan offline.
  2. Memverifikasi bahwa ke-50 pemanggilan mengembalikan `HikingSosStatus.queuedOffline` dan hanya membuat **1 entri** pada `_pendingSosAlerts`.
  3. Menghidupkan jaringan dengan latensi simulasi `10 ms`, lalu memicu **15 panggilan `retryPendingSos(alertId)` dan 5 panggilan `flushPendingData()` secara bersamaan**.
* **Hasil Akhir:**
  * Hanya **1 permintaan `upsertSosAlert`** yang dieksekusi berkat proteksi `_uploadingSosAlertIds` dan `_uploadedSosAlertIds`.
  * Server menerima tepat **1 alert SOS unik** (`sosAlertsByClientId.length == 1`, `duplicateSosPrevented == 0`).

### 4.3. P0 Stress 3 — Ketahanan terhadap Sinyal GPS Buruk, Timestamp Mundur & Batas Wilayah
* **Tujuan:** Memastikan perhitungan jarak dan status pendakian tidak rusak oleh *noise* sensor GPS di pegunungan.
* **Hasil Akhir:**
  * **100 sinyal GPS dengan akurasi 250 meter** (> batas 100 m) mengubah status menjadi `HikingTrackingStatus.gpsUnavailable`, memulai segmen rute baru, dan **tidak menambah jarak pendakian sedikit pun** (`distanceKm` tetap akurat).
  * Ketika sinyal kembali akurat di koordinat berbeda, titik pertama dijadikan jangkar (*anchor*) segmen baru sehingga tidak terjadi lonjakan jarak lurus (*straight-line jump*) dari titik sebelum hilang sinyal.
  * **50 sinyal dengan timestamp mundur** (*out-of-order buffer*) berhasil ditolak seluruhnya.
  * **3 sinyal berturut-turut di luar radius 15 km** memicu status `outsideGrace`, dan **2 sinyal berturut-turut kembali di dalam radius** memulihkan status ke `tracking`.

### 4.4. P1 Stress 4 — Ketahanan Singleton `LocationService` & Presisi Zona Risiko
* **Tujuan:** Menguji perhitungan Haversine dan klasifikasi zona bahaya pada pergerakan cepat melintasi batas zona (`5 km`, `10 km`, `15 km`, `40 km`).
* **Hasil Akhir:**
  * Pemanggilan `LocationService().dispose()` tidak lagi mematikan *singleton*.
  * **1.000 pembaruan lokasi manual** berturut-turut berhasil memicu notifikasi listener tanpa error dan memetakan `zoneLevel` (`1` s/d `4`) secara konsisten.

### 4.5. P2 Stress 5 — Konkurensi Chatbot 5 Bahasa & Ketahanan Fallback Lokal
* **Tujuan:** Melengkapi hasil pengujian API pada [`docs/REKAP_PENGUJIAN_CHATBOT_POSTMAN.md`](./REKAP_PENGUJIAN_CHATBOT_POSTMAN.md) (di mana rata-rata waktu respons server Ollama adalah `68,87 detik`) dengan menguji perilaku aplikasi mobile saat server mengalami beban puncak/kegagalan.
* **Hasil Akhir:**
  * Dari **25 request konkuren** lintas 5 bahasa (`id`, `en`, `jv`, `ba`, `sas`) yang dikenai kombinasi respons sukses (`200 OK`), *server overload* (`503`), *malformed JSON*, *empty response*, dan *timeout* (`504`), **100% panggilan selesai dengan aman**.
  * Setiap panggilan yang gagal di sisi cloud langsung dijawab oleh `RuleBasedFallback` dengan penanda `ResponseSource.localFallback`.

---

## 5. Kesiapan Stress Test Backend Staging (`postman/sigumi_mobile_backend_stress_collection.json`)

Untuk menguji kapasitas server Supabase staging terhadap beban banyak perangkat secara bersamaan, telah disiapkan collection [`postman/sigumi_mobile_backend_stress_collection.json`](../postman/sigumi_mobile_backend_stress_collection.json) yang memodelkan 3 profil beban utama:

1. **Folder 1 — Read Burst (Beranda, Peta, Shelter & Cuaca):**
   * `GET /rest/v1/volcanoes` (Status gunung berapi)
   * `POST /rest/v1/rpc/get_nearest_shelters` (Query spasial PostGIS shelter terdekat)
   * `POST /rest/v1/rpc/update_user_location` (Update lokasi & zona risiko pengguna)
   * `POST /functions/v1/hiking-weather` (Edge Function cuaca pendakian)
2. **Folder 2 — Write & Recovery Pendaki Aktif (Idempotensi & Batching):**
   * `POST /rest/v1/hiking_sessions?on_conflict=client_session_id` (Upsert sesi pendakian unik per Virtual User)
   * `POST /rest/v1/hiking_track_points?on_conflict=client_point_id` (Batch upload 12 titik GPS/menit)
   * `POST /rest/v1/hiking_track_points?on_conflict=client_point_id` (Pengiriman ulang batch yang sama untuk memverifikasi `Prefer: resolution=ignore-duplicates` menolak duplikasi)
3. **Folder 3 — SOS Darurat & Laporan Pengguna Sintetis:**
   * `POST /rest/v1/hiking_sos_alerts?on_conflict=client_alert_id` (Upsert alert SOS sintetis dengan `client_alert_id` unik)
   * `POST /rest/v1/reports` (Pembuatan laporan warga sintetis)

### Cara Menjalankan Stress Test Backend Staging dengan Postman CLI (`v1.87.0`)

Setelah mengisi variabel `supabase_staging_url`, `supabase_anon_key`, `user_jwt_token`, dan `synthetic_user_id` pada file [`postman/sigumi_staging_environment.json`](../postman/sigumi_staging_environment.json):

```powershell
# 1. Uji Fungsional 1 Iterasi (Memastikan kredensial & endpoint staging sudah terhubung)
postman collection run postman/sigumi_mobile_backend_stress_collection.json -e postman/sigumi_staging_environment.json

# 2. Smoke / Baseline Test (5 Virtual Users flat selama 1 menit)
postman performance run postman/sigumi_mobile_backend_stress_collection.json -e postman/sigumi_staging_environment.json --load-profile fixed --peak-vu 5 --duration 1

# 3. Ramp-Up Load & Stress Test (Mulai 5 VU, naik bertahap ke 50 VU selama 5 menit, dengan syarat lulus p95 < 1000ms & error < 2%)
postman performance run postman/sigumi_mobile_backend_stress_collection.json -e postman/sigumi_staging_environment.json --load-profile ramp-up --base-vu 5 --peak-vu 50 --duration 5 --load-segments "30s,1m" --pass-if "less_than(p95, 1000)" --pass-if "less_than(error_rate, 2)"

# 4. Spike Test (Lonjakan mendadak dari 5 VU ke 100 VU saat peringatan gunung berapi selama 3 menit)
postman performance run postman/sigumi_mobile_backend_stress_collection.json -e postman/sigumi_staging_environment.json --load-profile spike --base-vu 5 --peak-vu 100 --duration 3 --load-segments "1m,20s,40s"
```

---

## 6. Cara Menjalankan Ulang Suite Stress Test Mobile Secara Lokal

Untuk menjalankan seluruh pengujian ketahanan mobile kapan saja (termasuk di pipeline CI/CD sebelum rilis):

```powershell
# Menjalankan suite stress test mobile
flutter test test/mobile_stress_test.dart

# Menjalankan seluruh suite pengujian aplikasi
flutter test
```

