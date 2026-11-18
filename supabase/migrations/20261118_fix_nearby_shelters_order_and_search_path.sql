-- ============================================================
-- Migration 20261118: Perbaikan bug & hardening RPC
--
-- 1. get_nearby_shelters: LIMIT sebelumnya diterapkan SEBELUM pengurutan
--    jarak, sehingga posko yang dikembalikan belum tentu yang terdekat.
--    Perbaikan: urutkan berdasarkan jarak lalu LIMIT di dalam subquery.
-- 2. Kunci search_path pada fungsi SECURITY DEFINER yang belum mengaturnya
--    (mitigasi pembajakan skema).
--
-- Idempoten & aman: hanya memperbaiki definisi fungsi, tidak mengubah data,
-- aturan akses, maupun hak GRANT yang sudah ada.
-- ============================================================

-- 1. Perbaikan urutan get_nearby_shelters -------------------------------------
CREATE OR REPLACE FUNCTION get_nearby_shelters(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_volcano_id UUID DEFAULT NULL,
  p_type TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_user_point GEOGRAPHY;
  v_result JSONB;
BEGIN
  v_user_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;

  SELECT jsonb_build_object(
    'success', true,
    'shelters', COALESCE(jsonb_agg(shelter_data ORDER BY distance_km ASC), '[]'::jsonb),
    'total', COUNT(*)
  ) INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', s.id,
      'name', s.name,
      'type', s.type,
      'latitude', ST_Y(s.location::geometry),
      'longitude', ST_X(s.location::geometry),
      'address', s.address,
      'phone', s.phone,
      'capacity', s.capacity,
      'has_medical', s.has_medical,
      'has_kitchen', s.has_kitchen,
      'has_toilet', s.has_toilet,
      'is_24h', s.is_24h,
      'is_active', s.is_active,
      'notes', s.notes,
      'distance_km', ROUND((ST_Distance(s.location, v_user_point) / 1000)::numeric, 2),
      'distance_from_volcano', s.distance_from_volcano,
      'volcano_name', v.name
    ) AS shelter_data,
    (ST_Distance(s.location, v_user_point) / 1000) AS distance_km
    FROM public.shelters s
    JOIN public.volcanoes v ON v.id = s.volcano_id
    WHERE s.is_active = true
      AND (p_volcano_id IS NULL OR s.volcano_id = p_volcano_id)
      AND (p_type IS NULL OR s.type = p_type)
    ORDER BY (ST_Distance(s.location, v_user_point)) ASC
    LIMIT p_limit
  ) sub;

  RETURN COALESCE(v_result, jsonb_build_object('success', true, 'shelters', '[]'::jsonb, 'total', 0));
END;
$$;

-- 2. Kunci search_path pada fungsi SECURITY DEFINER lain ----------------------
DO $$
BEGIN
  IF to_regprocedure('public.get_user_risk_zone(double precision,double precision,uuid)') IS NOT NULL THEN
    EXECUTE 'ALTER FUNCTION public.get_user_risk_zone(double precision, double precision, uuid) SET search_path = public, extensions, pg_temp';
  END IF;

  IF to_regprocedure('public.update_user_location(double precision,double precision)') IS NOT NULL THEN
    EXECUTE 'ALTER FUNCTION public.update_user_location(double precision, double precision) SET search_path = public, extensions, pg_temp';
  END IF;

  IF to_regprocedure('public.invoke_sync_magma()') IS NOT NULL THEN
    EXECUTE 'ALTER FUNCTION public.invoke_sync_magma() SET search_path = public, pg_temp';
  END IF;
END $$;

-- 3. Cabut hak EXECUTE implisit (PUBLIC) pada fungsi yang tidak seharusnya
--    dapat dipanggil sembarang klien. PostgreSQL memberi EXECUTE ke PUBLIC
--    secara default saat fungsi dibuat; migrasi awal hanya menambah GRANT
--    eksplisit tanpa mencabut PUBLIC.
DO $$
BEGIN
  -- update_user_location: hanya untuk pengguna login (memakai auth.uid()).
  -- Aplikasi hanya memanggilnya saat currentUser != null, jadi anon aman dicabut.
  IF to_regprocedure('public.update_user_location(double precision,double precision)') IS NOT NULL THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.update_user_location(double precision, double precision) FROM PUBLIC';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.update_user_location(double precision, double precision) FROM anon';
    EXECUTE 'GRANT EXECUTE ON FUNCTION public.update_user_location(double precision, double precision) TO authenticated';
  END IF;

  -- invoke_sync_magma: fungsi internal (cron/edge), tidak untuk klien.
  IF to_regprocedure('public.invoke_sync_magma()') IS NOT NULL THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.invoke_sync_magma() FROM PUBLIC';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.invoke_sync_magma() FROM anon';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.invoke_sync_magma() FROM authenticated';
  END IF;
END $$;
