-- ============================================================
-- Migration 017: Password Reset - Recovery Email & OTP Challenges
--
-- Menambahkan:
--   1. Kolom recovery_email + status verifikasi di tabel profiles
--   2. Tabel otp_challenges untuk menyimpan OTP server-side
--   3. Tabel reset_tickets untuk otorisasi reset sekali pakai
--   4. RLS yang ketat: hanya service_role yang bisa baca
-- ============================================================

-- ── 1. Kolom email pemulihan pada tabel profiles ────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS recovery_email       TEXT,
  ADD COLUMN IF NOT EXISTS recovery_email_verified BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS recovery_email_verified_at TIMESTAMPTZ;

-- Index untuk lookup by recovery_email (dipakai Edge Function saja, bukan client)
CREATE INDEX IF NOT EXISTS idx_profiles_recovery_email
  ON public.profiles (recovery_email)
  WHERE recovery_email IS NOT NULL;

-- ── 2. Tabel OTP Challenges ──────────────────────────────────
-- Menyimpan challenge OTP yang dikirim ke email pemulihan.
-- Hanya accessible oleh service_role (Edge Function).
-- OTP disimpan sebagai sha256 hash — tidak pernah plain text.
CREATE TABLE IF NOT EXISTS public.otp_challenges (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  purpose       TEXT NOT NULL CHECK (purpose IN ('registration', 'reset', 'change_email')),
  otp_hash      TEXT NOT NULL,         -- sha256(otp) — bukan plain text
  target_email  TEXT NOT NULL,         -- email tujuan pengiriman
  attempts      INT DEFAULT 0,
  max_attempts  INT DEFAULT 5,
  expires_at    TIMESTAMPTZ NOT NULL,
  consumed_at   TIMESTAMPTZ,           -- NULL = belum dipakai
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk lookup aktif berdasarkan user + purpose
CREATE INDEX IF NOT EXISTS idx_otp_challenges_user_purpose
  ON public.otp_challenges (user_id, purpose, created_at DESC)
  WHERE consumed_at IS NULL;

-- Index untuk cleanup challenges kedaluwarsa
CREATE INDEX IF NOT EXISTS idx_otp_challenges_expires
  ON public.otp_challenges (expires_at);

-- ── 3. Tabel Reset Tickets ───────────────────────────────────
-- Token sekali pakai yang diterbitkan setelah OTP terverifikasi.
-- Digunakan untuk mengotorisasi perubahan kata sandi.
-- Hanya accessible oleh service_role.
CREATE TABLE IF NOT EXISTS public.reset_tickets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_id UUID REFERENCES public.otp_challenges(id) ON DELETE SET NULL,
  ticket_hash TEXT NOT NULL,           -- sha256(ticket) — bukan plain text
  expires_at  TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,             -- NULL = belum dipakai
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk lookup ticket aktif
CREATE INDEX IF NOT EXISTS idx_reset_tickets_user
  ON public.reset_tickets (user_id, created_at DESC)
  WHERE consumed_at IS NULL;

-- ── 4. Row Level Security ────────────────────────────────────
-- otp_challenges: hanya service_role yang bisa akses (Edge Function)
ALTER TABLE public.otp_challenges ENABLE ROW LEVEL SECURITY;
-- Tolak semua akses dari role anon dan authenticated
-- Edge Function menggunakan service_role key, bukan client key
CREATE POLICY "No client access to otp_challenges"
  ON public.otp_challenges FOR ALL
  USING (FALSE);

-- reset_tickets: hanya service_role
ALTER TABLE public.reset_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "No client access to reset_tickets"
  ON public.reset_tickets FOR ALL
  USING (FALSE);

-- Profiles: tambahkan policy untuk user bisa baca recovery_email milik sendiri
-- (Policy SELECT yang sudah ada di migration 001 sudah cukup,
--  kolom baru ikut ter-expose ke user pemilik akun)

-- ── 5. Fungsi Cleanup: hapus challenge & ticket kedaluwarsa ─
-- Dijalankan secara periodik via pg_cron (lihat migration cron)
CREATE OR REPLACE FUNCTION public.cleanup_expired_otp()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Hapus OTP challenges yang sudah expire lebih dari 1 jam
  DELETE FROM public.otp_challenges
  WHERE expires_at < NOW() - INTERVAL '1 hour';

  -- Hapus reset tickets yang sudah expire lebih dari 1 jam
  DELETE FROM public.reset_tickets
  WHERE expires_at < NOW() - INTERVAL '1 hour';
END;
$$;

-- ── 6. Komentar dokumentasi ──────────────────────────────────
COMMENT ON COLUMN public.profiles.recovery_email IS
  'Email aktif untuk pemulihan kata sandi. Bukan metode login.';
COMMENT ON COLUMN public.profiles.recovery_email_verified IS
  'TRUE jika email pemulihan sudah diverifikasi via OTP.';
COMMENT ON TABLE public.otp_challenges IS
  'Challenge OTP sementara. Hanya diakses Edge Function via service_role.';
COMMENT ON TABLE public.reset_tickets IS
  'Tiket reset sekali pakai setelah OTP terverifikasi. Hanya diakses Edge Function.';
