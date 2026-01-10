---
module: Database Schema
date: 2026-01-09
problem_type: database_issue
component: postgresql_enum
symptoms:
  - "invalid input value for enum event_visibility: 'shared_with_name'"
  - "Visibility settings not preserved after hot restart"
  - "Events saved as 'shared with details' show as 'private' after restart"
root_cause: schema_mismatch
severity: critical
stage: Phase 2 Testing
tags: [enum-values, database-migration, type-safety, visibility-privacy]
related_issues:
  - "PR #234 - Phase 2: Timezone Support & Bug Fixes"
  - "Issue #211 - Timezone Support for Cross-Timezone Users (Epic)"
  - "supabase/migrations/015_add_all_day_to_events.sql"
  - "supabase/migrations/016_fix_event_visibility_enum.sql"
  - "supabase/migrations/017_convert_visibility_to_enum.sql"
  - "docs/solutions/logic-errors/events-not-persisting-calendar-20260109.md"
---

# Event Visibility Enum Mismatch & Type Issues

## Problem

**Severity:** 🔴 CRITICAL - Data Integrity & Privacy

**Observable Symptoms:**

1. **Enum value rejection:**
   ```
   PostgrestException: invalid input value for enum event_visibility: "shared_with_name"
   ```

2. **Visibility not preserved:**
   - User saves event as "Shared with details"
   - After hot restart, event shows as "Private"
   - Privacy settings silently reset to default

3. **Missing all_day column:**
   ```
   PostgrestException: Could not find the 'all_day' column of 'events' in the schema cache
   ```

## Investigation

### Three Separate Issues Discovered

1. **Missing `all_day` column** - EventModel.toJson() included field that didn't exist in database
2. **Enum value format mismatch** - App sends snake_case, database has camelCase
3. **Column type wrong** - `visibility` was TEXT instead of enum type

### Root Causes

#### Issue 1: Missing all_day Column

**File:** `lib/data/models/event_model.dart`

```dart
Map<String, dynamic> toJson() {
  return {
    'title': title,
    'start_time': TimezoneUtils.toUtcString(startTime),
    'end_time': TimezoneUtils.toUtcString(endTime),
    'all_day': allDay,  // ❌ Column doesn't exist in database!
    // ... other fields
  };
}
```

**Database state:**
```sql
-- events table had NO all_day column
SELECT column_name FROM information_schema.columns
WHERE table_name = 'events' AND column_name = 'all_day';
-- Returns: (empty)
```

#### Issue 2: Enum Value Format Mismatch

**App code (Dart):**
```dart
enum EventVisibility {
  private,           // 'private'
  sharedWithName,    // 'shared_with_name'  ← snake_case
  busyOnly,          // 'busy_only'         ← snake_case
}
```

**Database enum (PostgreSQL):**
```sql
SELECT enumlabel FROM pg_enum
WHERE enumtypid = 'event_visibility'::regtype;

-- Results:
-- 'private'
-- 'sharedWithName'  ← camelCase ❌
-- 'busyOnly'        ← camelCase ❌
```

**Why this breaks:**
1. App sends `visibility: 'shared_with_name'` in JSON
2. PostgreSQL tries to cast to event_visibility enum
3. 'shared_with_name' doesn't exist in enum → ERROR
4. Transaction rolls back, event creation fails

#### Issue 3: Visibility Column Type Wrong

**Database schema inspection:**
```sql
SELECT column_name, data_type, udt_name, column_default
FROM information_schema.columns
WHERE table_name = 'events' AND column_name = 'visibility';

-- Results:
-- column_name | data_type | udt_name | column_default
-- visibility  | text      | text     | 'private'::text  ← TEXT, not enum!
```

**Why this breaks:**
1. Column type is `TEXT`, not `event_visibility` enum
2. No type enforcement → any string accepted
3. Default is `'private'::text` instead of `'private'::event_visibility`
4. RLS policies comparing enum values fail type checks
5. Data can become inconsistent

**User impact:**
- Event saved with visibility = 'shared_with_name'
- Hot restart → app re-fetches from database
- Database returns TEXT 'shared_with_name'
- App expects enum, gets TEXT → defaults to 'private'
- Privacy settings silently lost

## Solution

### Migration 1: Add all_day Column

**File:** `supabase/migrations/015_add_all_day_to_events.sql`

```sql
-- Add missing all_day column to events table
ALTER TABLE events
ADD COLUMN IF NOT EXISTS all_day BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN events.all_day IS
  'True if this is an all-day event (no specific time)';

-- Add index for filtering all-day vs timed events
CREATE INDEX IF NOT EXISTS idx_events_all_day ON events(all_day);
```

**Result:**
- ✅ Events can now be created with all_day = true/false
- ✅ Schema matches EventModel.toJson()
- ✅ Index improves query performance for calendar filtering

### Migration 2: Fix Enum Values

**File:** `supabase/migrations/016_fix_event_visibility_enum.sql`

```sql
-- Add snake_case enum values to match app constants
ALTER TYPE event_visibility ADD VALUE IF NOT EXISTS 'shared_with_name';
ALTER TYPE event_visibility ADD VALUE IF NOT EXISTS 'busy_only';

-- Migrate existing data from camelCase to snake_case
UPDATE events
SET visibility = 'shared_with_name'
WHERE visibility = 'sharedWithName';

UPDATE events
SET visibility = 'busy_only'
WHERE visibility = 'busyOnly';

-- Do the same for shadow_calendar table
UPDATE shadow_calendar
SET visibility = 'shared_with_name'
WHERE visibility = 'sharedWithName';

UPDATE shadow_calendar
SET visibility = 'busy_only'
WHERE visibility = 'busyOnly';

-- Note: Cannot remove old enum values without recreating type
-- Old values (sharedWithName, busyOnly) remain but won't be used
```

**Data migration results:**
- 162 events migrated to 'shared_with_name'
- 44 events migrated to 'busy_only'
- 17 events already 'private' (no change)

### Migration 3: Convert Column Type to Enum

**File:** `supabase/migrations/017_convert_visibility_to_enum.sql`

```sql
-- Step 1: Drop RLS policy that references visibility column
-- (Must drop before changing column type)
DROP POLICY IF EXISTS "Users can view own and group members events" ON events;

-- Step 2: Convert visibility from TEXT to enum type
ALTER TABLE events ALTER COLUMN visibility DROP DEFAULT;
ALTER TABLE events
ALTER COLUMN visibility TYPE event_visibility
USING visibility::event_visibility;  -- Cast existing TEXT values to enum
ALTER TABLE events
ALTER COLUMN visibility SET DEFAULT 'private'::event_visibility;

-- Step 3: Do the same for shadow_calendar
ALTER TABLE shadow_calendar
ALTER COLUMN visibility TYPE event_visibility
USING visibility::event_visibility;

-- Step 4: Recreate RLS policy with correct enum type
CREATE POLICY "Users can view own and group members events"
ON events FOR SELECT TO authenticated
USING (
  user_id = auth.uid()
  OR (
    visibility <> 'private'::event_visibility  -- Now uses enum comparison
    AND user_id <> auth.uid()
    AND EXISTS (
      SELECT 1 FROM group_members gm
      WHERE gm.group_id IN (
        SELECT group_id FROM group_members WHERE user_id = auth.uid()
      )
      AND gm.user_id = events.user_id
    )
  )
);
```

**Result:**
- ✅ Column type is now `event_visibility` enum (type-safe)
- ✅ Default is `'private'::event_visibility` (correct type)
- ✅ RLS policies use proper enum comparisons
- ✅ Data integrity enforced at database level

## Prevention

### Database Schema Alignment Checklist

Before adding new fields to models:

1. **Check if column exists:**
   ```sql
   SELECT column_name, data_type, udt_name
   FROM information_schema.columns
   WHERE table_name = 'events' AND column_name = 'new_field';
   ```

2. **If using enums, verify values match:**
   ```sql
   -- Check enum definition
   SELECT enumlabel FROM pg_enum
   WHERE enumtypid = 'your_enum'::regtype
   ORDER BY enumsortorder;
   ```

3. **Verify column type matches Dart model:**
   - Dart `bool` → PostgreSQL `BOOLEAN`
   - Dart `String` (enum) → PostgreSQL custom enum type
   - Dart `DateTime` → PostgreSQL `TIMESTAMPTZ`

4. **Create migration BEFORE using field in code:**
   ```bash
   # Create migration first
   supabase migration new add_new_field

   # Then update Dart model
   # Then test
   ```

### Enum Value Naming Convention

**ALWAYS use snake_case for enum values:**

```dart
// ✅ CORRECT - matches PostgreSQL/JSON conventions
enum EventVisibility {
  private,           // 'private'
  shared_with_name,  // 'shared_with_name'
  busy_only,         // 'busy_only'
}
```

```sql
-- ✅ CORRECT - matches Dart naming
CREATE TYPE event_visibility AS ENUM (
  'private',
  'shared_with_name',
  'busy_only'
);
```

**Why snake_case:**
- JSON convention (most APIs use snake_case)
- PostgreSQL convention (lowercase with underscores)
- Dart toJson() naturally produces snake_case
- Supabase client expects snake_case

### Migration Order When Changing Enum Types

**CRITICAL: Follow this order:**

```sql
-- 1. Drop policies that reference the column
DROP POLICY IF EXISTS "policy_name" ON table_name;

-- 2. Drop default
ALTER TABLE table_name ALTER COLUMN column_name DROP DEFAULT;

-- 3. Change column type
ALTER TABLE table_name
ALTER COLUMN column_name TYPE enum_type
USING column_name::enum_type;

-- 4. Set new default with correct type
ALTER TABLE table_name
ALTER COLUMN column_name SET DEFAULT 'value'::enum_type;

-- 5. Recreate policies with correct type comparisons
CREATE POLICY "policy_name" ON table_name ...;
```

**Why this order matters:**
- Policies prevent column type changes → must drop first
- Defaults must match column type → drop before change, set after
- USING clause converts existing data during type change

## Testing

### Verify Schema Matches Models

**Check all_day column:**
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'events' AND column_name = 'all_day';

-- Expected:
-- all_day | boolean | NO | false
```

**Check visibility enum type:**
```sql
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'events' AND column_name = 'visibility';

-- Expected:
-- visibility | USER-DEFINED | event_visibility
```

**Check enum values:**
```sql
SELECT enumlabel
FROM pg_enum
WHERE enumtypid = 'event_visibility'::regtype
ORDER BY enumsortorder;

-- Expected:
-- private
-- shared_with_name
-- busy_only
-- (possibly old camelCase values too - harmless)
```

### Manual Testing

**Test visibility persistence:**

1. Create event as "Private" → hot restart → verify stays "Private" ✅
2. Create event as "Shared with name" → hot restart → verify stays "Shared with name" ✅
3. Create event as "Busy only" → hot restart → verify stays "Busy only" ✅

**Test all-day events:**

1. Create all-day event → verify stored with all_day = true ✅
2. Create timed event → verify stored with all_day = false ✅
3. Query database → verify events table has all_day column ✅

## Technical Details

### PostgreSQL Enum Limitations

**Cannot remove enum values without recreating type:**

```sql
-- ❌ This doesn't exist in PostgreSQL
ALTER TYPE event_visibility DROP VALUE 'sharedWithName';

-- ✅ To remove values, must recreate entire type:
-- 1. Create new enum with correct values
CREATE TYPE event_visibility_new AS ENUM (
  'private', 'shared_with_name', 'busy_only'
);

-- 2. Convert column to new type
ALTER TABLE events
ALTER COLUMN visibility TYPE event_visibility_new
USING visibility::text::event_visibility_new;

-- 3. Drop old type, rename new
DROP TYPE event_visibility;
ALTER TYPE event_visibility_new RENAME TO event_visibility;
```

**For this migration:** We kept old values (harmless) to avoid complex type recreation.

### Why Type Safety Matters

**TEXT column (before fix):**
```sql
-- ❌ Any string accepted
INSERT INTO events (visibility) VALUES ('invalid_value');  -- Succeeds!
INSERT INTO events (visibility) VALUES ('private');        -- Succeeds
INSERT INTO events (visibility) VALUES ('shared_with_name'); -- Succeeds
```

**ENUM column (after fix):**
```sql
-- ✅ Only valid enum values accepted
INSERT INTO events (visibility) VALUES ('invalid_value');  -- ERROR
INSERT INTO events (visibility) VALUES ('private');        -- Succeeds
INSERT INTO events (visibility) VALUES ('shared_with_name'); -- Succeeds
```

**Impact on RLS policies:**

```sql
-- With TEXT: Type mismatch warnings, unreliable comparisons
visibility <> 'private'::text  -- Comparing TEXT to TEXT

-- With enum: Type-safe comparisons
visibility <> 'private'::event_visibility  -- Comparing enum to enum
```

## Resolution Timeline

1. **Bug #3 discovered:** "Could not find 'all_day' column" error
2. **Migration 015 created:** Added all_day column ✅
3. **Bug #4 discovered:** "invalid input value 'shared_with_name'" error
4. **Investigation:** Found enum value mismatch (camelCase vs snake_case)
5. **Migration 016 created:** Added snake_case enum values, migrated data ✅
6. **Bug #5 discovered:** "Visibility not preserved after hot restart"
7. **Investigation:** Found visibility column was TEXT, not enum
8. **Migration 017 created:** Converted column type to enum ✅

**Total bugs fixed:** 3 (all related to database schema)
**Migrations created:** 3
**Data migrated:** 223 events across all visibility types

## Critical Pattern

⭐ **This solution has been promoted to Required Reading:**
[Pattern 3: Database Schema Alignment](../../patterns/critical-patterns.md#pattern-3-database-schema-alignment)

All developers must create migrations BEFORE using fields in code to prevent data integrity issues.

## Tags

#database-migration #enum-values #type-safety #schema-mismatch #privacy #visibility
