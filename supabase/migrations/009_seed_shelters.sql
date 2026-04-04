-- ============================================================
-- Migration 009: Seed data Posko Evakuasi & Fasilitas Kesehatan
-- Data realistis berdasarkan lokasi nyata di sekitar 3 gunung
-- ============================================================
-- Catatan:
-- ST_MakePoint(LONGITUDE, LATITUDE) — PostGIS format
-- distance_from_volcano dihitung otomatis via subquery
-- ============================================================

-- ══════════════════════════════════════════════════════════════
-- GUNUNG MERAPI — Yogyakarta / Sleman / Klaten
-- Volcano ID: a1b2c3d4-e5f6-7890-abcd-111111111111
-- ══════════════════════════════════════════════════════════════

INSERT INTO public.shelters (volcano_id, name, type, location, address, phone, capacity, has_medical, has_kitchen, has_toilet, is_24h, distance_from_volcano, notes) VALUES

-- ── Posko Evakuasi Merapi ──
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Barak Pengungsian Glagaharjo',
  'posko_evakuasi',
  ST_SetSRID(ST_MakePoint(110.4721, -7.6358), 4326)::geography,
  'Desa Glagaharjo, Kec. Cangkringan, Sleman',
  '0274-895123',
  350,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4721, -7.6358), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Barak utama lereng selatan. Dilengkapi tenda darurat dan logistik BPBD.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Barak Pengungsian Kepuharjo',
  'posko_evakuasi',
  ST_SetSRID(ST_MakePoint(110.4537, -7.6142), 4326)::geography,
  'Desa Kepuharjo, Kec. Cangkringan, Sleman',
  '0274-895234',
  250,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4537, -7.6142), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko evakuasi utama untuk warga lereng selatan Merapi.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Stadion Maguwoharjo',
  'gor',
  ST_SetSRID(ST_MakePoint(110.4182, -7.7505), 4326)::geography,
  'Jl. Stadion Maguwoharjo, Depok, Sleman',
  '0274-869500',
  5000,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4182, -7.7505), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko penampungan massal. Digunakan saat erupsi besar 2010. Kapasitas besar.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Balai Desa Umbulharjo',
  'balai_desa',
  ST_SetSRID(ST_MakePoint(110.4385, -7.6280), 4326)::geography,
  'Desa Umbulharjo, Kec. Cangkringan, Sleman',
  '0274-896100',
  150,
  false, true, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4385, -7.6280), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko darurat desa. Tersedia dapur umum dan MCK.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Balai Desa Hargobinangun',
  'balai_desa',
  ST_SetSRID(ST_MakePoint(110.4015, -7.6185), 4326)::geography,
  'Desa Hargobinangun, Kec. Pakem, Sleman',
  '0274-895567',
  200,
  false, true, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4015, -7.6185), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko darurat lereng barat Merapi.'
),

-- ── Fasilitas Kesehatan Merapi ──
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Puskesmas Cangkringan',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(110.4578, -7.6749), 4326)::geography,
  'Panggung, Argomulyo, Kec. Cangkringan, Sleman',
  '0274-896055',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4578, -7.6749), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas terdekat lereng selatan. Rawat jalan dan UGD dasar.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Puskesmas Pakem',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(110.4152, -7.6581), 4326)::geography,
  'Jl. Kaliurang KM 17.5, Kec. Pakem, Sleman',
  '0274-895146',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4152, -7.6581), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas rawat inap. Melayani area lereng barat Merapi.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'RS Panti Nugroho',
  'rumah_sakit',
  ST_SetSRID(ST_MakePoint(110.4168, -7.6545), 4326)::geography,
  'Jl. Kaliurang KM 17, Pakembinangun, Pakem, Sleman',
  '0274-895037',
  NULL,
  true, false, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4168, -7.6545), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'RS umum swasta terdekat dari lereng Merapi. UGD 24 jam.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'Puskesmas Kemalang',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(110.4805, -7.6314), 4326)::geography,
  'Kec. Kemalang, Kabupaten Klaten, Jawa Tengah',
  '0272-330215',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.4805, -7.6314), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas sisi timur Merapi (Klaten). Rawat jalan dan UGD.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-111111111111',
  'RSUD Sleman',
  'rumah_sakit',
  ST_SetSRID(ST_MakePoint(110.3492, -7.7165), 4326)::geography,
  'Jl. Bhayangkara No.48, Triharjo, Sleman',
  '0274-868720',
  NULL,
  true, false, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(110.3492, -7.7165), 4326)::geography,
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography
  ) / 1000)::numeric, 2),
  'Rumah sakit utama rujukan bencana Merapi. UGD 24 jam, bedah, ICU.'
);


-- ══════════════════════════════════════════════════════════════
-- GUNUNG AGUNG — Bali / Karangasem
-- Volcano ID: a1b2c3d4-e5f6-7890-abcd-222222222222
-- ══════════════════════════════════════════════════════════════

INSERT INTO public.shelters (volcano_id, name, type, location, address, phone, capacity, has_medical, has_kitchen, has_toilet, is_24h, distance_from_volcano, notes) VALUES

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
  'Klinik praktik di lereng timur laut Agung. P3K dan rujukan.'
);


-- ══════════════════════════════════════════════════════════════
-- GUNUNG RINJANI — Lombok / NTB
-- Volcano ID: a1b2c3d4-e5f6-7890-abcd-333333333333
-- ══════════════════════════════════════════════════════════════

INSERT INTO public.shelters (volcano_id, name, type, location, address, phone, capacity, has_medical, has_kitchen, has_toilet, is_24h, distance_from_volcano, notes) VALUES

-- ── Posko Evakuasi Rinjani ──
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'Posko Sembalun Lawang',
  'posko_evakuasi',
  ST_SetSRID(ST_MakePoint(116.5142, -8.4825), 4326)::geography,
  'Desa Sembalun Lawang, Kec. Sembalun, Lombok Timur',
  '0376-22456',
  300,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.5142, -8.4825), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko utama jalur pendakian Sembalun. Tersedia tim SAR.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'Posko Senaru',
  'posko_evakuasi',
  ST_SetSRID(ST_MakePoint(116.4085, -8.3115), 4326)::geography,
  'Desa Senaru, Kec. Bayan, Lombok Utara',
  '0376-22789',
  250,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.4085, -8.3115), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko evakuasi jalur Senaru. Pos pendakian utara TNGR.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'Balai Desa Aikmel',
  'balai_desa',
  ST_SetSRID(ST_MakePoint(116.5478, -8.5250), 4326)::geography,
  'Desa Aikmel, Kec. Aikmel, Lombok Timur',
  '0376-22123',
  200,
  false, true, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.5478, -8.5250), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'Posko darurat desa. Penampungan sementara warga lereng timur.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'GOR Dasan Agung',
  'gor',
  ST_SetSRID(ST_MakePoint(116.1201, -8.5812), 4326)::geography,
  'Jl. Pemuda, Mataram, NTB',
  '0370-623011',
  2000,
  true, true, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.1201, -8.5812), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'GOR besar di Mataram. Penampungan massal jika erupsi besar.'
),

-- ── Fasilitas Kesehatan Rinjani ──
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'Puskesmas Sembalun',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(116.5198, -8.4915), 4326)::geography,
  'Desa Sembalun Bumbung, Kec. Sembalun, Lombok Timur',
  '0376-22567',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.5198, -8.4915), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas terdekat dari jalur Sembalun. Rawat jalan dan P3K.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'Puskesmas Bayan',
  'puskesmas',
  ST_SetSRID(ST_MakePoint(116.3850, -8.2855), 4326)::geography,
  'Desa Bayan, Kec. Bayan, Lombok Utara',
  '0376-22890',
  NULL,
  true, false, true, false,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.3850, -8.2855), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'Puskesmas lereng utara Rinjani. Rawat jalan dan UGD dasar.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'RSUD dr. R. Soedjono',
  'rumah_sakit',
  ST_SetSRID(ST_MakePoint(116.5480, -8.6545), 4326)::geography,
  'Jl. Prof. M. Yamin No.55, Selong, Lombok Timur',
  '0376-21260',
  NULL,
  true, false, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.5480, -8.6545), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'RS utama Lombok Timur. UGD 24 jam, ICU, bedah. RS rujukan utama TNGR.'
),
(
  'a1b2c3d4-e5f6-7890-abcd-333333333333',
  'RSUD Kota Mataram',
  'rumah_sakit',
  ST_SetSRID(ST_MakePoint(116.1050, -8.5920), 4326)::geography,
  'Jl. Pejanggik No.6, Mataram, NTB',
  '0370-621365',
  NULL,
  true, false, true, true,
  ROUND((ST_Distance(
    ST_SetSRID(ST_MakePoint(116.1050, -8.5920), 4326)::geography,
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography
  ) / 1000)::numeric, 2),
  'RS terbesar di NTB. Fasilitas lengkap untuk trauma center bencana.'
);
