# 📋 Panduan Setup Supabase untuk SIGUMI

Panduan lengkap step-by-step untuk membuat dan mengkonfigurasi project Supabase SIGUMI.

---

## Langkah 1: Buat Project Supabase Baru

1. Buka [Supabase Dashboard](https://supabase.com/dashboard)
2. Klik **"New Project"**
3. Isi form:
   - **Organization**: Pilih organization Anda
   - **Project Name**: `SIGUMI`
   - **Database Password**: Buat password yang kuat (simpan baik-baik!)
   - **Region**: `Southeast Asia (Singapore)` — `ap-southeast-1`
4. Klik **"Create new project"**
5. Tunggu hingga project selesai di-provisioning (±2 menit)

---

## Langkah 2: Catat Kredensial Project

Setelah project siap, buka **Project Settings → API**:

1. **Project URL**: `https://xxxxx.supabase.co` — copy ini
2. **anon/public key**: `eyJhbGci.....` — copy ini
3. Paste kedua value tersebut ke file `lib/config/supabase_config.dart` di project Flutter

---

## Langkah 3: Aktifkan Ekstensi PostGIS

1. Buka **Database → Extensions** di Supabase Dashboard
2. Cari **"postgis"**
3. Klik toggle untuk mengaktifkannya
4. Pastikan schema-nya: `extensions`

Atau jalankan SQL berikut di **SQL Editor**:

```sql
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA extensions;
```

---

## Langkah 4: Konfigurasi Authentication

### 4a. Matikan Email Confirmations
SIGUMI menggunakan **email sintetis** dari nomor telepon (misal: `6281234567890@sigumi.app`)
untuk auth tanpa membutuhkan SMS provider. Oleh karena itu:

1. Buka **Authentication → Settings → Email Auth**
2. **Matikan** "Enable email confirmations" (WAJIB!)
3. Klik **Save**

> ⚠️ Ini WAJIB dilakukan! Karena email bersifat sintetis, verifikasi email tidak
> mungkin dilakukan.

### 4b. Setup SMS Provider (Produksi — Opsional)
Untuk produksi dengan OTP SMS sungguhan, Anda bisa menambahkan SMS provider:
- **Twilio** (paling umum)
- **Vonage** atau **MessageBird**

> 💡 Untuk development, skip langkah ini. Email sintetis sudah cukup.

---

## Langkah 5: Jalankan Migration SQL

Buka **SQL Editor** di Supabase Dashboard, lalu copy-paste dan jalankan file-file SQL berikut **SECARA BERURUTAN**:

### Urutan Eksekusi:
1. `supabase/migrations/001_create_profiles.sql`
2. `supabase/migrations/002_create_volcanoes.sql` 
3. `supabase/migrations/003_create_danger_zones.sql`
4. `supabase/migrations/004_rpc_get_user_risk_zone.sql`
5. `supabase/migrations/005_rpc_update_user_location.sql`
6. `supabase/migrations/006_seed_volcanoes.sql`
7. `supabase/migrations/007_create_shelters.sql`
8. `supabase/migrations/008_rpc_get_nearby_shelters.sql`
9. `supabase/migrations/009_seed_shelters.sql`

> 💡 Setiap file SQL sudah di-design idempotent. Kalau gagal, bisa dijalankan ulang.

---

## Langkah 6: Verifikasi Setup

Jalankan query berikut di SQL Editor untuk verifikasi:

```sql
-- Cek tabel sudah terbuat
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Cek PostGIS aktif
SELECT PostGIS_Version();

-- Cek data gunung berapi sudah ter-seed
SELECT name, status_level, 
       ST_Y(location::geometry) as lat, 
       ST_X(location::geometry) as lng 
FROM volcanoes;

-- Cek data shelter sudah ter-seed
SELECT s.name, s.type, s.distance_from_volcano, v.name as volcano
FROM shelters s
JOIN volcanoes v ON v.id = s.volcano_id
ORDER BY v.name, s.type, s.distance_from_volcano;

-- Test RPC get_user_risk_zone (dari Yogyakarta)
SELECT * FROM get_user_risk_zone(-7.7956, 110.3695);

-- Test RPC get_nearby_shelters (dari Yogyakarta)
SELECT * FROM get_nearby_shelters(-7.7956, 110.3695);
```

Semua query harus return data tanpa error.

---

## Langkah 7: Update Flutter Config

Buka file `lib/config/supabase_config.dart` dan isi:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';   // ← Ganti
  static const String anonKey = 'YOUR_ANON_KEY_HERE';                // ← Ganti
}
```

---

## Troubleshooting

### PostGIS tidak ditemukan
```sql
-- Coba enable dengan schema public
CREATE EXTENSION IF NOT EXISTS postgis;
```

### RPC Function error "function does not exist"
Pastikan semua migration dijalankan berurutan. RPC `get_user_risk_zone` bergantung pada tabel `volcanoes` yang harus sudah ada.

### Auth signup gagal (400 Bad Request)
Pastikan **"Enable email confirmations" sudah DIMATIKAN** di Authentication → Settings.
SIGUMI menggunakan email sintetis dari nomor telepon, sehingga verifikasi email tidak diperlukan.
