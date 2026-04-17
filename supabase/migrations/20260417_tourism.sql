-- ============================================================
-- MIGRASI: Fitur Pariwisata SIGUMI
-- Jalankan di: Supabase Dashboard → SQL Editor
-- ============================================================

-- ── Tabel Destinasi Wisata ────────────────────────────────────
CREATE TABLE IF NOT EXISTS tourism_destinations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  region TEXT NOT NULL CHECK (region IN ('Yogyakarta', 'Bali', 'Lombok')),
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('Alam', 'Budaya', 'Pantai', 'Kuliner')),
  description TEXT,
  address TEXT,
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  photo_url TEXT,
  entry_fee INTEGER DEFAULT 0,
  open_hours TEXT DEFAULT '08.00 - 17.00',
  rating NUMERIC(2,1) DEFAULT 4.5,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Tabel Agenda/Event Wisata ─────────────────────────────────
CREATE TABLE IF NOT EXISTS tourism_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  destination_id UUID REFERENCES tourism_destinations(id) ON DELETE SET NULL,
  region TEXT NOT NULL CHECK (region IN ('Yogyakarta', 'Bali', 'Lombok')),
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT CHECK (event_type IN ('Festival', 'Pertunjukan', 'Ritual', 'Pameran')),
  start_date DATE NOT NULL,
  end_date DATE,
  time TEXT,
  location_name TEXT NOT NULL,
  price INTEGER DEFAULT 0,
  is_recurring BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── RLS: Buka akses read-only untuk semua user (anon & auth) ──
ALTER TABLE tourism_destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tourism_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tourism destinations readable by all"
  ON tourism_destinations FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Tourism events readable by all"
  ON tourism_events FOR SELECT
  TO anon, authenticated
  USING (true);

-- ── Index untuk performa query by region ─────────────────────
CREATE INDEX IF NOT EXISTS idx_tourism_destinations_region
  ON tourism_destinations(region);

CREATE INDEX IF NOT EXISTS idx_tourism_events_region_date
  ON tourism_events(region, start_date);

-- ============================================================
-- SEED DATA — Yogyakarta
-- ============================================================

INSERT INTO tourism_destinations (region, name, category, description, address, lat, lng, entry_fee, open_hours, rating) VALUES
(
  'Yogyakarta', 'Candi Borobudur', 'Budaya',
  'Candi Buddha terbesar di dunia, dibangun pada abad ke-8 oleh Dinasti Syailendra. Situs Warisan Dunia UNESCO yang menjadi kebanggaan Indonesia dengan arsitektur stupa yang megah dan relief yang menakjubkan.',
  'Jl. Badrawati, Borobudur, Magelang, Jawa Tengah',
  -7.6079, 110.2038, 50000, '06.00 - 17.00', 4.9
),
(
  'Yogyakarta', 'Candi Prambanan', 'Budaya',
  'Kompleks candi Hindu terbesar di Indonesia, didedikasikan untuk Trimurti: Brahma, Wisnu, dan Siwa. Terletak di perbatasan Yogyakarta dan Jawa Tengah dengan arsitektur yang menawan.',
  'Jl. Raya Solo - Yogyakarta, Prambanan, Sleman',
  -7.7520, 110.4914, 50000, '06.00 - 17.00', 4.8
),
(
  'Yogyakarta', 'Pantai Parangtritis', 'Pantai',
  'Pantai ikonik Yogyakarta dengan pasir hitam dan ombak yang besar. Dikenal dengan legenda Nyi Roro Kidul dan pemandangan matahari terbenam yang memukau.',
  'Parangtritis, Kretek, Bantul, Yogyakarta',
  -8.0257, 110.3325, 10000, '24 Jam', 4.5
),
(
  'Yogyakarta', 'Malioboro', 'Kuliner',
  'Jantung kota Yogyakarta — pusat perbelanjaan, kuliner, dan budaya. Nikmati gudeg, bakpia, dan berbagai kuliner khas Jogja sambil menikmati suasana kota yang hidup.',
  'Jl. Malioboro, Gedong Tengen, Yogyakarta',
  -7.7929, 110.3659, 0, '24 Jam', 4.7
),
(
  'Yogyakarta', 'Gunung Merapi Tour', 'Alam',
  'Wisata jeep off-road mengelilingi sisi gunung berapi paling aktif di Indonesia. Saksikan sisa-sisa erupsi 2010, lava tour malam hari, dan pemandangan Merapi dari dekat.',
  'Kaliurang, Pakem, Sleman, Yogyakarta',
  -7.5407, 110.4457, 300000, '05.00 - 17.00', 4.8
);

-- ── SEED DATA — Bali ─────────────────────────────────────────

INSERT INTO tourism_destinations (region, name, category, description, address, lat, lng, entry_fee, open_hours, rating) VALUES
(
  'Bali', 'Pura Tanah Lot', 'Budaya',
  'Pura Hindu yang berdiri di atas batu karang di tengah laut. Salah satu objek wisata paling ikonik di Bali dengan pemandangan matahari terbenam yang spektakuler.',
  'Beraban, Kediri, Tabanan, Bali',
  -8.6211, 115.0868, 60000, '07.00 - 19.00', 4.8
),
(
  'Bali', 'Tegalalang Rice Terrace', 'Alam',
  'Sawah terasering yang indah di dataran tinggi Ubud. UNESCO mengakui subak (sistem irigasi tradisional Bali) sebagai Warisan Budaya Dunia.',
  'Tegallalang, Gianyar, Bali',
  -8.4312, 115.2786, 15000, '08.00 - 18.00', 4.6
),
(
  'Bali', 'Pantai Kuta', 'Pantai',
  'Pantai paling terkenal di Bali dengan hamparan pasir putih dan ombak yang cocok untuk surfing. Ramai dengan wisatawan, pedagang, dan kehidupan malam yang meriah.',
  'Kuta, Badung, Bali',
  -8.7184, 115.1686, 0, '24 Jam', 4.5
),
(
  'Bali', 'Pura Uluwatu', 'Budaya',
  'Pura suci di tepi tebing setinggi 70 meter di ujung selatan Bali. Terkenal dengan pertunjukan Tari Kecak saat matahari terbenam yang memukau.',
  'Pecatu, Kuta Selatan, Badung, Bali',
  -8.8291, 115.0849, 50000, '09.00 - 19.00', 4.9
),
(
  'Bali', 'Ubud Monkey Forest', 'Alam',
  'Hutan suci seluas 12,5 hektar yang dihuni ratusan monyet ekor panjang. Terdapat tiga pura kuno di dalamnya dengan nuansa mistis dan asri.',
  'Jl. Monkey Forest, Ubud, Gianyar, Bali',
  -8.5188, 115.2592, 80000, '09.00 - 17.30', 4.6
);

-- ── SEED DATA — Lombok ───────────────────────────────────────

INSERT INTO tourism_destinations (region, name, category, description, address, lat, lng, entry_fee, open_hours, rating) VALUES
(
  'Lombok', 'Pantai Mandalika', 'Pantai',
  'Kawasan wisata premium di selatan Lombok dengan pantai pasir putih yang panjang. Tuan rumah MotoGP Mandalika Circuit, menjadikannya destinasi kelas dunia.',
  'Kuta, Pujut, Lombok Tengah, NTB',
  -8.8836, 116.2955, 10000, '24 Jam', 4.8
),
(
  'Lombok', 'Gili Trawangan', 'Pantai',
  'Pulau kecil paling populer dari Tiga Gili di Lombok Barat. Bebas kendaraan bermotor, kaya terumbu karang, dan destinasi favorit snorkeling & diving.',
  'Gili Indah, Pemenang, Lombok Utara, NTB',
  -8.3529, 116.0247, 0, '24 Jam', 4.7
),
(
  'Lombok', 'Air Terjun Sendang Gile', 'Alam',
  'Air terjun bertingkat yang menakjubkan di kaki Gunung Rinjani. Dua air terjun bertumpuk dengan pemandangan hutan tropis yang hijau dan menyejukkan.',
  'Senaru, Bayan, Lombok Utara, NTB',
  -8.3211, 116.4247, 10000, '07.00 - 17.00', 4.7
),
(
  'Lombok', 'Desa Sade', 'Budaya',
  'Desa adat Suku Sasak yang masih mempertahankan tradisi leluhur. Rumah tradisional dari lumpur kerbau, tenun Sasak, dan tarian tradisional yang autentik.',
  'Rembitan, Pujut, Lombok Tengah, NTB',
  -8.8471, 116.2637, 0, '08.00 - 17.00', 4.5
),
(
  'Lombok', 'Gunung Rinjani', 'Alam',
  'Gunung berapi aktif tertinggi kedua di Indonesia (3.726 mdpl). Surga para pendaki dengan danau kawah Segara Anak yang indah dan panorama 360 derajat yang luar biasa.',
  'Sembalun, Lombok Timur, NTB',
  -8.4111, 116.4573, 150000, '05.00 - 17.00', 4.9
);

-- ============================================================
-- SEED DATA — Events
-- ============================================================

INSERT INTO tourism_events (region, title, description, event_type, start_date, end_date, time, location_name, price, is_recurring) VALUES
-- Yogyakarta
(
  'Yogyakarta', 'Sendratari Ramayana', 
  'Pertunjukan tari Ramayana dengan latar belakang Candi Prambanan yang megah. Cerita epik yang dipersembahkan oleh ratusan penari terlatih.',
  'Pertunjukan', '2026-05-01', NULL, '19.30 WIB', 'Panggung Terbuka Prambanan', 125000, TRUE
),
(
  'Yogyakarta', 'Karnaval Malioboro',
  'Parade budaya tahunan yang meriah di sepanjang Jalan Malioboro dengan kostum tradisional, musik gamelan, dan tarian daerah.',
  'Festival', '2026-05-10', '2026-05-10', '15.00 - 21.00 WIB', 'Jalan Malioboro, Yogyakarta', 0, FALSE
),
(
  'Yogyakarta', 'Sekaten',
  'Perayaan Maulid Nabi Muhammad SAW dengan pasar malam, gamelan sekaten, dan iring-iringan grebeg yang meriah di alun-alun Keraton.',
  'Festival', '2026-06-05', '2026-06-12', '09.00 - 22.00 WIB', 'Alun-alun Utara Keraton Yogyakarta', 0, FALSE
),
-- Bali
(
  'Bali', 'Tari Kecak Uluwatu',
  'Pertunjukan tari Kecak dramatis dengan latar matahari terbenam di tepi tebing Pura Uluwatu. Menceritakan kisah Ramayana tanpa musik, hanya suara "cak" ratusan penari.',
  'Pertunjukan', '2026-04-18', NULL, '18.00 WITA', 'Pura Uluwatu, Badung', 100000, TRUE
),
(
  'Bali', 'Festival Seni Ubud',
  'Festival seni dan budaya bergengsi tahunan di Ubud dengan pertunjukan tari, musik tradisional, pameran lukisan, dan workshop seni.',
  'Festival', '2026-05-01', '2026-05-08', '10.00 - 22.00 WITA', 'Ubud Palace & Arjuna Stage', 50000, FALSE
),
-- Lombok
(
  'Lombok', 'Pertunjukan Gendang Beleq',
  'Pertunjukan musik tradisional Lombok dengan gendang raksasa (beleq) yang biasanya mengiringi upacara adat, perang, dan pernikahan Sasak.',
  'Pertunjukan', '2026-04-23', NULL, '16.00 WITA', 'Desa Sade, Lombok Tengah', 0, TRUE
),
(
  'Lombok', 'Lombok Sumbawa Expo',
  'Pameran produk unggulan, kuliner, dan kerajinan tangan dari Lombok dan Sumbawa. Ajang promosi wisata dan investasi daerah.',
  'Pameran', '2026-05-07', '2026-05-14', '09.00 - 21.00 WITA', 'Lombok Epicentrum Mall', 0, FALSE
),
(
  'Lombok', 'Festival Bau Nyale',
  'Ritual tahunan Suku Sasak menangkap cacing nyale (cacing laut) di pantai selatan Lombok. Diiringi atraksi presean (silat Sasak) dan hiburan tradisional.',
  'Ritual', '2027-02-19', NULL, '03.00 WITA', 'Pantai Seger, Mandalika', 0, FALSE
);
