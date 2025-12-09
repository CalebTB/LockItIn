# Supabase Database Migrations

This folder contains SQL migration files for setting up your Supabase database.

## How to Run Migrations

### Option 1: Supabase Dashboard (Recommended for beginners)

1. Go to your Supabase project: https://app.supabase.com/
2. Click on **SQL Editor** in the left sidebar
3. Click **"New query"**
4. Copy and paste the contents of a migration file (e.g., `01_create_users_table.sql`)
5. Click **"Run"** at the bottom right
6. Check for success message

### Option 2: Supabase CLI (Advanced)

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_ID

# Run migration
supabase db push
```

## Migration Files

### `01_create_users_table.sql`
**Purpose**: Creates the `users` table for storing user profile information

**What it does**:
- Creates `users` table with columns: id, email, full_name, avatar_url, bio, created_at, updated_at
- Links to `auth.users` table (Supabase's built-in auth table)
- Enables Row Level Security (RLS)
- Creates RLS policies:
  - Users can view their own profile
  - Users can update their own profile
  - Users can insert their own profile during signup
- Creates index on email for faster lookups
- Creates trigger to auto-update `updated_at` timestamp
- Grants proper permissions

**When to run**: Before testing authentication (Day 3)

## Migration Order

Run migrations in numerical order:
1. `01_create_users_table.sql` ← **Run this now!**
2. `02_create_events_table.sql` (Day 8 - Calendar integration)
3. `03_create_friendships_table.sql` (Day 15 - Friend system)
4. And so on...

## Troubleshooting

### "relation already exists"
The table was already created. Safe to ignore or drop and recreate:
```sql
DROP TABLE IF EXISTS public.users CASCADE;
-- Then run the migration again
```

### "permission denied"
Make sure you're logged into the correct Supabase project.

### "syntax error"
Copy the entire file contents, don't modify the SQL.

---

**Next Step**: After running `01_create_users_table.sql`, you're ready to test authentication in your Flutter app!
