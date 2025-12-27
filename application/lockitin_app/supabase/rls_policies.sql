-- Row Level Security (RLS) Policies for LockItIn
-- These policies ensure users can only access their own data
--
-- HOW TO APPLY THESE POLICIES:
-- 1. Go to https://app.supabase.com/
-- 2. Select your project
-- 3. Go to SQL Editor
-- 4. Copy and paste this entire file
-- 5. Click "Run" to execute
--
-- Last updated: December 26, 2024

-- ============================================================================
-- USERS TABLE - Row Level Security
-- ============================================================================

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
ON users
FOR SELECT
USING (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
ON users
FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy: Users can insert their own profile (handled by auth trigger, but allow for manual creation)
CREATE POLICY "Users can insert own profile"
ON users
FOR INSERT
WITH CHECK (auth.uid() = id);

-- ============================================================================
-- EVENTS TABLE - Row Level Security
-- ============================================================================

-- Enable RLS on events table
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own events
CREATE POLICY "Users can view own events"
ON events
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can create their own events
CREATE POLICY "Users can create own events"
ON events
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own events
CREATE POLICY "Users can update own events"
ON events
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own events
CREATE POLICY "Users can delete own events"
ON events
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
--
-- 1. These policies ensure complete data isolation between users
-- 2. Each user can ONLY access their own events and profile
-- 3. Supabase automatically handles auth.uid() based on JWT tokens
-- 4. No user can see another user's events without explicit group sharing (to be implemented)
--
-- FUTURE POLICIES (not yet implemented):
-- - Group sharing policies (when groups table is created)
-- - Friend visibility policies (for Shadow Calendar feature)
-- - Proposal voting policies (for event proposals)
--
-- ============================================================================
