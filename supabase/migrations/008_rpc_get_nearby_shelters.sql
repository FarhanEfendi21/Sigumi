-- ============================================================
-- Migration 008: RPC untuk mendapatkan shelter terdekat
-- Menggunakan PostGIS untuk menghitung jarak akurat
-- ============================================================

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
AS $$
DECLARE
  v_user_point GEOGRAPHY;
  v_result JSONB;
BEGIN
  -- Buat point dari koordinat user
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
