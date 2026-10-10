-- The mobile app reads evacuation points directly from this table.
-- Keep this migration safe for environments where the table has not been
-- created yet; it becomes effective once public.evakuasi exists.
DO $$
BEGIN
  IF to_regclass('public.evakuasi') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.evakuasi ENABLE ROW LEVEL SECURITY';
    EXECUTE 'GRANT SELECT ON TABLE public.evakuasi TO anon, authenticated';

    IF NOT EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'evakuasi'
        AND policyname = 'Public can read evacuation points'
    ) THEN
      EXECUTE 'CREATE POLICY "Public can read evacuation points" ON public.evakuasi FOR SELECT TO anon, authenticated USING (true)';
    END IF;
  END IF;
END;
$$;
