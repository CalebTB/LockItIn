# Potluck Real-time Updates Troubleshooting Guide

## Problem
Dishes are being claimed/unclaimed successfully in the backend (confirmed by logs), but the UI doesn't update in real-time to show the changes.

## Root Cause
The `events` table is not included in the `supabase_realtime` publication, which means WebSocket subscriptions won't receive UPDATE events when dishes are claimed/unclaimed.

## Solution Steps

### Step 1: Verify Realtime Configuration

Run this query in your **Supabase SQL Editor**:

```sql
-- Check if events table is in realtime publication
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'events';
```

**Expected result:**
- If the query returns a row → ✅ Realtime IS enabled (skip to Step 3)
- If the query returns 0 rows → ❌ Realtime NOT enabled (continue to Step 2)

OR run the comprehensive verification script:
```bash
cat supabase/verify_realtime.sql
# Copy and paste the output into Supabase SQL Editor
```

### Step 2: Apply Migration 024

If realtime is NOT enabled, you need to apply migration 024.

**Option A: Using Supabase CLI** (if installed and configured)
```bash
cd /Users/calebbyers/Code/LockItIn
./supabase/apply_migration_024.sh
```

**Option B: Manual SQL** (in Supabase Dashboard → SQL Editor)
```sql
-- Enable realtime for events table
ALTER PUBLICATION supabase_realtime ADD TABLE events;
```

**Verify it worked:**
```sql
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';
-- Should now show 'events' in the list
```

### Step 3: Full App Restart (CRITICAL!)

⚠️ **This is the most important step!**

After applying the migration, you MUST:

1. **Stop the Flutter app completely** (don't just hot reload or hot restart)
2. **Close the app from the iOS simulator/Android emulator**
3. **Restart the app from scratch**

Why? WebSocket subscriptions are established when the app starts. They won't pick up the new realtime publication config unless the app is fully restarted.

### Step 4: Check Diagnostic Logs

After restarting the app with the enhanced logging, you should see these new log messages:

**When the event detail screen opens:**
```
🔌 Setting up realtime subscription for event <event-id>
📡 Subscription status changed: RealtimeSubscribeStatus.subscribed
✅ Successfully subscribed to real-time updates for event <event-id>
```

**When a dish is claimed/unclaimed:**
```
📨 Real-time callback triggered! Payload keys: [id, title, ...]
✅ Successfully parsed updated event. Dishes count: X
🔄 UI state updated with new event data
```

### Step 5: Test Claim/Unclaim

1. Open a Potluck event detail screen
2. Check logs for subscription setup messages
3. Claim or unclaim a dish
4. Watch for real-time callback logs
5. Verify the UI updates immediately

## Diagnostic Checklist

- [ ] Verified events table is in supabase_realtime publication
- [ ] Applied migration 024 if needed
- [ ] Fully restarted the app (not just hot reload)
- [ ] Saw "🔌 Setting up realtime subscription" log
- [ ] Saw "✅ Successfully subscribed" log
- [ ] Saw "📨 Real-time callback triggered" when claiming dish
- [ ] UI updated to show claimed/unclaimed status immediately

## Common Issues

### Issue: "Subscription timed out" or "Channel error"
**Solution:** Check your Supabase project status and internet connection. Restart the app.

### Issue: "Subscription closed"
**Solution:** The subscription was closed unexpectedly. Check for widget disposal or navigation issues.

### Issue: Callback triggers but fails to parse
**Error:** `❌ Failed to parse real-time update`
**Solution:** Check if the EventModel.fromJson correctly handles the template_data field.

### Issue: Still not working after following all steps
1. Check the Supabase dashboard → Database → Replication → Realtime
2. Verify the events table is listed
3. Check for any RLS policies blocking reads on events table
4. Try with a test account to rule out permissions issues

## Related Files

- Migration: `supabase/migrations/024_enable_realtime_events.sql`
- Verification: `supabase/verify_realtime.sql`
- Apply script: `supabase/apply_migration_024.sh`
- Widget code: `application/lockitin_app/lib/presentation/widgets/templates/potluck_dish_list.dart`

## Reference

This issue is documented in Pattern 6 of `flutter-supabase-critical-patterns.md`:
> "Check Database Config BEFORE Writing Client Code"

The Surprise Party template implementation revealed that template_data updates don't propagate in real-time unless the events table is explicitly added to the supabase_realtime publication.
