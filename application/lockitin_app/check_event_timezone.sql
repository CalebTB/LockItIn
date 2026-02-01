-- Check the most recent Friendsgiving event
SELECT 
  id,
  title,
  group_id,
  start_time,
  end_time,
  all_day,
  visibility,
  created_at
FROM events
WHERE title LIKE '%Friendsgiving%'
ORDER BY created_at DESC
LIMIT 1;
