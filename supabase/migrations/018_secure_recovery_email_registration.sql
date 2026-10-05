-- Bind registration email verification to the phone number and require a
-- server-issued grant before a new SIGUMI Auth user can be created.

ALTER TABLE public.otp_challenges
  ADD COLUMN IF NOT EXISTS target_phone TEXT,
  ADD COLUMN IF NOT EXISTS request_ip TEXT;

CREATE INDEX IF NOT EXISTS idx_otp_registration_pair
  ON public.otp_challenges (target_email, target_phone, created_at DESC)
  WHERE purpose = 'registration' AND consumed_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_otp_request_ip_purpose_created
  ON public.otp_challenges (request_ip, purpose, created_at DESC)
  WHERE request_ip IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.registration_email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash TEXT NOT NULL UNIQUE,
  target_phone TEXT NOT NULL,
  target_email TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  auth_user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.registration_email_verifications ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.registration_email_verifications FROM anon, authenticated;
GRANT ALL ON public.registration_email_verifications TO service_role;

-- A table-level UPDATE grant overrides column-level revokes. Replace it with
-- explicit safe-column grants so clients cannot forge verified recovery data.
REVOKE INSERT, UPDATE ON public.profiles FROM anon, authenticated;
REVOKE INSERT (recovery_email, recovery_email_verified, recovery_email_verified_at),
  UPDATE (recovery_email, recovery_email_verified, recovery_email_verified_at)
  ON public.profiles FROM anon, authenticated;
GRANT INSERT (
  id, full_name, phone, date_of_birth, language, region, audio_guidance,
  font_size, high_contrast, last_location, last_location_updated_at, fcm_token
) ON public.profiles TO authenticated;
GRANT UPDATE (
  full_name, phone, date_of_birth, language, region, audio_guidance,
  font_size, high_contrast, last_location, last_location_updated_at, fcm_token
) ON public.profiles TO authenticated;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  signup_grant public.registration_email_verifications%ROWTYPE;
  signup_grant_id UUID;
  user_phone TEXT;
BEGIN
  user_phone := NEW.raw_user_meta_data->>'phone';

  BEGIN
    signup_grant_id := (NEW.raw_app_meta_data->>'sigumi_registration_grant_id')::UUID;
  EXCEPTION WHEN invalid_text_representation THEN
    RAISE EXCEPTION 'A valid recovery email verification is required';
  END;

  IF signup_grant_id IS NULL OR user_phone IS NULL THEN
    RAISE EXCEPTION 'A verified SIGUMI registration is required';
  END IF;

  SELECT * INTO signup_grant
  FROM public.registration_email_verifications
  WHERE id = signup_grant_id
    AND target_phone = user_phone
    AND expires_at > NOW()
    AND consumed_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Registration verification is invalid, expired, or already used';
  END IF;

  UPDATE public.registration_email_verifications
  SET consumed_at = NOW(), auth_user_id = NEW.id
  WHERE id = signup_grant.id AND consumed_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Registration verification has already been used';
  END IF;

  INSERT INTO public.profiles (
    id, full_name, phone, date_of_birth,
    recovery_email, recovery_email_verified, recovery_email_verified_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    user_phone,
    CASE
      WHEN NEW.raw_user_meta_data->>'date_of_birth' IS NOT NULL
      THEN (NEW.raw_user_meta_data->>'date_of_birth')::DATE
      ELSE NULL
    END,
    signup_grant.target_email,
    TRUE,
    NOW()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.cleanup_expired_otp()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  DELETE FROM public.otp_challenges
  WHERE expires_at < NOW() - INTERVAL '1 hour';

  DELETE FROM public.reset_tickets
  WHERE expires_at < NOW() - INTERVAL '1 hour';

  DELETE FROM public.registration_email_verifications
  WHERE expires_at < NOW() - INTERVAL '1 hour';
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_expired_otp() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_otp() TO postgres, service_role;

DO $$
BEGIN
  PERFORM cron.unschedule('cleanup-expired-otp-hourly');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule(
  'cleanup-expired-otp-hourly',
  '0 * * * *',
  'SELECT public.cleanup_expired_otp();'
);

COMMENT ON TABLE public.registration_email_verifications IS
  'One-time server-issued proof binding a verified recovery email to a new phone account.';
