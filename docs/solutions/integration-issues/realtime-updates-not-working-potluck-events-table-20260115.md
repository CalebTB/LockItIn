---
module: Templates
date: 2026-01-15
problem_type: integration_issue
component: database
symptoms:
  - "Potluck dish claim/unclaim successful in backend but UI not updating"
  - "Real-time subscriptions connected successfully but callbacks never fired"
  - "UI showed 'Claimed by Unknown' instead of actual user"
  - "No realtime callback logs despite successful subscription"
root_cause: config_error
resolution_type: config_change
severity: high
tags: [realtime, supabase, websocket, potluck, template, publication, mcp]
---

# Real-time Updates Not Working: Potluck Template Events Table

## Problem

Potluck dish claim/unclaim operations were succeeding in the backend (confirmed by logs), but the UI was not updating in real-time. Users saw dishes remain in their original state or show "Claimed by Unknown" instead of the actual claimer's name.

## Environment

- **Module:** Templates (Potluck)
- **Flutter Version:** 3.16+
- **Supabase Backend:** PostgreSQL + Row Level Security + Realtime
- **Sprint:** Sprint 4 (Templates Framework)
- **Date:** 2026-01-15

## Related Issues

- **Similar Issue:** [Surprise Party RSVP Real-time Updates](../workflow-issues/ai-agent-not-consulting-existing-code-event-templates-20260114.md) - Same root cause with `event_invitations` table
- **Critical Pattern:** Pattern 6 in [Flutter + Supabase Critical Patterns](../patterns/flutter-supabase-critical-patterns.md) - "Check Database Config BEFORE Writing Client Code"
- **Performance Issue:** [GitHub Issue #247](https://github.com/CalebTB/LockItIn/issues/247) - Real-time updates now work but feel clunky

## Symptoms

1. **Backend Operations Successful:**
   ```
   flutter: 🔵 LockItIn [EventService] ℹ️  Updated event in Supabase
   flutter: 🔵 LockItIn [CalendarProvider] ℹ️  Claimed dish aba9e641... for event a1b1729b...
   ```

2. **Subscriptions Connected Successfully:**
   ```
   flutter: 🔵 LockItIn [PotluckDishList] ℹ️  🔌 Setting up realtime subscription
   flutter: 🔵 LockItIn [PotluckDishList] ℹ️  📡 Subscription status changed: RealtimeSubscribeStatus.subscribed
   flutter: 🔵 LockItIn [PotluckDishList] ℹ️  ✅ Successfully subscribed to real-time updates
   ```

3. **But No Callbacks Fired:**
   - Missing log: `📨 Real-time callback triggered!` (never appeared)
   - UI did not update despite successful subscription
   - User saw stale data or "Claimed by Unknown"

4. **User Observation:**
   > "as you can see i claimed the dish but Ui not showing that"

## Investigation Attempts

### Attempt 1: Added Real-time Subscriptions to Widgets
**What we tried:**
```dart
class _PotluckDishListState extends State<PotluckDishList> {
  RealtimeChannel? _channel;
  late EventModel _currentEvent;

  void _setupRealtimeSubscription() {
    _channel = supabase.channel('potluck-event-${widget.event.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'events',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: widget.event.id,
        ),
        callback: (payload) {
          // Parse and update UI
        },
      )
      .subscribe();
  }
}
```

**Why it didn't work:** Subscription code was correct, but database wasn't configured to broadcast `events` table changes.

### Attempt 2: Added Comprehensive Diagnostic Logging
**What we tried:**
- Added logging for subscription setup
- Added logging for subscription status changes
- Added logging for callbacks with payload details
- Added logging for event parsing and UI updates

**Why it didn't work:** Logs confirmed subscriptions were connecting successfully, but callbacks were never triggered. This narrowed the problem to database configuration, not client code.

### Attempt 3: Manually Asked User to Apply Migration
**What we tried:**
- Created migration script `supabase/apply_migration_024.sh`
- Created verification SQL `supabase/verify_realtime.sql`
- Asked user to manually run SQL in Supabase Dashboard

**Why it was suboptimal:** Supabase MCP tool was available but wasn't used. This added friction and delayed the fix.

## Root Cause

The `events` table was **not included** in the `supabase_realtime` publication in PostgreSQL.

**Technical Explanation:**

1. Supabase Realtime uses PostgreSQL's logical replication feature via publications
2. Only tables explicitly added to `supabase_realtime` publication broadcast changes
3. The `events` table was missing from this publication
4. WebSocket subscriptions connected successfully (no error)
5. But Postgres never sent UPDATE events to the WebSocket because the table wasn't being replicated

**Verification Query:**
```sql
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'events';
-- Result: 0 rows (events NOT in publication)
```

**Additional Learning:**

The AI agent should have used the **Supabase MCP tool** immediately instead of asking the user to manually run SQL. MCP tools are first-class capabilities that should be preferred over manual operations.

## Solution

### Step 1: Verify Events Table Missing from Publication

Used **Supabase MCP** to check:

```sql
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
    'events table NOT in realtime publication ❌' as status
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'events'
);
```

**Result:** ❌ Events table NOT in publication

### Step 2: Apply Migration 024 via Supabase MCP

```sql
-- Enable realtime for events table
ALTER PUBLICATION supabase_realtime ADD TABLE events;
```

**Applied via:** `mcp__supabase__execute_sql` tool

### Step 3: Verify Events Table Now in Publication

```sql
SELECT
    schemaname,
    tablename,
    '📡 In realtime publication' as status
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;
```

**Result:**
```
- event_invitations ✓
- event_proposals ✓
- events ✓  ← Newly added
- notifications ✓
- proposal_votes ✓
```

### Step 4: Full App Restart (CRITICAL!)

⚠️ **WebSocket subscriptions only connect on app startup**. Hot reload is NOT sufficient.

1. Stop the app completely
2. Close from simulator/emulator
3. Restart from scratch

### Step 5: Test Real-time Updates

After restart, claiming/unclaiming dishes now shows:

```
🔌 Setting up realtime subscription for event <id>
📡 Subscription status changed: RealtimeSubscribeStatus.subscribed
✅ Successfully subscribed to real-time updates for event <id>

[User claims dish]

📨 Real-time callback triggered! Payload keys: [id, title, ...]
✅ Successfully parsed updated event. Dishes count: X
🔄 UI state updated with new event data
```

✅ **UI now updates immediately without refresh**

## Key Files

- Migration: `supabase/migrations/024_enable_realtime_events.sql`
- Widget: `application/lockitin_app/lib/presentation/widgets/templates/potluck_dish_list.dart`
- Widget: `application/lockitin_app/lib/presentation/widgets/templates/potluck_summary_card.dart`
- Model: `application/lockitin_app/lib/data/models/event_template_model.dart`
- Troubleshooting Guide: `REALTIME_TROUBLESHOOTING.md`
- Migration Log: `supabase/migrations/APPLIED.md`

## Prevention

### 1. Check Database Config BEFORE Client Code

**Before writing WebSocket subscription code:**

```sql
-- 1. Verify table is in realtime publication
SELECT * FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'your_table';

-- 2. If missing, add it
ALTER PUBLICATION supabase_realtime ADD TABLE your_table;

-- 3. Document it
COMMENT ON TABLE your_table IS
'Your table description. Realtime enabled for live updates.';
```

**Reference:** Pattern 6 in [Flutter + Supabase Critical Patterns](../patterns/flutter-supabase-critical-patterns.md)

### 2. Use MCP Tools When Available

**❌ WRONG:**
```
AI: "Please run this SQL in your Supabase dashboard..."
User: [manually copies, navigates to dashboard, pastes, runs]
```

**✅ CORRECT:**
```dart
// Use Supabase MCP tool directly
mcp__supabase__execute_sql(query: "ALTER PUBLICATION...")
```

**Rule:** When MCP tools are available (Supabase, GitHub, etc.), use them instead of asking users to manually perform operations. MCP tools are first-class capabilities.

### 3. Add Comprehensive Diagnostic Logging

When implementing real-time features:

```dart
void _setupRealtimeSubscription() {
  Logger.info('Widget', '🔌 Setting up realtime subscription');

  _channel = supabase.channel('channel-name')
    .onPostgresChanges(
      // ...
      callback: (payload) {
        Logger.info('Widget', '📨 Real-time callback triggered!');
        // Process update
        Logger.info('Widget', '🔄 UI state updated');
      },
    )
    .subscribe((status, error) {
      Logger.info('Widget', '📡 Subscription status: $status');
      if (error != null) {
        Logger.error('Widget', '❌ Subscription error: $error');
      }
    });
}
```

This logging quickly identified that callbacks weren't firing, narrowing the problem to database config.

### 4. Full App Restart After Database Config Changes

WebSocket subscriptions connect during app initialization. They won't pick up new publication configs with hot reload.

**After applying database config changes:**
1. Stop app completely
2. Restart from scratch
3. Verify subscriptions reconnect with new config

### 5. Create Migration for Realtime Configuration

Don't rely on manual SQL - create a migration:

```sql
-- supabase/migrations/024_enable_realtime_events.sql
-- Migration: Enable Realtime for Events Table
-- Purpose: Allow real-time updates for template_data changes

ALTER PUBLICATION supabase_realtime ADD TABLE events;

COMMENT ON TABLE events IS
'Calendar events with privacy settings. Realtime enabled for template updates.';
```

### 6. Document Applied Migrations

Track manual migrations in `supabase/migrations/APPLIED.md`:

```markdown
## 2026-01-15

### Migration 024: Enable Realtime for Events Table
**Applied via:** Supabase MCP
**Status:** ✅ Applied successfully
```

## Testing

### Manual Test Plan

1. **Setup:**
   - Create Potluck event with 3+ dishes
   - Open event detail screen
   - Verify subscription logs appear

2. **Test Claim:**
   - Claim a dish
   - Verify callback log appears: `📨 Real-time callback triggered!`
   - Verify UI updates immediately (no refresh needed)
   - Verify correct user name displayed

3. **Test Unclaim:**
   - Unclaim a dish
   - Verify callback log appears
   - Verify UI updates to show dish as available
   - Verify no "Claimed by Unknown" displayed

4. **Test Multiple Users:**
   - Open same event on two devices/users
   - User A claims dish
   - User B's screen should update immediately
   - Verify both see consistent state

### Verification Queries

```sql
-- Verify events table in publication
SELECT tablename FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- Check realtime settings
SELECT * FROM pg_publication WHERE pubname = 'supabase_realtime';
```

## Related Documentation

- **Critical Patterns:** [Flutter + Supabase Critical Patterns](../patterns/flutter-supabase-critical-patterns.md) - Pattern 6
- **Similar Issue:** [Surprise Party RSVP Real-time Updates](../workflow-issues/ai-agent-not-consulting-existing-code-event-templates-20260114.md)
- **Migration File:** `supabase/migrations/024_enable_realtime_events.sql`
- **Troubleshooting Guide:** `REALTIME_TROUBLESHOOTING.md`
- **Performance Follow-up:** [GitHub Issue #247](https://github.com/CalebTB/LockItIn/issues/247)

## Lessons Learned

1. **Database config must be verified BEFORE writing client code** - Silent failures waste debugging time
2. **Use MCP tools when available** - Don't ask users to manually perform operations
3. **Comprehensive logging is essential** - Helps narrow problems quickly
4. **Full app restart required after database config changes** - Hot reload insufficient for WebSocket reconnection
5. **This pattern repeats** - Same issue occurred with Surprise Party template's `event_invitations` table

## Future Improvements

- Add automated test to verify all template-related tables are in realtime publication
- Create pre-deployment checklist: "Are all tables that need realtime in the publication?"
- Document MCP tool usage patterns for common operations
- Add CI check to ensure migrations that add realtime are properly tracked
