# Supabase Database Setup

This directory contains SQL scripts for setting up the LockItIn database schema and security policies.

## Quick Start

### 0. Create Database Schema (First Time Only)

If you haven't set up your database tables yet:

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Navigate to **SQL Editor** (left sidebar)
4. Open `schema.sql` from this directory
5. Copy the entire contents
6. Paste into the SQL Editor
7. Click **Run** (or press Cmd+Enter)

This creates:
- ✅ `users` table with auto-profile creation trigger
- ✅ `events` table with validation constraints
- ✅ Performance indexes
- ✅ Updated_at triggers

### 1. Apply Row Level Security Policies

**IMPORTANT:** You must apply these policies immediately to ensure user data isolation!

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Navigate to **SQL Editor** (left sidebar)
4. Open `rls_policies.sql` from this directory
5. Copy the entire contents
6. Paste into the SQL Editor
7. Click **Run** (or press Cmd+Enter)

### 2. Verify RLS is Enabled

After running the policies, verify they're active:

1. In Supabase Dashboard, go to **Database** → **Tables**
2. Click on the `events` table
3. Check that RLS is **enabled** (green shield icon)
4. Click **View Policies** to see all policies

Expected policies on `events` table:
- ✅ Users can view own events (SELECT)
- ✅ Users can create own events (INSERT)
- ✅ Users can update own events (UPDATE)
- ✅ Users can delete own events (DELETE)

### 3. Test Security

You can test the policies are working:

```sql
-- This should return only YOUR events (not all events)
SELECT * FROM events;

-- This should fail (trying to view another user's events)
SELECT * FROM events WHERE user_id != auth.uid();
```

## Database Schema

### Current Tables

#### `users` table
Stores user profiles and settings.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE
);
```

#### `events` table
Stores calendar events with privacy settings.

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE NOT NULL,
  location TEXT,
  visibility TEXT NOT NULL CHECK (visibility IN ('private', 'sharedWithName', 'busyOnly')),
  category TEXT,
  native_calendar_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE
);

-- Index for faster queries
CREATE INDEX idx_events_user_id ON events(user_id);
CREATE INDEX idx_events_start_time ON events(start_time);
```

## How RLS Works

Row Level Security (RLS) is a PostgreSQL feature that Supabase uses to enforce data access rules at the database level:

1. **Every query is scoped to the authenticated user**
   - When you query `SELECT * FROM events`, Supabase automatically adds `WHERE user_id = auth.uid()`
   - Even if malicious code tries to access other users' data, the database blocks it

2. **auth.uid() is secure**
   - Supabase extracts the user ID from the JWT token
   - This cannot be spoofed or manipulated by the client

3. **Defense in depth**
   - Even if there's a bug in your Flutter app, the database enforces isolation
   - Prevents accidental data leaks

## Troubleshooting

### "row-level security policy for table prevents this"

This error means RLS is working! It occurs when you try to:
- Access another user's data
- Insert data with someone else's user_id
- Update/delete events you don't own

**This is expected behavior** - it means your security is working.

### Events not showing up after login

Check:
1. Is the user authenticated? `SupabaseClientManager.isAuthenticated`
2. Is the user ID being set correctly when creating events?
3. Are you filtering events by the correct user ID?

Run this query in SQL Editor to see all events for your user:

```sql
SELECT * FROM events WHERE user_id = auth.uid();
```

### Cannot create events

Ensure:
1. User is authenticated (not anonymous)
2. `user_id` in EventModel matches `auth.uid()`
3. RLS policies are applied

## Future Database Tables

These tables will be added in future sprints:

- `groups` - Friend groups for event coordination
- `group_members` - Many-to-many relationship
- `event_proposals` - Proposed event times
- `proposal_time_options` - Time options for proposals
- `proposal_votes` - Voting on time options
- `calendar_sharing` - Privacy settings per group
- `notifications` - In-app notification queue

Each table will have its own RLS policies to maintain security.

## Maintenance

### Adding New Policies

When adding new tables:

1. Always enable RLS: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;`
2. Create policies for all operations (SELECT, INSERT, UPDATE, DELETE)
3. Test policies thoroughly
4. Document in this README

### Updating Policies

To modify an existing policy:

```sql
-- Drop the old policy
DROP POLICY "policy_name" ON table_name;

-- Create the new policy
CREATE POLICY "policy_name" ON table_name
FOR SELECT
USING (your_condition);
```

## Security Best Practices

1. ✅ **Always use auth.uid()** - Never trust user_id from the client
2. ✅ **Enable RLS on all tables** - No exceptions
3. ✅ **Test policies** - Verify users can't access each other's data
4. ✅ **Use WITH CHECK** - Ensure INSERT/UPDATE can't bypass RLS
5. ✅ **Audit regularly** - Review policies as features evolve

---

**Last Updated:** December 26, 2024
**Schema Version:** 1.0.0 (MVP - Events only)
