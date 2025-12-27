-- LockItIn Database Schema
-- Complete schema for users and events tables
--
-- HOW TO APPLY THIS SCHEMA:
-- 1. Go to https://app.supabase.com/
-- 2. Select your project
-- 3. Go to SQL Editor
-- 4. Copy and paste this entire file
-- 5. Click "Run" to execute
--
-- IMPORTANT: Run this BEFORE applying RLS policies (rls_policies.sql)
--
-- Last updated: December 26, 2024

-- ============================================================================
-- USERS TABLE
-- ============================================================================

-- Create users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Auto-create user profile on signup
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create profile when user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION create_user_profile();

-- ============================================================================
-- EVENTS TABLE
-- ============================================================================

-- Create custom enum types
DO $$ BEGIN
  CREATE TYPE event_visibility AS ENUM ('private', 'sharedWithName', 'busyOnly');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE event_category AS ENUM ('work', 'friend', 'holiday', 'other');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  visibility event_visibility NOT NULL DEFAULT 'private',
  category event_category DEFAULT 'other',
  native_calendar_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE,

  -- Constraints
  CONSTRAINT valid_time_range CHECK (end_time > start_time),
  CONSTRAINT valid_title CHECK (length(trim(title)) > 0)
);

-- Add updated_at trigger for events
CREATE TRIGGER update_events_updated_at
BEFORE UPDATE ON events
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

-- Index for user's events (most common query)
CREATE INDEX IF NOT EXISTS idx_events_user_id ON events(user_id);

-- Index for date range queries
CREATE INDEX IF NOT EXISTS idx_events_start_time ON events(start_time);
CREATE INDEX IF NOT EXISTS idx_events_user_date ON events(user_id, start_time);

-- Index for native calendar ID (for bidirectional sync)
CREATE INDEX IF NOT EXISTS idx_events_native_calendar_id ON events(native_calendar_id)
WHERE native_calendar_id IS NOT NULL;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Run these queries to verify the schema was created correctly:

-- Check users table exists
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'users';

-- Check events table exists
-- SELECT table_name, column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'events';

-- Check triggers exist
-- SELECT trigger_name, event_object_table, action_statement
-- FROM information_schema.triggers
-- WHERE event_object_table IN ('users', 'events');

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
--
-- After running this schema:
-- 1. Apply RLS policies: Run supabase/rls_policies.sql
-- 2. Test user signup: Create a test account in your app
-- 3. Verify profile creation: Check that a row appears in users table
-- 4. Test event creation: Create an event and verify it appears in events table
--
-- ============================================================================
