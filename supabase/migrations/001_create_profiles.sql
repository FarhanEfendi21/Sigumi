-- ============================================================
-- Migration 001: Tabel profiles
-- Ekstensi dari auth.users untuk data profil pengguna SIGUMI
-- ============================================================

-- Pastikan PostGIS sudah aktif
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA extensions;

-- Tabel profil pengguna
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  date_of_birth DATE,  -- Untuk personalisasi AI
  language TEXT DEFAULT 'id' CHECK (language IN ('id', 'en')),
  region TEXT,
  audio_guidance BOOLEAN DEFAULT FALSE,
  font_size DOUBLE PRECISION DEFAULT 1.0,
  high_contrast BOOLEAN DEFAULT FALSE,
  -- Lokasi terakhir user sebagai PostGIS geography point
  last_location GEOGRAPHY(POINT, 4326),
  last_location_updated_at TIMESTAMPTZ,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index untuk query spasial pada lokasi user
CREATE INDEX IF NOT EXISTS idx_profiles_last_location 
  ON public.profiles USING GIST (last_location);

-- Trigger: Auto-create profile saat user baru sign up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, date_of_birth)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone', ''),
    CASE 
      WHEN NEW.raw_user_meta_data->>'date_of_birth' IS NOT NULL 
      THEN (NEW.raw_user_meta_data->>'date_of_birth')::DATE
      ELSE NULL
    END
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger jika ada, lalu buat baru
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger: Auto-update updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- Row Level Security (RLS)
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- User hanya bisa SELECT profil sendiri
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

-- User hanya bisa UPDATE profil sendiri
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- INSERT otomatis via trigger, tapi izinkan juga manual insert untuk profil sendiri
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
