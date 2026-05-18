-- ============================================================
-- Migration: Tambah kolom klimatologi ke volcanic_daily_reports
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================================

ALTER TABLE volcanic_daily_reports
  ADD COLUMN IF NOT EXISTS weather         TEXT,
  ADD COLUMN IF NOT EXISTS wind_direction  TEXT,
  ADD COLUMN IF NOT EXISTS wind_speed_text TEXT,
  ADD COLUMN IF NOT EXISTS temp_min        NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS temp_max        NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS humidity_min    NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS humidity_max    NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS pressure_min    NUMERIC(8,2),
  ADD COLUMN IF NOT EXISTS pressure_max    NUMERIC(8,2);

-- Verifikasi kolom baru
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'volcanic_daily_reports'
  AND column_name IN (
    'weather', 'wind_direction', 'wind_speed_text',
    'temp_min', 'temp_max',
    'humidity_min', 'humidity_max',
    'pressure_min', 'pressure_max'
  )
ORDER BY column_name;
