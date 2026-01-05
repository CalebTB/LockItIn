-- ============================================================================
-- Migration 014: Add Composite Indexes for group_members RLS Optimization
-- ============================================================================
-- Fixes critical performance issue: RLS policies on events and shadow_calendar
-- perform self-joins on group_members without proper indexes.
--
-- Root cause: The RLS policy on events table has this subquery:
--   EXISTS (
--     SELECT 1 FROM group_members gm1
--     INNER JOIN group_members gm2
--       ON gm1.group_id = gm2.group_id
--     WHERE gm1.user_id = auth.uid()
--       AND gm2.user_id = events.user_id
--   )
--
-- Without composite indexes, this self-join scans the entire group_members
-- table for EVERY event row, causing exponential slowdown.
--
-- Impact: 10-50x faster group calendar queries for groups with 5+ members
--
-- Created: January 4, 2026
-- Issue: Database Performance Audit - Group Calendar Lag
-- ============================================================================

-- ============================================================================
-- COMPOSITE INDEXES
-- ============================================================================

-- Index 1: Optimize "which groups is user X in?"
-- Used by: RLS policies when filtering by auth.uid()
-- Example query: WHERE gm1.user_id = auth.uid()
CREATE INDEX IF NOT EXISTS idx_group_members_user_group
ON group_members(user_id, group_id);

-- Index 2: Optimize "who is in group Y?"
-- Used by: RLS policies when joining on group_id
-- Example query: ON gm1.group_id = gm2.group_id WHERE gm2.user_id = events.user_id
CREATE INDEX IF NOT EXISTS idx_group_members_group_user
ON group_members(group_id, user_id);

-- Index 3: Covering index (includes role column)
-- Avoids table lookups when role is needed
-- Only available in PostgreSQL 11+ (Supabase uses PostgreSQL 15+)
CREATE INDEX IF NOT EXISTS idx_group_members_rls_covering
ON group_members(user_id, group_id)
INCLUDE (role);

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify indexes were created:
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'group_members'
-- ORDER BY indexname;
--
-- Expected output should include:
-- - idx_group_members_user_group
-- - idx_group_members_group_user
-- - idx_group_members_rls_covering
--
-- ============================================================================
-- PERFORMANCE TESTING
-- ============================================================================
-- Test RLS policy performance before/after:
--
-- EXPLAIN ANALYZE
-- SELECT DISTINCT gm2.user_id
-- FROM group_members gm1
-- INNER JOIN group_members gm2 ON gm1.group_id = gm2.group_id
-- WHERE gm1.user_id = auth.uid()
--   AND gm1.user_id != gm2.user_id;
--
-- Before: Should show "Seq Scan" on group_members (SLOW)
-- After: Should show "Index Scan" using idx_group_members_user_group (FAST)
--
-- ============================================================================
-- INDEX USAGE MONITORING
-- ============================================================================
-- Monitor index usage with this query:
--
-- SELECT
--   schemaname,
--   tablename,
--   indexname,
--   idx_scan as index_scans,
--   idx_tup_read as tuples_read,
--   idx_tup_fetch as tuples_fetched
-- FROM pg_stat_user_indexes
-- WHERE tablename = 'group_members'
-- ORDER BY idx_scan DESC;
--
-- After optimization:
-- - idx_group_members_user_group should have high scan count
-- - idx_group_members_group_user should have high scan count
-- - Base table sequential scans should drop to near zero
--
-- ============================================================================
