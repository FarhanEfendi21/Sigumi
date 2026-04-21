-- ============================================================
-- Migration: Update language support to 5 languages
-- Menambah support untuk Jawa (jv), Bali (ba), Sasak (sa)
-- ============================================================

-- Update CHECK constraint untuk language field
-- Drop constraint lama
ALTER TABLE public.profiles 
DROP CONSTRAINT IF EXISTS "profiles_language_check";

-- Tambah constraint baru dengan 5 bahasa
ALTER TABLE public.profiles
ADD CONSTRAINT "profiles_language_check" 
CHECK (language IN ('id', 'en', 'jv', 'ba', 'sa'));
