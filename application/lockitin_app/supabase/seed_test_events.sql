-- Seed Test Events for Current User
-- Run this in Supabase SQL Editor after logging in
-- Replace YOUR_USER_ID with your actual user ID from auth.users

-- First, find your user ID by running:
-- SELECT id, email FROM auth.users;

-- Then replace 'YOUR_USER_ID' below with your actual UUID

-- IMPORTANT: Put your UUID in single quotes like: '61ac1893-cafa-4cbc-8fab-fa74b57e3ebb'

DO $$
DECLARE
  test_user_id UUID := '61ac1893-cafa-4cbc-8fab-fa74b57e3ebb'; -- Your user ID (in quotes!)
  today DATE := CURRENT_DATE;
BEGIN

-- Clear existing test events (optional - comment out if you want to keep existing)
-- DELETE FROM events WHERE user_id = test_user_id;

-- Insert test events across the next 30 days
INSERT INTO events (user_id, title, description, start_time, end_time, location, visibility, category, created_at)
VALUES
  -- Today's events
  (test_user_id, 'Morning Standup', 'Daily team sync',
   (today + INTERVAL '9 hours')::timestamp,
   (today + INTERVAL '9 hours 30 minutes')::timestamp,
   'Zoom', 'shared_with_name', 'work', NOW()),

  (test_user_id, 'Lunch with Sarah', 'Catch up over tacos',
   (today + INTERVAL '12 hours')::timestamp,
   (today + INTERVAL '13 hours')::timestamp,
   'Taco Bell', 'shared_with_name', 'friend', NOW()),

  -- Tomorrow
  (test_user_id, 'Gym Session', 'Leg day',
   (today + INTERVAL '1 day 6 hours')::timestamp,
   (today + INTERVAL '1 day 7 hours 30 minutes')::timestamp,
   'LA Fitness', 'busy_only', 'other', NOW()),

  (test_user_id, 'Project Review', 'Q1 milestone review',
   (today + INTERVAL '1 day 14 hours')::timestamp,
   (today + INTERVAL '1 day 15 hours')::timestamp,
   'Conference Room A', 'shared_with_name', 'work', NOW()),

  -- Day after tomorrow
  (test_user_id, 'Dentist Appointment', 'Regular checkup',
   (today + INTERVAL '2 days 10 hours')::timestamp,
   (today + INTERVAL '2 days 11 hours')::timestamp,
   'Downtown Dental', 'private', 'other', NOW()),

  -- This weekend
  (test_user_id, 'Game Night', 'Board games with the crew',
   (today + INTERVAL '5 days 19 hours')::timestamp,
   (today + INTERVAL '5 days 23 hours')::timestamp,
   'Mike''s place', 'shared_with_name', 'friend', NOW()),

  (test_user_id, 'Brunch', 'Sunday brunch tradition',
   (today + INTERVAL '6 days 11 hours')::timestamp,
   (today + INTERVAL '6 days 13 hours')::timestamp,
   'The Breakfast Club', 'shared_with_name', 'friend', NOW()),

  -- Next week
  (test_user_id, 'Sprint Planning', 'Plan Sprint 3 tasks',
   (today + INTERVAL '7 days 10 hours')::timestamp,
   (today + INTERVAL '7 days 12 hours')::timestamp,
   'Zoom', 'shared_with_name', 'work', NOW()),

  (test_user_id, 'Coffee with Alex', 'Networking catch-up',
   (today + INTERVAL '8 days 15 hours')::timestamp,
   (today + INTERVAL '8 days 16 hours')::timestamp,
   'Starbucks', 'shared_with_name', 'friend', NOW()),

  (test_user_id, 'Team Happy Hour', 'End of month celebration',
   (today + INTERVAL '9 days 17 hours')::timestamp,
   (today + INTERVAL '9 days 19 hours')::timestamp,
   'The Local Bar', 'shared_with_name', 'work', NOW()),

  -- Two weeks out
  (test_user_id, 'Doctor Appointment', 'Annual physical',
   (today + INTERVAL '14 days 9 hours')::timestamp,
   (today + INTERVAL '14 days 10 hours')::timestamp,
   'Medical Center', 'private', 'other', NOW()),

  (test_user_id, 'Birthday Party', 'Emma''s 30th!',
   (today + INTERVAL '15 days 18 hours')::timestamp,
   (today + INTERVAL '15 days 23 hours')::timestamp,
   'Rooftop Venue', 'shared_with_name', 'friend', NOW()),

  -- Special events
  (test_user_id, 'New Year''s Eve Party', 'Ring in 2026!',
   '2025-12-31 20:00:00'::timestamp,
   '2026-01-01 02:00:00'::timestamp,
   'Downtown', 'shared_with_name', 'friend', NOW()),

  (test_user_id, 'New Year''s Day', 'Recovery day',
   '2026-01-01 00:00:00'::timestamp,
   '2026-01-01 23:59:59'::timestamp,
   NULL, 'private', 'holiday', NOW()),

  -- Work deadlines
  (test_user_id, 'Project Deadline', 'MVP feature complete',
   (today + INTERVAL '10 days 17 hours')::timestamp,
   (today + INTERVAL '10 days 18 hours')::timestamp,
   NULL, 'busy_only', 'work', NOW()),

  (test_user_id, '1:1 with Manager', 'Weekly sync',
   (today + INTERVAL '3 days 11 hours')::timestamp,
   (today + INTERVAL '3 days 11 hours 30 minutes')::timestamp,
   'Office', 'private', 'work', NOW()),

  -- Recurring-style events (spread across weeks)
  (test_user_id, 'Yoga Class', 'Morning flow',
   (today + INTERVAL '4 days 7 hours')::timestamp,
   (today + INTERVAL '4 days 8 hours')::timestamp,
   'Yoga Studio', 'busy_only', 'other', NOW()),

  (test_user_id, 'Yoga Class', 'Morning flow',
   (today + INTERVAL '11 days 7 hours')::timestamp,
   (today + INTERVAL '11 days 8 hours')::timestamp,
   'Yoga Studio', 'busy_only', 'other', NOW()),

  (test_user_id, 'Yoga Class', 'Morning flow',
   (today + INTERVAL '18 days 7 hours')::timestamp,
   (today + INTERVAL '18 days 8 hours')::timestamp,
   'Yoga Studio', 'busy_only', 'other', NOW()),

  -- Movie night
  (test_user_id, 'Movie Night', 'New Marvel film',
   (today + INTERVAL '12 days 19 hours')::timestamp,
   (today + INTERVAL '12 days 22 hours')::timestamp,
   'AMC Theater', 'shared_with_name', 'friend', NOW());

RAISE NOTICE 'Successfully inserted 20 test events for user %', test_user_id;

END $$;

-- Verify the events were created
-- SELECT title, start_time, category, visibility FROM events ORDER BY start_time;
