-- ============================================================
-- Migration 007: Tabel shelters (Posko Evakuasi & Fasilitas Kesehatan)
-- Menyimpan lokasi posko, rumah sakit, puskesmas di sekitar gunung
-- ============================================================

CREATE TABLE IF NOT EXISTS public.shelters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relasi ke gunung berapi terdekat
  volcano_id UUID NOT NULL REFERENCES public.volcanoes(id) ON DELETE CASCADE,

  -- Info dasar
  name TEXT NOT NULL,                    -- Nama fasilitas
  type TEXT NOT NULL CHECK (type IN (
    'posko_evakuasi',                    -- Posko/barak evakuasi
    'rumah_sakit',                       -- Rumah sakit
    'puskesmas',                         -- Puskesmas
    'klinik',                            -- Klinik kesehatan
    'balai_desa',                        -- Balai desa (posko darurat)
    'gor'                                -- GOR / gedung serba guna
  )),

  -- Lokasi PostGIS (geography untuk perhitungan jarak akurat)
  location GEOGRAPHY(POINT, 4326) NOT NULL,

  -- Detail fasilitas
  address TEXT,                          -- Alamat lengkap
  phone TEXT,                            -- Nomor telepon
  capacity INTEGER,                      -- Kapasitas tampung (orang)
  has_medical BOOLEAN DEFAULT false,     -- Ada tenaga medis?
  has_kitchen BOOLEAN DEFAULT false,     -- Ada dapur umum?
  has_toilet BOOLEAN DEFAULT true,       -- Ada MCK?
  is_24h BOOLEAN DEFAULT false,          -- Buka 24 jam?

  -- Status operasional
  is_active BOOLEAN DEFAULT true,        -- Masih beroperasi?
  notes TEXT,                            -- Catatan tambahan

  -- Jarak ke gunung (precomputed saat insert, km)
  distance_from_volcano DOUBLE PRECISION,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Index untuk query spasial & filter ──
CREATE INDEX IF NOT EXISTS idx_shelters_volcano
  ON public.shelters (volcano_id);

CREATE INDEX IF NOT EXISTS idx_shelters_type
  ON public.shelters (type);

CREATE INDEX IF NOT EXISTS idx_shelters_location
  ON public.shelters USING GIST (location);

CREATE INDEX IF NOT EXISTS idx_shelters_active
  ON public.shelters (is_active) WHERE is_active = true;

-- ============================================================
-- Row Level Security (RLS) — Public read
-- ============================================================
ALTER TABLE public.shelters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read shelters"
  ON public.shelters FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anon can read shelters"
  ON public.shelters FOR SELECT
  TO anon
  USING (true);
