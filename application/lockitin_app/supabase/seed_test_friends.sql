-- LockItIn Test Friends Seed Data
-- Creates 7 test user accounts with friendships and adds them to your group
--
-- HOW TO USE:
-- 1. Replace 'YOUR_USER_ID_HERE' with your actual Supabase user ID
--    (You can find this in Supabase Dashboard > Authentication > Users)
-- 2. Replace 'YOUR_GROUP_ID_HERE' with your group's UUID
--    (You can find this by running: SELECT id, name FROM groups;)
-- 3. Run this script in Supabase SQL Editor
--
-- Last updated: December 27, 2025

-- ============================================================================
-- CONFIGURATION - REPLACE THESE WITH YOUR IDs
-- ============================================================================

-- Find your user ID: Go to Supabase Dashboard > Authentication > Users
-- Find your group ID: Run "SELECT id, name FROM groups;" in SQL Editor
DO $$
DECLARE
  my_user_id UUID := 'YOUR_USER_ID_HERE';  -- <-- REPLACE THIS!
  my_group_id UUID := 'YOUR_GROUP_ID_HERE'; -- <-- REPLACE THIS!

  -- Test user IDs (fixed UUIDs for consistency)
  alex_id UUID := '11111111-1111-1111-1111-111111111111';
  emma_id UUID := '22222222-2222-2222-2222-222222222222';
  jordan_id UUID := '33333333-3333-3333-3333-333333333333';
  sophia_id UUID := '44444444-4444-4444-4444-444444444444';
  marcus_id UUID := '55555555-5555-5555-5555-555555555555';
  olivia_id UUID := '66666666-6666-6666-6666-666666666666';
  ethan_id UUID := '77777777-7777-7777-7777-777777777777';

BEGIN
  -- ============================================================================
  -- CREATE TEST USERS IN auth.users
  -- ============================================================================

  -- Note: We insert into auth.users first, then the trigger creates the profile
  -- For testing, we'll insert directly into both tables

  -- First, insert into auth.users (minimal required fields)
  INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, instance_id, aud, role)
  VALUES
    (alex_id, 'alex.chen@test.com', crypt('TestPassword123!', gen_salt('bf')), now(), now(), now(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (emma_id, 'emma.wilson@test.com', crypt('TestPassword123!', gen_salt('bf')), now(), now(), now(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (jordan_id, 'jordan.rivera@test.com', crypt('TestPassword123!', gen_salt('bf')), now(), now(), now(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (sophia_id, 'sophia.patel@test.com', crypt('TestPassword123!', gen_salt('bf')), now(), now(), now(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (marcus_id, 'marcus.johnson@test.com', crypt('TestPassword123!', gen_salt('bf')), now(), now(), now(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (olivia_id, 'olivia.kim@test.com', crypt('TestPassword123!', gen_salt('bf')), now(), now(), now(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (ethan_id, 'ethan.brooks@test.com', crypt('TestPassword123!', gen_salt('bf')), now(), now(), now(), '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated')
  ON CONFLICT (id) DO NOTHING;

  -- ============================================================================
  -- CREATE TEST USER PROFILES
  -- ============================================================================

  INSERT INTO users (id, email, full_name, bio, created_at)
  VALUES
    (alex_id, 'alex.chen@test.com', 'Alex Chen', 'Software engineer who loves hiking and board games', now()),
    (emma_id, 'emma.wilson@test.com', 'Emma Wilson', 'Foodie and amateur photographer', now()),
    (jordan_id, 'jordan.rivera@test.com', 'Jordan Rivera', 'Music producer and coffee enthusiast', now()),
    (sophia_id, 'sophia.patel@test.com', 'Sophia Patel', 'Yoga instructor and book lover', now()),
    (marcus_id, 'marcus.johnson@test.com', 'Marcus Johnson', 'Basketball player and movie buff', now()),
    (olivia_id, 'olivia.kim@test.com', 'Olivia Kim', 'Graphic designer and plant mom', now()),
    (ethan_id, 'ethan.brooks@test.com', 'Ethan Brooks', 'Chef and travel addict', now())
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    bio = EXCLUDED.bio;

  -- ============================================================================
  -- CREATE FRIENDSHIPS (all accepted)
  -- ============================================================================

  -- Create friendships between you and all test users
  INSERT INTO friendships (user_id, friend_id, status, created_at, accepted_at)
  VALUES
    (my_user_id, alex_id, 'accepted', now() - interval '30 days', now() - interval '29 days'),
    (my_user_id, emma_id, 'accepted', now() - interval '25 days', now() - interval '24 days'),
    (my_user_id, jordan_id, 'accepted', now() - interval '20 days', now() - interval '19 days'),
    (my_user_id, sophia_id, 'accepted', now() - interval '15 days', now() - interval '14 days'),
    (my_user_id, marcus_id, 'accepted', now() - interval '10 days', now() - interval '9 days'),
    (my_user_id, olivia_id, 'accepted', now() - interval '7 days', now() - interval '6 days'),
    (my_user_id, ethan_id, 'accepted', now() - interval '3 days', now() - interval '2 days')
  ON CONFLICT (user_id, friend_id) DO UPDATE SET
    status = 'accepted',
    accepted_at = EXCLUDED.accepted_at;

  -- ============================================================================
  -- ADD TEST USERS TO YOUR GROUP
  -- ============================================================================

  -- Add all test users as members of your group
  INSERT INTO group_members (group_id, user_id, role, joined_at)
  VALUES
    (my_group_id, alex_id, 'member', now() - interval '29 days'),
    (my_group_id, emma_id, 'member', now() - interval '24 days'),
    (my_group_id, jordan_id, 'member', now() - interval '19 days'),
    (my_group_id, sophia_id, 'member', now() - interval '14 days'),
    (my_group_id, marcus_id, 'member', now() - interval '9 days'),
    (my_group_id, olivia_id, 'member', now() - interval '6 days'),
    (my_group_id, ethan_id, 'member', now() - interval '2 days')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  RAISE NOTICE 'Successfully created 7 test friends and added them to your group!';
  RAISE NOTICE 'Test accounts created:';
  RAISE NOTICE '  1. Alex Chen (alex.chen@test.com)';
  RAISE NOTICE '  2. Emma Wilson (emma.wilson@test.com)';
  RAISE NOTICE '  3. Jordan Rivera (jordan.rivera@test.com)';
  RAISE NOTICE '  4. Sophia Patel (sophia.patel@test.com)';
  RAISE NOTICE '  5. Marcus Johnson (marcus.johnson@test.com)';
  RAISE NOTICE '  6. Olivia Kim (olivia.kim@test.com)';
  RAISE NOTICE '  7. Ethan Brooks (ethan.brooks@test.com)';
  RAISE NOTICE '';
  RAISE NOTICE 'All accounts have password: TestPassword123!';
  RAISE NOTICE '';
  RAISE NOTICE 'All 7 test friends have been added to your group as members.';

END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check that users were created
SELECT id, email, full_name FROM users WHERE email LIKE '%@test.com' ORDER BY created_at;

-- Check that friendships were created (replace with your user ID)
-- SELECT * FROM get_friends('YOUR_USER_ID_HERE');

-- Check that group members were added (replace with your group ID)
-- SELECT u.full_name, gm.role, gm.joined_at
-- FROM group_members gm
-- JOIN users u ON u.id = gm.user_id
-- WHERE gm.group_id = 'YOUR_GROUP_ID_HERE'
-- ORDER BY gm.joined_at;
