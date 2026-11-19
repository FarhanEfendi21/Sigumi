-- ============================================================
-- Migration: Tambahan kolom VAR & VONA MAGMA Indonesia pada volcano_summarizer
-- Idempoten: aman dijalankan pada database yang sudah maupun belum memiliki tabel.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.volcano_summarizer (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fetched_at TIMESTAMPTZ DEFAULT NOW(),
  report_date DATE NOT NULL,
  volcano_name TEXT NOT NULL,
  volcano_key TEXT NOT NULL,
  level_code INTEGER DEFAULT 1,
  level_name TEXT NOT NULL,
  period_start TEXT,
  period_end TEXT,
  timezone TEXT DEFAULT 'WIB',
  summary TEXT,
  detail_url TEXT,
  author TEXT,
  weather TEXT,
  wind_direction TEXT,
  wind_speed_text TEXT,
  temp_min NUMERIC(5,2),
  temp_max NUMERIC(5,2),
  humidity_min NUMERIC(5,2),
  humidity_max NUMERIC(5,2),
  pressure_min NUMERIC(8,2),
  pressure_max NUMERIC(8,2),
  UNIQUE (volcano_key, report_date, period_start)
);

ALTER TABLE public.volcano_summarizer
  ADD COLUMN IF NOT EXISTS visual_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS vona_color_code TEXT,
  ADD COLUMN IF NOT EXISTS visibility TEXT,
  ADD COLUMN IF NOT EXISTS crater_smoke TEXT,
  ADD COLUMN IF NOT EXISTS avalanche_notes TEXT,
  ADD COLUMN IF NOT EXISTS seismicity JSONB DEFAULT '{}'::JSONB;

CREATE INDEX IF NOT EXISTS idx_volcano_summarizer_key_date
  ON public.volcano_summarizer (volcano_key, report_date DESC);

ALTER TABLE public.volcano_summarizer ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read volcano_summarizer"
  ON public.volcano_summarizer;
CREATE POLICY "Public can read volcano_summarizer"
  ON public.volcano_summarizer FOR SELECT
  TO anon, authenticated
  USING (true);
