# Supabase Setup Guide for LockItIn

This guide walks you through setting up your Supabase backend for the LockItIn app.

---

## Step 1: Create a Supabase Project

1. Go to [https://app.supabase.com/](https://app.supabase.com/)
2. Sign in or create a free account
3. Click **"New Project"**
4. Fill in the details:
   - **Name**: `lockitin` (or any name you prefer)
   - **Database Password**: Generate a strong password (save it somewhere safe!)
   - **Region**: Choose the closest region to you
   - **Pricing Plan**: Free tier is perfect for development
5. Click **"Create new project"**
6. Wait 2-3 minutes for Supabase to provision your database

---

## Step 2: Get Your API Credentials

1. Once the project is created, go to **Settings** (gear icon in sidebar)
2. Click **API** in the left menu
3. You'll see two important values:

   **Project URL**:
   ```
   https://your-project-id.supabase.co
   ```

   **anon public key** (under "Project API keys"):
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

4. **Copy both values** - you'll need them in the next step

---

## Step 3: Configure the Flutter App

1. Open this file in your code editor:
   ```
   lib/core/config/supabase_config.dart
   ```

2. Replace the placeholder values:
   ```dart
   class SupabaseConfig {
     // Replace with your Project URL
     static const String supabaseUrl = 'https://your-project-id.supabase.co';

     // Replace with your anon public key
     static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

     static const bool enableDebugLogging = true;
   }
   ```

3. **Save the file**

---

## Step 4: Install Flutter Dependencies

Run this command in your terminal:

```bash
cd application/lockitin_app
flutter pub get
```

This will download all the packages specified in `pubspec.yaml`, including `supabase_flutter`.

---

## Step 5: Create Database Tables

You'll create the database schema in **Sprint 1, Day 4** when implementing authentication.

For now, Supabase automatically creates an `auth.users` table for authentication.

### Initial Tables (will be created during development):

1. **users** - User profiles (Day 4)
2. **events** - Calendar events (Day 8)
3. **friendships** - Friend connections (Day 15)
4. **groups** & **group_members** - Groups (Day 17)
5. **shadow_calendar** - Privacy-first availability (Day 22)
6. **event_proposals**, **proposal_time_options**, **proposal_votes** - Voting system (Day 29)

---

## Step 6: Test the Connection

1. Run the Flutter app:
   ```bash
   flutter run
   ```

2. Choose your Android emulator when prompted

3. The app should:
   - Show a splash screen
   - Initialize Supabase (check console logs)
   - Navigate to the Login screen

4. **Check the console logs** for:
   ```
   🔵 LockItIn [Main] ℹ️  Initializing Supabase...
   🔵 LockItIn [Main] ✅ Supabase initialized successfully
   ```

If you see ❌ errors, double-check your `supabase_config.dart` credentials.

---

## Step 7: Enable Row Level Security (RLS)

**Important**: You'll set up RLS policies as you build features, but here's a preview:

Supabase uses Row Level Security to enforce privacy at the database level.

Example RLS policy (you'll create these later):
```sql
-- Only users can see their own events
CREATE POLICY "Users can view own events"
  ON events
  FOR SELECT
  USING (auth.uid() = user_id);
```

---

## Common Issues & Troubleshooting

### "Failed to initialize Supabase"
- ✅ Check that `supabaseUrl` and `supabaseAnonKey` are correctly copied
- ✅ Make sure there are no extra spaces or quotes
- ✅ Verify your Supabase project is active (not paused)

### "Invalid API key"
- ✅ You must use the **anon public** key, not the service_role key
- ✅ The anon key should start with `eyJ...`

### "Network error"
- ✅ Check your internet connection
- ✅ If using an emulator, ensure it has network access
- ✅ Try restarting the emulator

### Flutter package errors
- ✅ Run `flutter clean` then `flutter pub get`
- ✅ Check that you're using Flutter 3.10.3+

---

## Next Steps

Once Supabase is configured and the app runs successfully:

1. ✅ **You're ready to start Sprint 1, Day 1!**
2. Follow the GitHub issues in order (#2, #3, #4, etc.)
3. Create database tables as you progress through the sprints

---

## Useful Supabase Resources

- **Supabase Dashboard**: [https://app.supabase.com/](https://app.supabase.com/)
- **Table Editor**: Create/edit tables in the Supabase dashboard
- **SQL Editor**: Run raw SQL queries
- **Auth Users**: View registered users
- **API Docs**: Auto-generated API documentation for your project
- **Flutter Docs**: [https://supabase.com/docs/reference/dart/introduction](https://supabase.com/docs/reference/dart/introduction)

---

## Security Notes

⚠️ **Important**:
- The `anon public` key is **safe** to use in client-side code
- **NEVER** commit the `service_role` key to version control
- The `supabase_config.dart` file is already in `.gitignore` (you should add it if not)
- Use Row Level Security (RLS) to enforce permissions at the database level

---

## Questions?

If you encounter issues:
1. Check the Flutter console logs for detailed error messages
2. Verify your Supabase dashboard shows the project as "Active"
3. Review the `FLUTTER_SUPABASE_INTEGRATION_GUIDE.md` for detailed examples

Ready to build! 🚀
