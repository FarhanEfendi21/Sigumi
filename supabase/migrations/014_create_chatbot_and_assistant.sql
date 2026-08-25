-- ============================================================
-- Migration 014: Tabel Chatbot dan Virtual Assistant
-- ============================================================

-- 1. Tabel Sesi Chat
CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT DEFAULT 'Percakapan Baru',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabel Pesan Chat
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'bot', 'system')),
  content TEXT NOT NULL,
  language VARCHAR(5) DEFAULT 'id',
  is_voice BOOLEAN DEFAULT FALSE,
  response_source TEXT CHECK (response_source IN ('cloud', 'local_rule_based', 'local_fallback')),
  confidence DOUBLE PRECISION,
  intent_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabel Log Perintah Suara (Virtual Assistant)
CREATE TABLE IF NOT EXISTS public.voice_command_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  command_text TEXT NOT NULL,
  detected_intent TEXT,
  is_successful BOOLEAN DEFAULT TRUE,
  confidence_score DOUBLE PRECISION,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexing untuk optimasi query
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON public.chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id ON public.chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_voice_command_logs_user_id ON public.voice_command_logs(user_id);

-- Trigger auto-update updated_at untuk chat_sessions
CREATE TRIGGER on_chat_sessions_updated
  BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Row Level Security (RLS)
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_command_logs ENABLE ROW LEVEL SECURITY;

-- Policy untuk Sesi Chat
CREATE POLICY "Users can manage their own chat sessions"
  ON public.chat_sessions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy untuk Pesan Chat
CREATE POLICY "Users can manage messages in their own sessions"
  ON public.chat_messages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.chat_sessions
      WHERE chat_sessions.id = chat_messages.session_id
      AND chat_sessions.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.chat_sessions
      WHERE chat_sessions.id = chat_messages.session_id
      AND chat_sessions.user_id = auth.uid()
    )
  );

-- Policy untuk Voice Command Logs
CREATE POLICY "Users can view and insert their own voice command logs"
  ON public.voice_command_logs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
