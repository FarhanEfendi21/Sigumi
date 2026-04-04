-- ============================================================
-- Migration 002: Tabel volcanoes
-- Data gunung berapi Indonesia dengan koordinat PostGIS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.volcanoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  -- Lokasi gunung sebagai PostGIS geography point (SRID 4326 = WGS84)
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  elevation DOUBLE PRECISION NOT NULL,
  status_level INTEGER NOT NULL DEFAULT 1 CHECK (status_level BETWEEN 1 AND 4),
  -- 1 = Normal, 2 = Waspada, 3 = Siaga, 4 = Awas
  status_description TEXT,
  last_eruption TEXT,
  recent_activities JSONB DEFAULT '[]'::JSONB,
  temperature DOUBLE PRECISION,
  wind_direction TEXT,
  wind_speed DOUBLE PRECISION,
  image_url TEXT,
  region TEXT NOT NULL,
  last_update TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Spatial index untuk query PostGIS
CREATE INDEX IF NOT EXISTS idx_volcanoes_location 
  ON public.volcanoes USING GIST (location);

-- Index untuk filter by region
CREATE INDEX IF NOT EXISTS idx_volcanoes_region 
  ON public.volcanoes (region);

-- ============================================================
-- Row Level Security (RLS)
-- Semua authenticated user bisa read, hanya service_role bisa write
-- ============================================================
ALTER TABLE public.volcanoes ENABLE ROW LEVEL SECURITY;

-- Semua authenticated user bisa baca data gunung
CREATE POLICY "Anyone can read volcanoes"
  ON public.volcanoes FOR SELECT
  TO authenticated
  USING (true);

-- Untuk anon users (public read juga diizinkan untuk peta publik)
CREATE POLICY "Anon can read volcanoes"
  ON public.volcanoes FOR SELECT
  TO anon
  USING (true);
