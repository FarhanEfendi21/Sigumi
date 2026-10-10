-- PostGIS is installed in the `extensions` schema. The existing function
-- runs as SECURITY DEFINER without that schema in its search_path, so its
-- geography declaration/casts fail when called through PostgREST.
DO $$
BEGIN
  IF to_regprocedure(
    'public.get_nearby_shelters(double precision,double precision,uuid,text,integer)'
  ) IS NOT NULL THEN
    EXECUTE 'ALTER FUNCTION public.get_nearby_shelters(double precision, double precision, uuid, text, integer) SET search_path = public, extensions, pg_temp';
  END IF;
END;
$$;
