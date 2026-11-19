-- ==============================================================================
-- Migration 023: Buka Akses Back-Office (Read, Realtime & Update Status) pada hiking_sos_alerts
-- Masalah:
--   Back-Office Admin (Next.js) login menggunakan tabel kustom `public.admins`
--   tanpa sesi Supabase Auth JWT, sehingga koneksi Supabase client di Back-Office
--   berjalan sebagai role `anon` (`auth.uid()` = NULL).
--   Akibatnya, RLS pada `public.hiking_sos_alerts` yang hanya mengizinkan
--   `auth.uid() = user_id` memblokir Back-Office saat mengambil daftar SOS ([] kosong),
--   memblokir event Supabase Realtime, dan menolak perubahan status penanganan.
-- ==============================================================================

-- 1. Pastikan hak akses tabel diberikan ke role anon dan authenticated
GRANT SELECT, INSERT, UPDATE ON public.hiking_sos_alerts TO anon, authenticated;

-- 2. Kebijakan SELECT: Izinkan Back-Office (anon) & pengguna terautentikasi membaca alert SOS
DROP POLICY IF EXISTS "Backoffice and users can view hiking SOS alerts" ON public.hiking_sos_alerts;
CREATE POLICY "Backoffice and users can view hiking SOS alerts"
  ON public.hiking_sos_alerts FOR SELECT
  TO anon, authenticated
  USING (true);

-- 3. Kebijakan UPDATE: Izinkan Back-Office memperbarui status penanganan (acknowledged / resolved / cancelled)
DROP POLICY IF EXISTS "Backoffice can update hiking SOS alerts status" ON public.hiking_sos_alerts;
CREATE POLICY "Backoffice can update hiking SOS alerts status"
  ON public.hiking_sos_alerts FOR UPDATE
  TO anon, authenticated
  USING (true)
  WITH CHECK (
    status IN ('open', 'acknowledged', 'resolved', 'cancelled')
  );

-- 4. Pertahankan kebijakan INSERT khusus untuk pendaki pemilik akun di aplikasi Mobile
DROP POLICY IF EXISTS "Users can create own hiking SOS alerts" ON public.hiking_sos_alerts;
CREATE POLICY "Users can create own hiking SOS alerts"
  ON public.hiking_sos_alerts FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND (
      session_id IS NULL
      OR EXISTS (
        SELECT 1 FROM public.hiking_sessions s
        WHERE s.id = session_id AND s.user_id = auth.uid()
      )
    )
  );

-- 5. Pastikan REPLICA IDENTITY FULL & publikasi Supabase Realtime aktif
ALTER TABLE public.hiking_sos_alerts REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'hiking_sos_alerts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.hiking_sos_alerts;
  END IF;
END $$;

-- 6. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
