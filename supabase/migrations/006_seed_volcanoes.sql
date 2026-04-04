-- ============================================================
-- Migration 006: Seed data gunung berapi & zona bahaya
-- Data awal untuk MVP (3 gunung utama)
-- ============================================================

-- ── Insert Gunung Berapi ──
INSERT INTO public.volcanoes (id, name, location, elevation, status_level, status_description, last_eruption, recent_activities, temperature, wind_direction, wind_speed, region)
VALUES
  (
    'a1b2c3d4-e5f6-7890-abcd-111111111111',
    'Gunung Merapi',
    ST_SetSRID(ST_MakePoint(110.4457, -7.5407), 4326)::geography,
    2968,
    2,
    'Aktivitas vulkanik masih tinggi. Guguran lava pijar teramati dengan jarak luncur maksimum 1.8 km ke arah barat daya. Terjadi 45 kali gempa guguran dan 12 kali gempa vulkanik.',
    '11 Maret 2023',
    '["Guguran lava pijar teramati jarak luncur maks 1.8 km arah barat daya", "45 kali gempa guguran", "12 kali gempa vulkanik dalam", "3 kali gempa tektonik lokal", "Asap kawah putih tebal 150m"]'::jsonb,
    28,
    'Barat Daya',
    15,
    'Yogyakarta'
  ),
  (
    'a1b2c3d4-e5f6-7890-abcd-222222222222',
    'Gunung Agung',
    ST_SetSRID(ST_MakePoint(115.5071, -8.3433), 4326)::geography,
    3031,
    1,
    'Aktivitas vulkanik tergolong normal. Tidak ada aktivitas kegempaan yang signifikan dalam 24 jam terakhir.',
    '13 Juni 2019',
    '["Tidak ada aktivitas signifikan", "Cuaca cerah, angin lemah ke arah barat"]'::jsonb,
    24,
    'Barat',
    10,
    'Bali'
  ),
  (
    'a1b2c3d4-e5f6-7890-abcd-333333333333',
    'Gunung Rinjani',
    ST_SetSRID(ST_MakePoint(116.4573, -8.4111), 4326)::geography,
    3726,
    2,
    'Aktivitas vulkanik waspada akibat peningkatan gempa. Terdapat hembusan asap putih di sekitar kawah.',
    '27 September 2016',
    '["Hembusan asap putih tipis sesekali terlihat", "2 kali gempa vulkanik dalam", "10 kali gempa tektonik jauh"]'::jsonb,
    22,
    'Selatan',
    12,
    'Lombok'
  )
ON CONFLICT (id) DO NOTHING;

-- ── Insert Zona Bahaya untuk setiap gunung ──
-- Merapi
INSERT INTO public.danger_zones (volcano_id, zone_level, zone_label, radius_km, description, color_hex) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-111111111111', 4, 'ZONA BAHAYA UTAMA', 5,  'Zona terlarang. Sangat berbahaya, evakuasi wajib.', '#EF4444'),
  ('a1b2c3d4-e5f6-7890-abcd-111111111111', 3, 'ZONA WASPADA',      10, 'Zona siaga tinggi. Siapkan rencana evakuasi.',     '#F97316'),
  ('a1b2c3d4-e5f6-7890-abcd-111111111111', 2, 'ZONA PERHATIAN',    15, 'Zona waspada. Pantau informasi resmi.',             '#F59E0B'),
  ('a1b2c3d4-e5f6-7890-abcd-111111111111', 1, 'ZONA RELATIF AMAN', 20, 'Zona relatif aman. Tetap waspada.',                 '#22C55E');

-- Agung
INSERT INTO public.danger_zones (volcano_id, zone_level, zone_label, radius_km, description, color_hex) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-222222222222', 4, 'ZONA BAHAYA UTAMA', 5,  'Zona terlarang. Sangat berbahaya, evakuasi wajib.', '#EF4444'),
  ('a1b2c3d4-e5f6-7890-abcd-222222222222', 3, 'ZONA WASPADA',      10, 'Zona siaga tinggi. Siapkan rencana evakuasi.',     '#F97316'),
  ('a1b2c3d4-e5f6-7890-abcd-222222222222', 2, 'ZONA PERHATIAN',    15, 'Zona waspada. Pantau informasi resmi.',             '#F59E0B'),
  ('a1b2c3d4-e5f6-7890-abcd-222222222222', 1, 'ZONA RELATIF AMAN', 20, 'Zona relatif aman. Tetap waspada.',                 '#22C55E');

-- Rinjani
INSERT INTO public.danger_zones (volcano_id, zone_level, zone_label, radius_km, description, color_hex) VALUES
  ('a1b2c3d4-e5f6-7890-abcd-333333333333', 4, 'ZONA BAHAYA UTAMA', 5,  'Zona terlarang. Sangat berbahaya, evakuasi wajib.', '#EF4444'),
  ('a1b2c3d4-e5f6-7890-abcd-333333333333', 3, 'ZONA WASPADA',      10, 'Zona siaga tinggi. Siapkan rencana evakuasi.',     '#F97316'),
  ('a1b2c3d4-e5f6-7890-abcd-333333333333', 2, 'ZONA PERHATIAN',    15, 'Zona waspada. Pantau informasi resmi.',             '#F59E0B'),
  ('a1b2c3d4-e5f6-7890-abcd-333333333333', 1, 'ZONA RELATIF AMAN', 20, 'Zona relatif aman. Tetap waspada.',                 '#22C55E');
