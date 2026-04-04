-- ============================================================
-- Migration 003: Tabel danger_zones
-- Zona bahaya per gunung berapi (radius-based)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.danger_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  volcano_id UUID NOT NULL REFERENCES public.volcanoes(id) ON DELETE CASCADE,
  zone_level INTEGER NOT NULL CHECK (zone_level BETWEEN 1 AND 4),
  -- 4 = ZONA BAHAYA UTAMA (0-5km)
  -- 3 = ZONA WASPADA (5-10km)
  -- 2 = ZONA PERHATIAN (10-15km)
  -- 1 = ZONA RELATIF AMAN (15-20km+)
  zone_label TEXT NOT NULL,
  radius_km DOUBLE PRECISION NOT NULL,
  description TEXT,
  color_hex TEXT, -- Warna di peta, misal '#EF4444'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk join dengan volcanoes
CREATE INDEX IF NOT EXISTS idx_danger_zones_volcano 
  ON public.danger_zones (volcano_id);

-- ============================================================
-- Row Level Security (RLS) — Public read
-- ============================================================
ALTER TABLE public.danger_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read danger zones"
  ON public.danger_zones FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anon can read danger zones"
  ON public.danger_zones FOR SELECT
  TO anon
  USING (true);
