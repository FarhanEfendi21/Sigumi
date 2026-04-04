-- ============================================================
-- Migration 005: RPC — update_user_location
-- Update lokasi real-time user ke tabel profiles
-- Dipanggil dari Flutter setiap kali GPS position berubah
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_user_location(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION
)
RETURNS JSON AS $$
DECLARE
  v_user_point GEOGRAPHY;
  v_nearest RECORD;
  v_result JSON;
BEGIN
  -- Buat point geography dari koordinat
  v_user_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography;
  
  -- Update lokasi di profile user yang sedang login
  UPDATE public.profiles 
  SET 
    last_location = v_user_point,
    last_location_updated_at = NOW()
  WHERE id = auth.uid();

  -- Hitung gunung berapi terdekat & zona risiko sekaligus
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

  -- Return JSON dengan info lokasi + risiko terdekat
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Hanya authenticated users yang bisa update lokasi
GRANT EXECUTE ON FUNCTION public.update_user_location TO authenticated;
