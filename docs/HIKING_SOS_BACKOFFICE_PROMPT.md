# Prompt AI: Integrasi SOS Backoffice SIGUMI

Salin seluruh isi bagian **Prompt siap pakai** di bawah ini ke AI yang memiliki akses ke repositori backoffice.

## Prompt siap pakai

````text
Anda bekerja pada repositori web backoffice admin/SAR SIGUMI. Implementasikan integrasi SOS pendaki pada halaman “Tracking Pendaki Aktif” yang saat ini menampilkan daftar sesi dan peta jalur. Sebelum mengubah kode, periksa struktur repositori, framework, pola UI, autentikasi admin, konfigurasi Supabase, dan cara aplikasi mengambil sesi serta titik tracking. Ikuti pola proyek; jangan mengasumsikan framework atau membuat aplikasi baru.

TUJUAN
Ketika aplikasi mobile menyimpan alert SOS ke Supabase, admin dapat melihatnya tanpa reload halaman, menemukan pendaki dan lokasinya di peta, membuka detail, serta memperbarui status penanganan. Halaman harus pulih dari reconnect atau event Realtime yang terlewat.

KONTRAK MOBILE
Mobile mengirim row ke public.hiking_sos_alerts dengan field:
- client_alert_id: ID unik untuk retry idempoten.
- session_id: UUID sesi hiking_sessions.
- user_id: UUID pengguna auth.users.
- latitude, longitude: koordinat GPS (keduanya wajib di schema saat ini).
- accuracy_meters: akurasi GPS, dapat null.
- location_recorded_at: waktu koordinat GPS dalam TIMESTAMPTZ, dapat null.
- message: teks SOS.
- status: awalnya open.
- created_at: waktu alert dibuat.

Mobile melakukan upsert berdasarkan client_alert_id. Deduplikasi berdasarkan id dan/atau client_alert_id, dan jangan membuat alert baru ketika event atau retry yang sama diterima lagi. Mobile menyimpan SOS secara lokal saat offline dan mencoba upload kembali; antrean lokal belum terlihat oleh backoffice. Nyatakan alert diterima server hanya jika row benar-benar tersedia di Supabase.

Catatan kontrak mobile saat ini: setelah konfirmasi SOS, panel SOS terbuka dan mengirim alert otomatis. Tombol panel yang berlabel “Kirim sinyal ke backoffice” saat ini membuka pemilihan kontak telepon. Jangan anggap klik tombol itu sebagai bukti pengiriman; row hiking_sos_alerts adalah sumber kebenaran. Perubahan mobile di luar tugas kecuali memang diperlukan dan diizinkan secara eksplisit.

MIGRASI DATABASE YANG SUDAH ADA
Sumber skema: supabase/migrations/20261027_hiking_sos_and_idempotent_points.sql. Periksa migrasi dan schema proyek sebelum mengubah apa pun. Bagian relevan SOS dari migrasi tersebut:

```sql
CREATE TABLE IF NOT EXISTS public.hiking_sos_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_alert_id TEXT UNIQUE,
  session_id UUID REFERENCES public.hiking_sessions(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  accuracy_meters DOUBLE PRECISION,
  location_recorded_at TIMESTAMPTZ,
  message TEXT NOT NULL DEFAULT 'Pengguna meminta bantuan melalui SOS.',
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'acknowledged', 'resolved', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_hiking_sos_alerts_open_created
  ON public.hiking_sos_alerts (created_at DESC)
  WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_hiking_sos_alerts_user_created
  ON public.hiking_sos_alerts (user_id, created_at DESC);

ALTER TABLE public.hiking_sos_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create own hiking SOS alerts"
  ON public.hiking_sos_alerts;
CREATE POLICY "Users can create own hiking SOS alerts"
  ON public.hiking_sos_alerts FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      session_id IS NULL
      OR EXISTS (
        SELECT 1 FROM public.hiking_sessions s
        WHERE s.id = session_id AND s.user_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "Users can view own hiking SOS alerts"
  ON public.hiking_sos_alerts;
CREATE POLICY "Users can view own hiking SOS alerts"
  ON public.hiking_sos_alerts FOR SELECT
  USING (auth.uid() = user_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'hiking_sos_alerts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.hiking_sos_alerts;
  END IF;
END $$;
```

Migrasi yang sama juga menambahkan client_session_id ke hiking_sessions dan client_point_id ke hiking_track_points untuk idempotensi. Jangan hapus atau duplikasi perubahan tersebut. Status SOS dibatasi ke open, acknowledged, resolved, cancelled. Skema mewajibkan latitude dan longitude.

YANG HARUS DIIMPLEMENTASIKAN
1. Pengambilan awal dan Supabase Realtime:
   - Ambil alert yang sudah ada saat halaman dibuka; jangan hanya mengandalkan event baru.
   - Subscribe INSERT dan UPDATE pada public.hiking_sos_alerts, deduplikasi event, dan perbarui UI tanpa reload.
   - Tangani status koneksi kanal, reconnect, unsubscribe saat komponen dilepas, lalu fetch ulang agar event yang terlewat tertangani.
   - Alert open yang sudah lama tetap muncul setelah refresh.

2. Daftar dan peta:
   - Tambahkan indikator SOS yang menonjol dan jumlah alert yang perlu ditangani.
   - Sediakan filter status; utamakan open dan acknowledged, tetapi izinkan histori resolved dan cancelled.
   - Bedakan marker SOS dari marker titik awal/akhir dan garis rute. Saat dipilih, fokuskan peta ke koordinat alert dan pilih sesi terkait jika tersedia.
   - Detail menampilkan identitas pendaki dari sumber profil yang benar-benar tersedia di proyek, sesi/gunung, pesan, waktu alert, koordinat, akurasi, dan umur lokasi dari location_recorded_at. Tandai lokasi stale dengan jelas; jangan menyebutnya realtime.
   - Alert dan koordinat tetap tampil bila join profil atau sesi gagal. Beri fallback yang jujur.
   - Pertahankan pola visual dan responsivitas halaman backoffice.

3. Penanganan status:
   - Admin yang berwenang dapat mengubah open menjadi acknowledged lalu resolved; isi acknowledged_at saat diakui dan resolved_at saat selesai.
   - Perlakukan cancelled sebagai status terminal yang dapat ditampilkan. Cegah transisi/aksi tanpa otorisasi dan tampilkan kegagalan secara jelas.
   - Ubah row yang sama, jangan insert row baru. Jangan menambah handled_by/audit table kecuali dibutuhkan pola proyek; jika perlu, jelaskan dan buat migrasi additive.

4. Keamanan dan migrasi:
   - RLS sekarang hanya mengizinkan pengguna membuat dan melihat alert miliknya. Periksa pola role admin proyek dan berikan akses admin melalui jalur backend terotorisasi.
   - Jangan pernah mengekspos service_role key ke browser, frontend bundle, local storage, atau konfigurasi publik. Jika menggunakan service_role, gunakan hanya pada server melalui secret environment. Alternatif RLS harus bergantung pada klaim/role admin yang tidak dapat diubah pengguna biasa.
   - Supabase Realtime juga wajib memakai autentikasi dan otorisasi admin yang aman; jangan membuka semua alert untuk seluruh pengguna aplikasi.
   - Periksa apakah migrasi sudah diterapkan pada environment target. Keberadaan file lokal bukan bukti skema remote sudah berubah. Jangan membuat tabel duplikat atau menjalankan SQL production secara manual. Jika skema perlu diubah, buat migrasi additive, kompatibel, idempotent, dan dokumentasikan prosedur deployment; jangan menerapkannya ke production tanpa prosedur proyek.

KRITERIA PENERIMAAN DAN TEST
- Alert open lama tampil saat halaman dibuka; alert baru muncul tanpa reload dengan marker pada koordinat yang benar.
- client_alert_id sama tidak menghasilkan tampilan ganda, termasuk setelah reconnect/fetch ulang.
- Umur dan akurasi lokasi terlihat; lokasi lama diberi label stale.
- Acknowledge/resolve memperbarui row dan timestamp yang benar, lalu UI berubah tanpa duplikasi.
- Join profil/sesi yang gagal tidak menghilangkan alert; status yang tidak berizin ditolak dengan pesan yang layak.
- Admin berwenang dapat membaca/menangani SOS; pengguna biasa tidak dapat membaca alert orang lain atau mengubah status admin.
- Tidak ada service_role secret di browser atau bundle.
- Temukan dan jalankan pemeriksaan/test yang dipakai proyek. Tambahkan test sesuai framework untuk fetch awal, Realtime insert/update, deduplikasi, reconnect/resync, status, role access, dan fallback join.

BATASAN DAN LAPORAN
- Gunakan pola repositori yang ada; jangan mengubah aplikasi mobile atau database production di luar kebutuhan yang disetujui.
- Jika schema profil, autentikasi admin, atau deployment tidak dapat dibuktikan dari repo/config, dokumentasikan blocker dan asumsi, jangan menebak nama tabel atau claim.
- Setelah implementasi, laporkan file yang berubah, alur data, perubahan/migrasi yang diperlukan, test yang dijalankan beserta hasilnya, dan langkah deployment. Bedakan perubahan kode dari integrasi production yang belum diterapkan.
````
