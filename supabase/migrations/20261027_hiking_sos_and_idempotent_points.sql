-- Idempotent point uploads allow the mobile client to retry after connectivity returns.
ALTER TABLE public.hiking_sessions
  ADD COLUMN IF NOT EXISTS client_session_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_hiking_sessions_client_session_id
  ON public.hiking_sessions (client_session_id);

ALTER TABLE public.hiking_track_points
  ADD COLUMN IF NOT EXISTS client_point_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_hiking_track_points_client_point_id
  ON public.hiking_track_points (client_point_id);

-- SOS records are written by the authenticated hiker and consumed by the SAR web dashboard.
CREATE TABLE IF NOT EXISTS public.hiking_sos_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_alert_id TEXT UNIQUE,
  session_id UUID REFERENCES public.hiking_sessions(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  accuracy_meters DOUBLE PRECISION,
  location_recorded_at TIMESTAMPTZ,
  message TEXT NOT NULL DEFAULT 'Pengguna meminta bantuan melalui SOS.',
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'acknowledged', 'resolved', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_hiking_sos_alerts_open_created
  ON public.hiking_sos_alerts (created_at DESC)
  WHERE status = 'open';
CREATE INDEX IF NOT EXISTS idx_hiking_sos_alerts_user_created
  ON public.hiking_sos_alerts (user_id, created_at DESC);

ALTER TABLE public.hiking_sos_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create own hiking SOS alerts"
  ON public.hiking_sos_alerts;
CREATE POLICY "Users can create own hiking SOS alerts"
  ON public.hiking_sos_alerts FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      session_id IS NULL
      OR EXISTS (
        SELECT 1 FROM public.hiking_sessions s
        WHERE s.id = session_id AND s.user_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "Users can view own hiking SOS alerts"
  ON public.hiking_sos_alerts;
CREATE POLICY "Users can view own hiking SOS alerts"
  ON public.hiking_sos_alerts FOR SELECT
  USING (auth.uid() = user_id);

-- The SAR web dashboard can subscribe to new SOS alerts over Supabase Realtime.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'hiking_sos_alerts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.hiking_sos_alerts;
  END IF;
END $$;
