-- ==============================================================================
-- Migration 022: Perbaikan Skema VPS untuk Lokasi PostGIS, Tracking & SOS
-- 1. Tambah search_path ke get_nearby_shelters & update_user_location
--    agar fungsi PostGIS (geography, ST_SetSRID, ST_Distance) dikenali PostgREST.
-- 2. Tambah kolom & constraint unik client_session_id dan client_point_id
--    untuk mendukung upload batch & idempotensi retry dari aplikasi mobile.
-- 3. Pastikan tabel hiking_sos_alerts dan kebijakan RLS aktif.
-- 4. Reload PostgREST cache schema.
-- ==============================================================================

-- 1. Perbaikan RPC get_nearby_shelters (PostGIS search_path)
CREATE OR REPLACE FUNCTION public.get_nearby_shelters(
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
    LIMIT p_limit
  ) sub;

  RETURN COALESCE(v_result, jsonb_build_object('success', true, 'shelters', '[]'::jsonb, 'total', 0));
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_nearby_shelters TO authenticated, anon;

-- 2. Perbaikan RPC update_user_location (PostGIS search_path)
CREATE OR REPLACE FUNCTION public.update_user_location(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  v_user_point GEOGRAPHY;
  v_nearest RECORD;
  v_result JSON;
BEGIN
  v_user_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;
  
  UPDATE public.profiles 
  SET 
    last_location = v_user_point,
    last_location_updated_at = NOW()
  WHERE id = auth.uid();

  SELECT 
    v.id,
    v.name,
    ROUND((ST_Distance(v.location, v_user_point) / 1000.0)::numeric, 2) AS distance_km,
    v.status_level,
    CASE
      WHEN ST_Distance(v.location, v_user_point) / 1000.0 <= 5 THEN 4
      WHEN ST_Distance(v.location, v_user_point) / 1000.0 <= 10 THEN 3
      WHEN ST_Distance(v.location, v_user_point) / 1000.0 <= 15 THEN 2
      ELSE 1
    END AS zone_level,
    CASE
      WHEN ST_Distance(v.location, v_user_point) / 1000.0 <= 5 THEN 'ZONA BAHAYA UTAMA'
      WHEN ST_Distance(v.location, v_user_point) / 1000.0 <= 10 THEN 'ZONA WASPADA'
      WHEN ST_Distance(v.location, v_user_point) / 1000.0 <= 15 THEN 'ZONA PERHATIAN'
      ELSE 'ZONA RELATIF AMAN'
    END AS zone_label
  INTO v_nearest
  FROM public.volcanoes v
  ORDER BY ST_Distance(v.location, v_user_point) ASC
  LIMIT 1;

  v_result := json_build_object(
    'success', true,
    'nearest_volcano', json_build_object(
      'id', v_nearest.id,
      'name', v_nearest.name,
      'distance_km', v_nearest.distance_km,
      'status_level', v_nearest.status_level,
      'zone_level', v_nearest.zone_level,
      'zone_label', v_nearest.zone_label
    ),
    'updated_at', NOW()
  );

  RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.update_user_location TO authenticated;

-- 3. Idempotensi Tracking: client_session_id & client_point_id
ALTER TABLE public.hiking_sessions
  ADD COLUMN IF NOT EXISTS client_session_id TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'hiking_sessions_client_session_id_key'
  ) THEN
    ALTER TABLE public.hiking_sessions
      ADD CONSTRAINT hiking_sessions_client_session_id_key UNIQUE (client_session_id);
  END IF;
END $$;

ALTER TABLE public.hiking_track_points
  ADD COLUMN IF NOT EXISTS client_point_id TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'hiking_track_points_client_point_id_key'
  ) THEN
    ALTER TABLE public.hiking_track_points
      ADD CONSTRAINT hiking_track_points_client_point_id_key UNIQUE (client_point_id);
  END IF;
END $$;

-- 4. Tabel SOS Alert
CREATE TABLE IF NOT EXISTS public.hiking_sos_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_alert_id TEXT UNIQUE,
  session_id UUID REFERENCES public.hiking_sessions(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  accuracy_meters DOUBLE PRECISION,
  location_recorded_at TIMESTAMPTZ,
  message TEXT NOT NULL DEFAULT 'Pengguna meminta bantuan melalui SOS.',
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'acknowledged', 'resolved', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ
);

ALTER TABLE public.hiking_sos_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create own hiking SOS alerts" ON public.hiking_sos_alerts;
CREATE POLICY "Users can create own hiking SOS alerts"
  ON public.hiking_sos_alerts FOR INSERT
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

DROP POLICY IF EXISTS "Users can view own hiking SOS alerts" ON public.hiking_sos_alerts;
CREATE POLICY "Users can view own hiking SOS alerts"
  ON public.hiking_sos_alerts FOR SELECT
  USING (auth.uid() = user_id);

-- 5. Reload Schema Cache PostgREST
NOTIFY pgrst, 'reload schema';

