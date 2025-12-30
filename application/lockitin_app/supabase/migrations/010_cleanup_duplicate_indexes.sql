-- ============================================================================
-- Migration 010: Remove Duplicate Indexes
-- ============================================================================
-- Fixes performance warning: "Duplicate indexes exist"
-- Found duplicates:
--   1. events.events_start_time_idx = events.idx_events_start_time
--   2. events.events_user_id_idx = events.idx_events_user_id
--
-- Keeping the idx_events_* versions (consistent naming convention)
--
-- Created: December 30, 2025
-- Issue: Supabase Database Advisor - Performance
-- ============================================================================

-- Drop duplicate index for start_time (keep idx_events_start_time)
DROP INDEX IF EXISTS events_start_time_idx;

-- Drop duplicate index for user_id (keep idx_events_user_id)
DROP INDEX IF EXISTS events_user_id_idx;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify only one index per column remains:
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'events'
-- ORDER BY indexname;
