-- ============================================================
-- FIX: Upsert data shelter Bali (Gunung Agung)
-- Jalankan di Supabase SQL Editor jika data Bali belum ada
-- UUID Agung: a1b2c3d4-e5f6-7890-abcd-222222222222
-- ============================================================

-- Cek dulu apakah data Bali sudah ada
DO $$
DECLARE
  bali_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO bali_count
  FROM public.shelters
  WHERE volcano_id = 'a1b2c3d4-e5f6-7890-abcd-222222222222';
  
  IF bali_count > 0 THEN
    RAISE NOTICE 'Data Bali sudah ada: % record ditemukan.', bali_count;
  ELSE
    RAISE NOTICE 'Data Bali BELUM ada. Jalankan INSERT di bawah ini.';
  END IF;
END;
$$;

-- ── INSERT data Bali (idempoten via ON CONFLICT DO NOTHING tidak bisa karena PK auto) ──
-- Hapus dulu jika ada duplikat, lalu insert ulang
DELETE FROM public.shelters WHERE volcano_id = 'a1b2c3d4-e5f6-7890-abcd-222222222222';

INSERT INTO public.shelters (volcano_id, name, type, location, address, phone, capacity, has_medical, has_kitchen, has_toilet, is_24h, distance_from_volcano, notes)
VALUES

-- ── Posko Evakuasi Agung ──
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Posko Evakuasi Rendang',
  'posko_evakuasi',
  ST_SetSRID(ST_MakePoint(115.4261, -8.4286), 4326)::geography,
  'Desa Rendang, Kec. Rendang, Karangasem, Bali',
  '0363-23150',
  400,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4261, -8.4286), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko utama BPBD untuk evakuasi Gunung Agung. Pusat koordinasi darurat.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'GOR Swecapura Klungkung',
  'gor',
  ST_SetSRID(ST_MakePoint(115.4048, -8.5362), 4326)::geography,
  'Jl. Untung Surapati, Semarapura, Klungkung, Bali',
  '0366-21012',
  3000,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4048, -8.5362), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'GOR besar untuk penampungan massal. Digunakan saat erupsi 2017-2019.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Balai Banjar Duda Timur',
  'balai_desa',
  ST_SetSRID(ST_MakePoint(115.4631, -8.4472), 4326)::geography,
  'Banjar Duda Timur, Desa Duda, Kec. Selat, Karangasem',
  '0363-23200',
  200,
  false, true, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4631, -8.4472), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko darurat banjar. Tersedia MCK dan dapur umum.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Posko Evakuasi Sidemen',
  'posko_evakuasi',
  ST_SetSRID(ST_MakePoint(115.4489, -8.4688), 4326)::geography,
  'Desa Sidemen, Kec. Sidemen, Karangasem, Bali',
  '0363-23456',
  300,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4489, -8.4688), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko evakuasi sekunder lereng barat daya Agung.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Posko Evakuasi Besakih',
  'posko_evakuasi',
  ST_SetSRID(ST_MakePoint(115.4521, -8.3751), 4326)::geography,
  'Desa Besakih, Kec. Rendang, Karangasem, Bali',
  '0363-23501',
  500,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4521, -8.3751), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko utama lereng barat Agung. Dekat Pura Besakih. Kapasitas besar.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Balai Banjar Muncan',
  'balai_desa',
  ST_SetSRID(ST_MakePoint(115.4412, -8.4012), 4326)::geography,
  'Banjar Muncan, Desa Muncan, Kec. Selat, Karangasem',
  '0363-23300',
  150,
  false, true, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4412, -8.4012), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko darurat desa Muncan. Dapur umum dan MCK tersedia.'
),

-- ── Fasilitas Kesehatan Agung ──
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Puskesmas Rendang',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(115.4240, -8.4310), 4326)::geography,
  'Jl. Raya Rendang, Kec. Rendang, Karangasem, Bali',
  '0363-23155',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4240, -8.4310), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas terdekat lereng barat Agung. Rawat jalan dan UGD.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Puskesmas Selat',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(115.4575, -8.4521), 4326)::geography,
  'Jl. Raya Selat, Kec. Selat, Karangasem, Bali',
  '0363-23189',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.4575, -8.4521), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas rawat inap. Melayani area lereng selatan Agung.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'RSUD Karangasem',
  'rumah_sakit',
  ST_SetSRID(ST_MakePoint(115.6021, -8.4495), 4326)::geography,
  'Jl. Ngurah Rai, Amlapura, Karangasem, Bali',
  '0363-21573',
  NULL,
  true, false, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.6021, -8.4495), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'RS utama Karangasem. UGD 24 jam, bedah, rawat inap. RS rujukan bencana.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Klinik Pratama Kubu',
  'klinik',
  ST_SetSRID(ST_MakePoint(115.5812, -8.3165), 4326)::geography,
  'Desa Kubu, Kec. Kubu, Karangasem, Bali',
  '0363-22100',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.5812, -8.3165), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Klinik di lereng timur laut Agung. P3K dan rujukan.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'RS Balimed Karangasem',
  'rumah_sakit',
  ST_SetSRID(ST_MakePoint(115.5987, -8.4398), 4326)::geography,
  'Jl. Diponegoro, Amlapura, Karangasem, Bali',
  '0363-22555',
  NULL,
  true, false, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.5987, -8.4398), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'RS swasta Karangasem. UGD 24 jam. Pelayanan lengkap.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-222222222222',
  'Puskesmas Kubu',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(115.5894, -8.3045), 4326)::geography,
  'Jl. Raya Kubu, Kec. Kubu, Karangasem, Bali',
  '0363-22210',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(115.5894, -8.3045), 4326)::geography,
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas lereng timur laut Agung. Rawat jalan.'
);

-- Verifikasi hasil
SELECT type, COUNT(*) as total 
FROM public.shelters 
WHERE volcano_id = 'a1b2c3d4-e5f6-7890-abcd-222222222222'
GROUP BY type
ORDER BY type;
