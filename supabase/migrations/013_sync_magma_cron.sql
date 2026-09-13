-- ============================================================
-- Migration 013: Cron Job Sinkronisasi Otomatis MAGMA Indonesia
-- Menjalankan Edge Function 'sync-magma' secara berkala (setiap 10 menit)
-- Menggunakan ekstensi pg_cron & pg_net bawaan Supabase
-- ============================================================

-- 1. Aktifkan ekstensi yang dibutuhkan
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Fungsi untuk memanggil Supabase Edge Function 'sync-magma'
-- Ganti 'YOUR_SERVICE_ROLE_KEY' dengan service_role key dari:
-- Supabase Dashboard -> Settings -> API -> Project API keys -> service_role
CREATE OR REPLACE FUNCTION public.invoke_sync_magma()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  project_url text := 'https://rtwanteecrvydxyrgpii.supabase.co';
  -- Default header anon/service_role
  -- Di Supabase, Edge Function dapat dipanggil dengan anon key jika verify_jwt = false,
  -- atau menggunakan service_role key jika verify_jwt diaktifkan.
  auth_header text := current_setting('app.settings.service_role_key', true);
BEGIN
  IF auth_header IS NULL OR auth_header = '' THEN
    auth_header := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0d2FudGVlY3J2eWR4eXJncGlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzU2NTQsImV4cCI6MjA5MDgxMTY1NH0.ofz33s1PLvEGu_rgnu1CTXt_IUKOi0Ppni_8rvCxKrU';
  END IF;

  PERFORM net.http_post(
    url := project_url || '/functions/v1/sync-magma',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || auth_header
    ),
    body := '{}'::jsonb
  );
END;
$$;

-- Berikan izin akses eksekusi fungsi
GRANT EXECUTE ON FUNCTION public.invoke_sync_magma() TO postgres, authenticated, service_role;

-- 3. Jadwalkan cron job (setiap 10 menit)
-- Hapus job lama jika sudah pernah dibuat
DO $$
BEGIN
  PERFORM cron.unschedule('sync-magma-every-10-min');
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

SELECT cron.schedule(
  'sync-magma-every-10-min',
  '*/10 * * * *',
  'SELECT public.invoke_sync_magma();'
);

-- ============================================================
-- CATATAN & QUERY PENGECEKAN CRON:
--
-- 1. Cek daftar cron job yang aktif:
--    SELECT * FROM cron.job;
--
-- 2. Cek riwayat log eksekusi cron:
--    SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;
--
-- 3. Tes jalankan secara manual di SQL Editor:
--    SELECT public.invoke_sync_magma();
-- ============================================================
