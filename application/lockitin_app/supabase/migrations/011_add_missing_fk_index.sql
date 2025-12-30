-- ============================================================================
-- Migration 011: Add Missing Foreign Key Index
-- ============================================================================
-- Fixes performance warning: "Unindexed foreign key"
-- Issue: group_invites.invited_by has no covering index
--
-- Foreign keys without indexes can cause slow DELETE operations on the parent
-- table (users) because PostgreSQL must scan for referencing rows.
--
-- Created: December 30, 2025
-- Issue: Supabase Database Advisor - Performance
-- ============================================================================

-- Add index for invited_by foreign key
CREATE INDEX IF NOT EXISTS idx_group_invites_invited_by
ON group_invites(invited_by);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify the index was created:
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'group_invites'
-- ORDER BY indexname;
