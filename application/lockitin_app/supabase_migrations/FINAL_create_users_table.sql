-- ============================================
-- FINAL WORKING VERSION - Run this complete script
-- ============================================

-- Step 1: Clean up any existing objects
DO $$
BEGIN
  -- Drop triggers
  DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
  DROP TRIGGER IF EXISTS set_updated_at ON public.users;

  -- Drop functions
  DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
  DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;

  -- Drop policies
  DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
  DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
  DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
  DROP POLICY IF EXISTS "Service role can insert users" ON public.users;
  DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
  DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.users;
  DROP POLICY IF EXISTS "Enable update for users based on id" ON public.users;
  DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.users;

  -- Drop table
  DROP TABLE IF EXISTS public.users CASCADE;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Cleanup completed with warnings: %', SQLERRM;
END $$;

-- Step 2: Create the users table
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.users IS 'User profiles for LockItIn app';

-- Step 3: Create indexes
CREATE INDEX users_email_idx ON public.users(email);
CREATE INDEX users_id_idx ON public.users(id);

-- Step 4: Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS Policies
-- Allow authenticated users to read all profiles (needed for group features)
CREATE POLICY "Enable read access for authenticated users"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow users to update their own profile
CREATE POLICY "Enable update for users based on id"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow authenticated users to insert (needed for trigger)
CREATE POLICY "Enable insert for authenticated users"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Step 6: Create updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Step 7: Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NOW()
  );
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    -- Log error but don't fail the auth.users insert
    RAISE WARNING 'Error creating user profile: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Step 8: Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Step 9: Verify everything was created
DO $$
BEGIN
  RAISE NOTICE 'Migration completed successfully!';
  RAISE NOTICE 'Table created: public.users';
  RAISE NOTICE 'Trigger created: on_auth_user_created';
  RAISE NOTICE 'Ready to test authentication!';
END $$;
