-- ============================================================
-- Migration 004: RPC — get_user_risk_zone
-- Menghitung zona risiko user berdasarkan lokasi GPS
-- Semua kalkulasi spasial dilakukan di level PostgreSQL/PostGIS
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_user_risk_zone(
  p_user_lat DOUBLE PRECISION,
  p_user_lng DOUBLE PRECISION,
  p_volcano_id UUID DEFAULT NULL
)
RETURNS TABLE (
  volcano_id UUID,
  volcano_name TEXT,
  distance_km DOUBLE PRECISION,
  zone_level INTEGER,
  zone_label TEXT,
  status_level INTEGER,
  status_description TEXT
) AS $$
DECLARE
  v_user_point GEOGRAPHY;
BEGIN
  -- Buat point geography dari koordinat user
  v_user_point := ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography;

  RETURN QUERY
  SELECT
    v.id AS volcano_id,
    v.name AS volcano_name,
    -- Hitung jarak dalam kilometer menggunakan PostGIS (geography = meter)
    ROUND((ST_Distance(v.location, v_user_point) / 1000.0)::numeric, 2)::double precision AS distance_km,
    -- Tentukan zona berdasarkan jarak
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
    END AS zone_label,
    v.status_level,
    v.status_description
  FROM public.volcanoes v
  WHERE (p_volcano_id IS NULL OR v.id = p_volcano_id)
  ORDER BY ST_Distance(v.location, v_user_point) ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant akses ke authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_risk_zone TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_risk_zone TO anon;
