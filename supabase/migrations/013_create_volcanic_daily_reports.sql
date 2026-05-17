-- ============================================================
-- Migration 013: Volcanic Daily Reports (MAGMA Indonesia)
-- Menyimpan laporan harian gunung berapi hasil scraping MAGMA
-- ============================================================

CREATE TABLE IF NOT EXISTS volcanic_daily_reports (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  fetched_at    timestamptz DEFAULT now(),
  report_date   date NOT NULL,
  volcano_name  text NOT NULL,           -- "Merapi", "Agung", "Rinjani"
  volcano_key   text NOT NULL,           -- "merapi", "agung", "rinjani" (normalized)
  level_code    int NOT NULL DEFAULT 1,  -- 1=Normal, 2=Waspada, 3=Siaga, 4=Awas
  level_name    text NOT NULL,           -- "Level I (Normal)", dll
  period_start  text,                    -- "00:00"
  period_end    text,                    -- "06:00"
  timezone      text DEFAULT 'WIB',
  summary       text,                    -- teks laporan singkat dari MAGMA
  detail_url    text,                    -- URL laporan detail di MAGMA
  author        text,                    -- nama petugas pembuat laporan
  UNIQUE (volcano_key, report_date, period_start)
);

-- Index untuk query cepat by volcano + date
CREATE INDEX IF NOT EXISTS idx_volcanic_reports_volcano_date
  ON volcanic_daily_reports (volcano_key, report_date DESC);

CREATE INDEX IF NOT EXISTS idx_volcanic_reports_fetched
  ON volcanic_daily_reports (fetched_at DESC);

-- RLS: baca public, tulis hanya via service_role (Edge Function)
ALTER TABLE volcanic_daily_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read on volcanic_daily_reports"
  ON volcanic_daily_reports
  FOR SELECT USING (true);

CREATE POLICY "Allow service role insert on volcanic_daily_reports"
  ON volcanic_daily_reports
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow service role update on volcanic_daily_reports"
  ON volcanic_daily_reports
  FOR UPDATE USING (true);

-- View: laporan terbaru per gunung (satu baris per gunung)
CREATE OR REPLACE VIEW latest_volcanic_reports AS
SELECT DISTINCT ON (volcano_key)
  id, report_date, volcano_name, volcano_key,
  level_code, level_name,
  period_start, period_end, timezone,
  summary, detail_url, author, fetched_at
FROM volcanic_daily_reports
ORDER BY volcano_key, report_date DESC, period_start DESC;
