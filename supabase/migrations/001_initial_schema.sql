-- ============================================================
-- Sacheta — Phase 2: Database Schema + Row Level Security
-- ============================================================
-- Run this in the Supabase SQL Editor (https://supabase.com/dashboard)
-- or apply via `supabase db push` / migration tooling.
--
-- This script is idempotent-safe for most objects but uses
-- IF NOT EXISTS / OR REPLACE where possible.
-- ============================================================

-- ── 0. Extensions ───────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ── 1. PROFILES ─────────────────────────────────────────────────
-- 1-to-1 with auth.users. Stores display preferences only.
-- Never stores credentials, tokens, or secrets.

CREATE TABLE IF NOT EXISTS profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT,
  language_style TEXT DEFAULT 'balanced',
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);


-- ── 2. DIARY PAGES ──────────────────────────────────────────────
-- The user's private writing. mode = 'my_pages' | 'sacheta'

CREATE TABLE IF NOT EXISTS diary_pages (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title      TEXT,
  content    TEXT NOT NULL DEFAULT '',
  page_date  DATE DEFAULT CURRENT_DATE,
  mode       TEXT NOT NULL DEFAULT 'my_pages',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);


-- ── 3. CONVERSATIONS ────────────────────────────────────────────
-- Sacheta conversation threads.

CREATE TABLE IF NOT EXISTS conversations (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title      TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);


-- ── 4. MESSAGES ─────────────────────────────────────────────────
-- Individual messages within a conversation.
-- user_id is retained for direct ownership enforcement.

CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role            TEXT NOT NULL,       -- 'user' | 'sacheta'
  content         TEXT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT now()
);


-- ── 5. MEMORIES ─────────────────────────────────────────────────
-- Sacheta's persistent long-term memory per user.
-- One row per user. Stores the full memory object as JSONB.

CREATE TABLE IF NOT EXISTS memories (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  content    JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);


-- ── 6. INDEXES ──────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_diary_pages_user_id
  ON diary_pages (user_id);

CREATE INDEX IF NOT EXISTS idx_diary_pages_user_date
  ON diary_pages (user_id, page_date);

CREATE INDEX IF NOT EXISTS idx_conversations_user_id
  ON conversations (user_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id
  ON messages (conversation_id);

CREATE INDEX IF NOT EXISTS idx_messages_user_id
  ON messages (user_id);

CREATE INDEX IF NOT EXISTS idx_memories_user_id
  ON memories (user_id);


-- ── 7. UPDATED_AT TRIGGER ───────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to every table that has updated_at.
DO $$
BEGIN
  -- profiles
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_profiles_updated_at') THEN
    CREATE TRIGGER trg_profiles_updated_at
      BEFORE UPDATE ON profiles
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  -- diary_pages
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_diary_pages_updated_at') THEN
    CREATE TRIGGER trg_diary_pages_updated_at
      BEFORE UPDATE ON diary_pages
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  -- conversations
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_conversations_updated_at') THEN
    CREATE TRIGGER trg_conversations_updated_at
      BEFORE UPDATE ON conversations
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  -- memories
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_memories_updated_at') THEN
    CREATE TRIGGER trg_memories_updated_at
      BEFORE UPDATE ON memories
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END $$;


-- ── 8. AUTO-CREATE PROFILE ON SIGNUP ────────────────────────────
-- When a new row appears in auth.users, automatically create
-- a matching profiles row with sensible defaults.

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name, language_style)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', NULL),
    'balanced'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only fire if the trigger doesn't already exist.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE FUNCTION handle_new_user();
  END IF;
END $$;


-- ── 9. ROW LEVEL SECURITY ───────────────────────────────────────

ALTER TABLE profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE diary_pages   ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE memories      ENABLE ROW LEVEL SECURITY;


-- ── 10. RLS POLICIES ────────────────────────────────────────────

-- ── PROFILES ────────────────────────────────────────────────────

CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);


-- ── DIARY PAGES ─────────────────────────────────────────────────

CREATE POLICY "diary_pages_select_own"
  ON diary_pages FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "diary_pages_insert_own"
  ON diary_pages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "diary_pages_update_own"
  ON diary_pages FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "diary_pages_delete_own"
  ON diary_pages FOR DELETE
  USING (auth.uid() = user_id);


-- ── CONVERSATIONS ───────────────────────────────────────────────

CREATE POLICY "conversations_select_own"
  ON conversations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "conversations_insert_own"
  ON conversations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "conversations_update_own"
  ON conversations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "conversations_delete_own"
  ON conversations FOR DELETE
  USING (auth.uid() = user_id);


-- ── MESSAGES ────────────────────────────────────────────────────
-- Ownership is enforced both directly (user_id = auth.uid())
-- AND by verifying the parent conversation belongs to the same user.

CREATE POLICY "messages_select_own"
  ON messages FOR SELECT
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
        AND conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "messages_insert_own"
  ON messages FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = conversation_id
        AND conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "messages_update_own"
  ON messages FOR UPDATE
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
        AND conversations.user_id = auth.uid()
    )
  );

CREATE POLICY "messages_delete_own"
  ON messages FOR DELETE
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM conversations
      WHERE conversations.id = messages.conversation_id
        AND conversations.user_id = auth.uid()
    )
  );


-- ── MEMORIES ────────────────────────────────────────────────────

CREATE POLICY "memories_select_own"
  ON memories FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "memories_insert_own"
  ON memories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "memories_update_own"
  ON memories FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "memories_delete_own"
  ON memories FOR DELETE
  USING (auth.uid() = user_id);
