-- Verify that events table is in the realtime publication
-- Run this in your Supabase SQL Editor to confirm realtime is enabled

-- 1. Check if events table is in supabase_realtime publication
SELECT
    schemaname,
    tablename,
    'events table IS in realtime publication ✅' as status
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND tablename = 'events'
UNION ALL
SELECT
    'public' as schemaname,
    'events' as tablename,
    'events table NOT in realtime publication ❌ - Run migration 024!' as status
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'events'
);

-- 2. Show all tables currently in realtime publication
SELECT
    schemaname,
    tablename,
    '📡 Currently in realtime publication' as note
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
