-- Fix registration grant lookup for Supabase Auth admin.createUser.
-- Auth inserts raw_user_meta_data before firing the auth.users INSERT trigger;
-- app_metadata is applied after the insert, so raw_app_meta_data is not
-- available to handle_new_user() at trigger time.

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
    signup_grant_id :=
      (NEW.raw_user_meta_data->>'sigumi_registration_grant_id')::UUID;
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

COMMENT ON FUNCTION public.handle_new_user() IS
  'Creates SIGUMI profiles only when a valid one-time recovery-email registration grant is present in raw_user_meta_data.';
