-- ============================================================
-- Migration 011: Tabel Nomor Telepon Darurat
-- Data bersifat dinamis, dapat dikelola admin
-- ============================================================

CREATE TABLE IF NOT EXISTS public.emergency_contacts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  phone        TEXT NOT NULL,
  description  TEXT,
  category     TEXT NOT NULL DEFAULT 'nasional'
                 CHECK (category IN ('posko', 'faskes', 'nasional')),
  region       TEXT NOT NULL DEFAULT 'Nasional'
                 CHECK (region IN ('Nasional', 'Yogyakarta', 'Bali', 'Lombok')),
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order   INTEGER NOT NULL DEFAULT 99,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index untuk query berdasarkan region
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_region
  ON public.emergency_contacts (region, is_active, sort_order);

-- RLS: data publik, semua user bisa baca
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "emergency_contacts_public_read"
  ON public.emergency_contacts
  FOR SELECT
  USING (is_active = TRUE);

-- Trigger auto-update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_emergency_contacts_updated_at
  BEFORE UPDATE ON public.emergency_contacts
  FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();
