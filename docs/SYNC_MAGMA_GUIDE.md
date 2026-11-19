# Panduan Lengkap Sinkronisasi Realtime MAGMA Indonesia ke Supabase

Dokumen ini menjelaskan penyebab data status gunung sebelumnya tidak bergerak (stuck 3 April) serta langkah mengaktifkan sinkronisasi otomatis menggunakan **Supabase Edge Function** dan **Cron Job**.

---

## 1. Mengapa Data Sebelumnya Stuck (3 Apr 17:57)?

Arsitektur aplikasi SIGUMI:
```
Website MAGMA ESDM  ──(Scraper/Sync)──>  Database Supabase  ──(Realtime WebSocket)──>  Aplikasi SIGUMI
[magma.esdm.go.id]                        [rtwanteecrvydxyrgpii]                         [Flutter / Web]
```
- **Supabase Realtime di aplikasi SIGUMI berjalan normal.**
- Namun, website MAGMA ESDM (PVMBG) tidak menyediakan push webhook ke Supabase.
- Data di database Supabase terakhir kali diisi melalui migration `006_seed_volcanoes.sql` pada 3 April. Tanpa ada script yang memperbarui data di Supabase, timestamp dan statusnya tidak akan berubah.

---

## 2. Solusi yang Telah Dibuat

Kami telah menyiapkan seluruh komponen otomatisasi:

| Komponen | Lokasi File | Fungsi |
|---|---|---|
| **Edge Function** | [`supabase/functions/sync-magma/index.ts`](file:///c:/Users/Lenovo/.gemini/antigravity/scratch/sigumi/supabase/functions/sync-magma/index.ts) | Mengambil data live dari MAGMA Indonesia (`/v1/gunung-api/tingkat-aktivitas`), mem-parsing 69+ gunung, mencocokkan dengan database, dan meng-update status secara otomatis. |
| **Cron Migration** | [`supabase/migrations/013_sync_magma_cron.sql`](file:///c:/Users/Lenovo/.gemini/antigravity/scratch/sigumi/supabase/migrations/013_sync_magma_cron.sql) | Menjalankan sinkronisasi otomatis setiap 10 menit di Postgres menggunakan `pg_cron` dan `pg_net`. |
| **Config** | [`supabase/config.toml`](file:///c:/Users/Lenovo/.gemini/antigravity/scratch/sigumi/supabase/config.toml) | Konfigurasi project Supabase `rtwanteecrvydxyrgpii`. |
| **GitHub Actions** | [`.github/workflows/sync_magma.yml`](file:///c:/Users/Lenovo/.gemini/antigravity/scratch/sigumi/.github/workflows/sync_magma.yml) | Alternatif cron gratis via GitHub Actions setiap 15 menit. |

---

## 3. Langkah Deploy Edge Function

Pilih salah satu metode berikut:

### Opsi A: Deploy via Supabase CLI (Rekomendasi)

Jalankan perintah berikut di terminal:
```bash
# 1. Login ke akun Supabase Anda
npx supabase login

# 2. Deploy function sync-magma ke project rtwanteecrvydxyrgpii
npx supabase functions deploy sync-magma --project-ref rtwanteecrvydxyrgpii --no-verify-jwt
```

### Opsi B: Deploy via Supabase Dashboard (Tanpa CLI)

1. Buka browser: [Supabase Dashboard - Edge Functions](https://supabase.com/dashboard/project/rtwanteecrvydxyrgpii/functions)
2. Klik tombol **"Create a new function"**.
3. Beri nama: `sync-magma`.
4. Salin seluruh isi dari file [`supabase/functions/sync-magma/index.ts`](file:///c:/Users/Lenovo/.gemini/antigravity/scratch/sigumi/supabase/functions/sync-magma/index.ts) dan tempel ke code editor di Dashboard.
5. Pada pengaturan Function Settings:
   - Nonaktifkan **"Enforce JWT Verification"** (agar cron job dan webhook bisa memanggilnya dengan mudah).
6. Klik **"Deploy"**.

---

## 4. Langkah Mengaktifkan Cron Job Otomatis

Setelah Edge Function di-deploy, aktifkan jadwal penarikan data berkala:

### Opsi 1: Menggunakan SQL Editor Supabase (`pg_cron`)

1. Buka [Supabase Dashboard -> SQL Editor](https://supabase.com/dashboard/project/rtwanteecrvydxyrgpii/sql).
2. Buka file [`supabase/migrations/013_sync_magma_cron.sql`](file:///c:/Users/Lenovo/.gemini/antigravity/scratch/sigumi/supabase/migrations/013_sync_magma_cron.sql).
3. Salin seluruh kodenya, tempel ke SQL Editor, lalu klik **"Run"**.
4. Database Postgres Anda sekarang akan memanggil Edge Function setiap 10 menit secara otomatis.

### Opsi 2: Menggunakan GitHub Actions (Gratis & Cloud)

Jika repository Anda sudah di-push ke GitHub:
1. File workflow sudah tersedia di `.github/workflows/sync_magma.yml`.
2. Masuk ke GitHub Repository -> **Settings** -> **Secrets and variables** -> **Actions**.
3. Tambahkan secret baru:
   - Name: `SUPABASE_SERVICE_ROLE_KEY` (ambil dari Supabase Dashboard -> Project Settings -> API -> `service_role`).
4. GitHub Actions akan otomatis melakukan ping ke Edge Function setiap 15 menit.

---

## 5. Cara Menguji dan Memverifikasi Hasilnya

Setelah di-deploy, Anda bisa langsung mengujinya:

### 1. Panggil Endpoint Secara Manual
Buka terminal atau browser dan panggil:
```bash
curl -X POST https://rtwanteecrvydxyrgpii.supabase.co/functions/v1/sync-magma
```
Atau langsung akses URL tersebut di browser jika GET didukung.

Respons sukses yang akan muncul:
```json
{
  "success": true,
  "message": "Synced 3 volcanoes from MAGMA Indonesia",
  "timestamp": "2026-09-13T07:40:00.000Z",
  "totalMagmaParsed": 69,
  "updates": [
    {
      "name": "Gunung Merapi",
      "previousLevel": 3,
      "currentLevel": 3,
      "status": "Siaga"
    },
    {
      "name": "Gunung Agung",
      "previousLevel": 1,
      "currentLevel": 1,
      "status": "Normal"
    },
    {
      "name": "Gunung Rinjani",
      "previousLevel": 2,
      "currentLevel": 2,
      "status": "Waspada"
    }
  ]
}
```

### 2. Cek di Aplikasi SIGUMI
- Buka aplikasi SIGUMI (Mobile/Web).
- Perhatikan label **"Terupdate"**: tanggalnya akan langsung berubah dari **3 Apr 17.57** menjadi **waktu hari ini**.
- Setiap kali PVMBG mengubah status gunung di situs resmi MAGMA Indonesia, aplikasi SIGUMI akan otomatis mendapatkan perubahan status tersebut dalam hitungan detik melalui Supabase Realtime!
