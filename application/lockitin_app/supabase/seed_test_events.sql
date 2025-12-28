-- LockItIn Test Events Seed Data
-- Creates 10 events per test user (70 total)
-- Date range: January 1-14, 2026
-- Duration range: 30 minutes to 4 hours
--
-- HOW TO USE:
-- 1. Run seed_test_friends.sql first (to create the test users)
-- 2. Run this script in Supabase SQL Editor
--
-- Last updated: December 27, 2025

-- ============================================================================
-- TEST USER IDs (must match seed_test_friends.sql)
-- ============================================================================

-- ============================================================================
-- CONFIGURATION - REPLACE THIS WITH YOUR USER ID
-- ============================================================================
-- Find your user ID: Go to Supabase Dashboard > Authentication > Users
-- Copy your UUID and paste it below

DO $$
DECLARE
  -- YOUR USER ID (replace this!)
  my_user_id UUID := 'YOUR_USER_ID_HERE';  -- <-- REPLACE THIS!

  -- Test user IDs (fixed UUIDs)
  alex_id UUID := '11111111-1111-1111-1111-111111111111';
  emma_id UUID := '22222222-2222-2222-2222-222222222222';
  jordan_id UUID := '33333333-3333-3333-3333-333333333333';
  sophia_id UUID := '44444444-4444-4444-4444-444444444444';
  marcus_id UUID := '55555555-5555-5555-5555-555555555555';
  olivia_id UUID := '66666666-6666-6666-6666-666666666666';
  ethan_id UUID := '77777777-7777-7777-7777-777777777777';

BEGIN

  -- ============================================================================
  -- YOUR EVENTS (10 events)
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (my_user_id, 'New Year Brunch', 'Starting the year right with friends', '2026-01-01 11:00:00-08', '2026-01-01 13:00:00-08', 'The Breakfast Club', 'sharedWithName', 'friend'),
    (my_user_id, 'Gym Session', 'Back to fitness routine', '2026-01-02 07:00:00-08', '2026-01-02 08:30:00-08', 'Equinox', 'private', 'other'),
    (my_user_id, 'Team Sync', 'Weekly planning meeting', '2026-01-03 10:00:00-08', '2026-01-03 11:00:00-08', 'Zoom', 'busyOnly', 'work'),
    (my_user_id, 'Dinner with Alex', 'Catching up over sushi', '2026-01-03 19:00:00-08', '2026-01-03 21:00:00-08', 'Nobu', 'sharedWithName', 'friend'),
    (my_user_id, 'Hiking Trip', 'Weekend adventure', '2026-01-04 08:00:00-08', '2026-01-04 12:00:00-08', 'Mt. Tam', 'sharedWithName', 'friend'),
    -- Week 2
    (my_user_id, 'Dentist Appointment', 'Regular checkup', '2026-01-07 14:00:00-08', '2026-01-07 15:00:00-08', 'Downtown Dental', 'private', 'other'),
    (my_user_id, 'Project Deadline', 'Feature complete milestone', '2026-01-08 09:00:00-08', '2026-01-08 17:00:00-08', 'Office', 'busyOnly', 'work'),
    (my_user_id, 'Game Night', 'Board games with the crew', '2026-01-10 18:00:00-08', '2026-01-10 22:00:00-08', 'My Place', 'sharedWithName', 'friend'),
    (my_user_id, 'Coffee with Jordan', 'Discussing music projects', '2026-01-12 10:00:00-08', '2026-01-12 11:30:00-08', 'Blue Bottle', 'sharedWithName', 'friend'),
    (my_user_id, 'Yoga Class', 'Midweek stretch', '2026-01-14 07:00:00-08', '2026-01-14 08:00:00-08', 'CorePower Yoga', 'busyOnly', 'other')
  ON CONFLICT DO NOTHING;

  -- ============================================================================
  -- ALEX CHEN - Software engineer, hiking, board games
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (alex_id, 'Morning Standup', 'Daily team sync', '2026-01-02 09:00:00-08', '2026-01-02 09:30:00-08', 'Zoom', 'busyOnly', 'work'),
    (alex_id, 'Code Review Session', 'Review PR for auth module', '2026-01-02 14:00:00-08', '2026-01-02 16:00:00-08', 'Office', 'busyOnly', 'work'),
    (alex_id, 'Hiking at Mission Peak', 'Weekend hike with the crew', '2026-01-04 07:00:00-08', '2026-01-04 11:00:00-08', 'Mission Peak Trail', 'sharedWithName', 'friend'),
    (alex_id, 'Board Game Night', 'Settlers of Catan tournament', '2026-01-05 18:00:00-08', '2026-01-05 22:00:00-08', 'My Place', 'sharedWithName', 'friend'),
    (alex_id, 'Sprint Planning', 'Q1 sprint kickoff', '2026-01-06 10:00:00-08', '2026-01-06 12:00:00-08', 'Conference Room A', 'busyOnly', 'work'),
    -- Week 2
    (alex_id, 'Lunch with Emma', 'Catch up over ramen', '2026-01-08 12:00:00-08', '2026-01-08 13:30:00-08', 'Ichiraku Ramen', 'sharedWithName', 'friend'),
    (alex_id, 'Tech Talk: Rust', 'Learning new language', '2026-01-09 15:00:00-08', '2026-01-09 16:30:00-08', 'Online', 'busyOnly', 'work'),
    (alex_id, 'Gym Session', 'Leg day', '2026-01-10 06:30:00-08', '2026-01-10 08:00:00-08', '24 Hour Fitness', 'private', 'other'),
    (alex_id, 'D&D Campaign', 'Chapter 5: The Dragon''s Lair', '2026-01-11 14:00:00-08', '2026-01-11 18:00:00-08', 'Jordan''s Place', 'sharedWithName', 'friend'),
    (alex_id, 'Mentorship Call', 'Career advice for junior dev', '2026-01-13 16:00:00-08', '2026-01-13 17:00:00-08', 'Google Meet', 'busyOnly', 'work')
  ON CONFLICT DO NOTHING;

  -- ============================================================================
  -- EMMA WILSON - Foodie, amateur photographer
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (emma_id, 'Food Photography Workshop', 'Learn lighting techniques', '2026-01-01 10:00:00-08', '2026-01-01 14:00:00-08', 'SF Photography Studio', 'sharedWithName', 'other'),
    (emma_id, 'Brunch at Tartine', 'Trying the new menu', '2026-01-02 10:30:00-08', '2026-01-02 12:00:00-08', 'Tartine Bakery', 'sharedWithName', 'friend'),
    (emma_id, 'Golden Hour Shoot', 'Sunset photos at the pier', '2026-01-03 16:00:00-08', '2026-01-03 18:00:00-08', 'Pier 39', 'sharedWithName', 'other'),
    (emma_id, 'Cooking Class: Italian', 'Pasta making from scratch', '2026-01-04 14:00:00-08', '2026-01-04 17:00:00-08', 'Sur La Table', 'sharedWithName', 'other'),
    (emma_id, 'Coffee with Sophia', 'Weekly catch-up', '2026-01-06 09:00:00-08', '2026-01-06 10:00:00-08', 'Blue Bottle Coffee', 'sharedWithName', 'friend'),
    -- Week 2
    (emma_id, 'Restaurant Review', 'New Korean BBQ spot', '2026-01-07 19:00:00-08', '2026-01-07 21:00:00-08', 'KBBQ House', 'sharedWithName', 'friend'),
    (emma_id, 'Photo Editing Session', 'Editing last week''s shoots', '2026-01-09 13:00:00-08', '2026-01-09 15:30:00-08', 'Home Office', 'busyOnly', 'work'),
    (emma_id, 'Farmers Market Trip', 'Fresh ingredients for the week', '2026-01-11 08:00:00-08', '2026-01-11 10:00:00-08', 'Ferry Building', 'sharedWithName', 'other'),
    (emma_id, 'Wine Tasting', 'Napa Valley day trip', '2026-01-12 11:00:00-08', '2026-01-12 15:00:00-08', 'Opus One Winery', 'sharedWithName', 'friend'),
    (emma_id, 'Blog Post Writing', 'Review of Italian class', '2026-01-14 14:00:00-08', '2026-01-14 16:00:00-08', 'Home', 'private', 'work')
  ON CONFLICT DO NOTHING;

  -- ============================================================================
  -- JORDAN RIVERA - Music producer, coffee enthusiast
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (jordan_id, 'Studio Session', 'Working on new track', '2026-01-01 20:00:00-08', '2026-01-02 00:00:00-08', 'Home Studio', 'busyOnly', 'work'),
    (jordan_id, 'Coffee Cupping', 'Tasting new Ethiopian beans', '2026-01-02 11:00:00-08', '2026-01-02 12:30:00-08', 'Sightglass Coffee', 'sharedWithName', 'other'),
    (jordan_id, 'Mixing Session', 'Final mix for client album', '2026-01-03 14:00:00-08', '2026-01-03 18:00:00-08', 'Hyde Street Studios', 'busyOnly', 'work'),
    (jordan_id, 'Open Mic Night', 'Checking out new artists', '2026-01-04 20:00:00-08', '2026-01-04 23:00:00-08', 'The Fillmore', 'sharedWithName', 'friend'),
    (jordan_id, 'Vinyl Shopping', 'Record store day trip', '2026-01-05 13:00:00-08', '2026-01-05 15:00:00-08', 'Amoeba Music', 'sharedWithName', 'other'),
    -- Week 2
    (jordan_id, 'Podcast Recording', 'Guest on music production show', '2026-01-07 10:00:00-08', '2026-01-07 11:30:00-08', 'Spotify Studios', 'sharedWithName', 'work'),
    (jordan_id, 'Coffee Date with Marcus', 'Discussing collab ideas', '2026-01-08 15:00:00-08', '2026-01-08 16:30:00-08', 'Ritual Coffee', 'sharedWithName', 'friend'),
    (jordan_id, 'Beat Making Workshop', 'Teaching basics to beginners', '2026-01-10 14:00:00-08', '2026-01-10 17:00:00-08', 'Community Center', 'sharedWithName', 'work'),
    (jordan_id, 'Concert: Bonobo', 'Live electronic show', '2026-01-11 20:00:00-08', '2026-01-11 23:30:00-08', 'The Greek Theatre', 'sharedWithName', 'friend'),
    (jordan_id, 'Mastering Session', 'Final touches on EP', '2026-01-13 10:00:00-08', '2026-01-13 14:00:00-08', 'Home Studio', 'busyOnly', 'work')
  ON CONFLICT DO NOTHING;

  -- ============================================================================
  -- SOPHIA PATEL - Yoga instructor, book lover
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (sophia_id, 'Morning Yoga Class', 'Vinyasa flow', '2026-01-01 06:00:00-08', '2026-01-01 07:30:00-08', 'CorePower Yoga', 'sharedWithName', 'work'),
    (sophia_id, 'Book Club Meeting', 'Discussing "Project Hail Mary"', '2026-01-02 18:00:00-08', '2026-01-02 20:00:00-08', 'Olivia''s Place', 'sharedWithName', 'friend'),
    (sophia_id, 'Private Yoga Session', 'One-on-one with new client', '2026-01-03 09:00:00-08', '2026-01-03 10:00:00-08', 'Client Home', 'busyOnly', 'work'),
    (sophia_id, 'Meditation Retreat', 'Weekend mindfulness workshop', '2026-01-04 09:00:00-08', '2026-01-04 13:00:00-08', 'Spirit Rock Center', 'sharedWithName', 'other'),
    (sophia_id, 'Library Trip', 'Picking up new reads', '2026-01-05 14:00:00-08', '2026-01-05 15:30:00-08', 'SF Public Library', 'private', 'other'),
    -- Week 2
    (sophia_id, 'Sunrise Yoga', 'Beach session', '2026-01-07 06:30:00-08', '2026-01-07 08:00:00-08', 'Ocean Beach', 'sharedWithName', 'work'),
    (sophia_id, 'Tea with Emma', 'Matcha and catching up', '2026-01-08 15:00:00-08', '2026-01-08 16:30:00-08', 'Stonemill Matcha', 'sharedWithName', 'friend'),
    (sophia_id, 'Yoga Teacher Training', 'Advanced certification class', '2026-01-10 09:00:00-08', '2026-01-10 12:00:00-08', 'Yoga Works', 'busyOnly', 'work'),
    (sophia_id, 'Reading Time', 'Finishing current book', '2026-01-11 19:00:00-08', '2026-01-11 21:00:00-08', 'Home', 'private', 'other'),
    (sophia_id, 'Group Hike', 'Mindful walking meditation', '2026-01-13 08:00:00-08', '2026-01-13 11:00:00-08', 'Muir Woods', 'sharedWithName', 'friend')
  ON CONFLICT DO NOTHING;

  -- ============================================================================
  -- MARCUS JOHNSON - Basketball player, movie buff
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (marcus_id, 'Morning Pickup Game', 'Full court 5v5', '2026-01-01 08:00:00-08', '2026-01-01 10:00:00-08', 'Mission Playground', 'sharedWithName', 'friend'),
    (marcus_id, 'Warriors Game', 'vs Lakers - should be good!', '2026-01-02 19:00:00-08', '2026-01-02 22:00:00-08', 'Chase Center', 'sharedWithName', 'friend'),
    (marcus_id, 'Movie Marathon', 'MCU Phase 4 catch-up', '2026-01-04 13:00:00-08', '2026-01-04 17:00:00-08', 'Home', 'sharedWithName', 'friend'),
    (marcus_id, 'Basketball Practice', 'Working on 3-pointers', '2026-01-05 07:00:00-08', '2026-01-05 08:30:00-08', 'YMCA', 'busyOnly', 'other'),
    (marcus_id, 'Film Club Screening', 'Classic: Pulp Fiction', '2026-01-06 19:00:00-08', '2026-01-06 22:00:00-08', 'Alamo Drafthouse', 'sharedWithName', 'friend'),
    -- Week 2
    (marcus_id, 'Gym Workout', 'Strength training day', '2026-01-08 06:00:00-08', '2026-01-08 07:30:00-08', 'Equinox', 'private', 'other'),
    (marcus_id, 'Lunch with Alex', 'Sports bar for game highlights', '2026-01-09 12:00:00-08', '2026-01-09 13:30:00-08', 'Buffalo Wild Wings', 'sharedWithName', 'friend'),
    (marcus_id, 'League Game', 'Rec league playoffs!', '2026-01-10 20:00:00-08', '2026-01-10 22:00:00-08', 'Kezar Pavilion', 'sharedWithName', 'friend'),
    (marcus_id, 'Movie Night: Oppenheimer', 'Finally watching it', '2026-01-12 18:00:00-08', '2026-01-12 21:00:00-08', 'AMC Metreon', 'sharedWithName', 'friend'),
    (marcus_id, 'Pickup Basketball', 'Sunday morning tradition', '2026-01-14 09:00:00-08', '2026-01-14 11:00:00-08', 'Dolores Park', 'sharedWithName', 'friend')
  ON CONFLICT DO NOTHING;

  -- ============================================================================
  -- OLIVIA KIM - Graphic designer, plant mom
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (olivia_id, 'Client Presentation', 'Logo reveal for startup', '2026-01-02 10:00:00-08', '2026-01-02 11:00:00-08', 'Client Office', 'busyOnly', 'work'),
    (olivia_id, 'Plant Nursery Visit', 'Looking for new monstera', '2026-01-03 11:00:00-08', '2026-01-03 13:00:00-08', 'Sloat Garden Center', 'sharedWithName', 'other'),
    (olivia_id, 'Design Sprint', 'App redesign workshop', '2026-01-04 09:00:00-08', '2026-01-04 13:00:00-08', 'WeWork', 'busyOnly', 'work'),
    (olivia_id, 'Pottery Class', 'Making new plant pots', '2026-01-05 14:00:00-08', '2026-01-05 17:00:00-08', 'The Clay Studio', 'sharedWithName', 'other'),
    (olivia_id, 'Portfolio Review', 'Getting feedback from mentor', '2026-01-06 15:00:00-08', '2026-01-06 16:30:00-08', 'Zoom', 'busyOnly', 'work'),
    -- Week 2
    (olivia_id, 'Plant Swap Meet', 'Trading cuttings with friends', '2026-01-07 11:00:00-08', '2026-01-07 13:00:00-08', 'Dolores Park', 'sharedWithName', 'friend'),
    (olivia_id, 'Freelance Work Block', 'Website mockups', '2026-01-09 09:00:00-08', '2026-01-09 12:00:00-08', 'Home Office', 'busyOnly', 'work'),
    (olivia_id, 'Art Gallery Opening', 'New exhibition downtown', '2026-01-10 18:00:00-08', '2026-01-10 20:00:00-08', 'SFMOMA', 'sharedWithName', 'friend'),
    (olivia_id, 'Watering Day', 'Tending to all 47 plants', '2026-01-12 09:00:00-08', '2026-01-12 10:00:00-08', 'Home', 'private', 'other'),
    (olivia_id, 'Design Meetup', 'SF Designers monthly', '2026-01-14 18:00:00-08', '2026-01-14 20:30:00-08', 'GitHub HQ', 'sharedWithName', 'work')
  ON CONFLICT DO NOTHING;

  -- ============================================================================
  -- ETHAN BROOKS - Chef, travel addict
  -- ============================================================================

  INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category)
  VALUES
    -- Week 1
    (ethan_id, 'Dinner Service Prep', 'Mise en place for the week', '2026-01-01 14:00:00-08', '2026-01-01 18:00:00-08', 'Restaurant Kitchen', 'busyOnly', 'work'),
    (ethan_id, 'Farmers Market Sourcing', 'Finding seasonal ingredients', '2026-01-02 07:00:00-08', '2026-01-02 09:00:00-08', 'Civic Center Market', 'sharedWithName', 'work'),
    (ethan_id, 'Private Dinner Party', 'Cooking for 8 guests', '2026-01-03 17:00:00-08', '2026-01-03 21:00:00-08', 'Client Home', 'busyOnly', 'work'),
    (ethan_id, 'Travel Planning', 'Researching Tokyo food scene', '2026-01-04 10:00:00-08', '2026-01-04 12:00:00-08', 'Home', 'private', 'other'),
    (ethan_id, 'Cooking Demo', 'Teaching knife skills', '2026-01-05 11:00:00-08', '2026-01-05 13:30:00-08', 'Williams Sonoma', 'sharedWithName', 'work'),
    -- Week 2
    (ethan_id, 'Dim Sum Brunch', 'Eating research for menu ideas', '2026-01-07 10:00:00-08', '2026-01-07 12:00:00-08', 'Yank Sing', 'sharedWithName', 'friend'),
    (ethan_id, 'Menu Development', 'Testing new spring dishes', '2026-01-08 13:00:00-08', '2026-01-08 17:00:00-08', 'Test Kitchen', 'busyOnly', 'work'),
    (ethan_id, 'Wine Pairing Dinner', 'Collaborative event with sommelier', '2026-01-10 18:00:00-08', '2026-01-10 22:00:00-08', 'Restaurant', 'sharedWithName', 'work'),
    (ethan_id, 'Beach BBQ', 'Casual cookout with friends', '2026-01-11 12:00:00-08', '2026-01-11 16:00:00-08', 'Baker Beach', 'sharedWithName', 'friend'),
    (ethan_id, 'Recipe Writing', 'Documenting new creations', '2026-01-13 09:00:00-08', '2026-01-13 11:00:00-08', 'Home', 'private', 'work')
  ON CONFLICT DO NOTHING;

  RAISE NOTICE 'Successfully created 80 events!';
  RAISE NOTICE '  - 10 events for YOU';
  RAISE NOTICE '  - 70 events for 7 test friends (10 each)';
  RAISE NOTICE 'Events span January 1-14, 2026';
  RAISE NOTICE 'Durations range from 30 minutes to 4 hours';

END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check event counts per user
SELECT
  u.full_name,
  COUNT(e.id) as event_count,
  MIN(e.start_time) as first_event,
  MAX(e.end_time) as last_event
FROM users u
LEFT JOIN events e ON e.user_id = u.id
WHERE u.email LIKE '%@test.com'
GROUP BY u.id, u.full_name
ORDER BY u.full_name;

-- Sample of events
SELECT
  u.full_name,
  e.title,
  e.start_time,
  e.end_time,
  e.visibility
FROM events e
JOIN users u ON u.id = e.user_id
WHERE u.email LIKE '%@test.com'
ORDER BY e.start_time
LIMIT 20;
