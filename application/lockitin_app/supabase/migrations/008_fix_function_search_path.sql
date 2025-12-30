-- ============================================================================
-- Migration 008: Fix Function Search Path Security Issue
-- ============================================================================
-- Fixes security warning: "Function has a role mutable search_path"
-- Solution: Add SET search_path = public to all SECURITY DEFINER functions
--
-- This prevents search_path injection attacks where a malicious user could
-- create functions in their own schema that shadow public schema functions.
--
-- Created: December 30, 2025
-- Issue: Supabase Database Advisor - Security
-- ============================================================================

-- update_updated_at_column (trigger function - not SECURITY DEFINER, but good practice)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$;

-- handle_updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$;

-- handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
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
    RAISE WARNING 'Error creating user profile: %', SQLERRM;
    RETURN NEW;
END;
$function$;

-- create_user_profile
CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  INSERT INTO public.users (id, email, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name'
  );
  RETURN NEW;
END;
$function$;

-- are_friends
CREATE OR REPLACE FUNCTION public.are_friends(user1_uuid uuid, user2_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM friendships
    WHERE ((user_id = user1_uuid AND friend_id = user2_uuid)
        OR (user_id = user2_uuid AND friend_id = user1_uuid))
      AND status = 'accepted'
  );
END;
$function$;

-- auth_is_group_member
CREATE OR REPLACE FUNCTION public.auth_is_group_member(group_uuid uuid, user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid AND user_id = user_uuid
  );
END;
$function$;

-- auth_has_group_role
CREATE OR REPLACE FUNCTION public.auth_has_group_role(group_uuid uuid, user_uuid uuid, required_roles group_member_role[])
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid
    AND user_id = user_uuid
    AND role = ANY(required_roles)
  );
END;
$function$;

-- is_group_member
CREATE OR REPLACE FUNCTION public.is_group_member(group_uuid uuid, user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid AND user_id = user_uuid
  );
END;
$function$;

-- get_friends
CREATE OR REPLACE FUNCTION public.get_friends(user_uuid uuid)
RETURNS TABLE(friendship_id uuid, friend_id uuid, full_name text, email text, avatar_url text, friendship_since timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    f.id as friendship_id,
    CASE
      WHEN f.user_id = user_uuid THEN f.friend_id
      ELSE f.user_id
    END as friend_id,
    u.full_name,
    u.email,
    u.avatar_url,
    f.accepted_at as friendship_since
  FROM friendships f
  JOIN users u ON u.id = CASE
    WHEN f.user_id = user_uuid THEN f.friend_id
    ELSE f.user_id
  END
  WHERE (f.user_id = user_uuid OR f.friend_id = user_uuid)
    AND f.status = 'accepted';
END;
$function$;

-- get_pending_requests
CREATE OR REPLACE FUNCTION public.get_pending_requests(user_uuid uuid)
RETURNS TABLE(request_id uuid, requester_id uuid, full_name text, email text, avatar_url text, requested_at timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    f.id as request_id,
    f.user_id as requester_id,
    u.full_name,
    u.email,
    u.avatar_url,
    f.created_at as requested_at
  FROM friendships f
  JOIN users u ON u.id = f.user_id
  WHERE f.friend_id = user_uuid
    AND f.status = 'pending';
END;
$function$;

-- get_sent_requests
CREATE OR REPLACE FUNCTION public.get_sent_requests(user_uuid uuid)
RETURNS TABLE(request_id uuid, recipient_id uuid, full_name text, email text, avatar_url text, sent_at timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    f.id as request_id,
    f.friend_id as recipient_id,
    u.full_name,
    u.email,
    u.avatar_url,
    f.created_at as sent_at
  FROM friendships f
  JOIN users u ON u.id = f.friend_id
  WHERE f.user_id = user_uuid
    AND f.status = 'pending';
END;
$function$;

-- get_group_members
CREATE OR REPLACE FUNCTION public.get_group_members(group_uuid uuid, user_uuid uuid)
RETURNS TABLE(member_id uuid, user_id uuid, full_name text, email text, avatar_url text, role group_member_role, joined_at timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- First verify the requesting user is a member of this group
  IF NOT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = group_uuid AND group_members.user_id = user_uuid
  ) THEN
    RAISE EXCEPTION 'Access denied: User is not a member of this group';
  END IF;

  RETURN QUERY
  SELECT
    gm.id as member_id,
    gm.user_id,
    u.full_name,
    u.email,
    u.avatar_url,
    gm.role,
    gm.joined_at
  FROM group_members gm
  JOIN users u ON u.id = gm.user_id
  WHERE gm.group_id = group_uuid
  ORDER BY
    CASE gm.role
      WHEN 'owner' THEN 1
      WHEN 'co_owner' THEN 2
      WHEN 'admin' THEN 3
      ELSE 4
    END,
    gm.joined_at;
END;
$function$;

-- get_group_role
CREATE OR REPLACE FUNCTION public.get_group_role(group_uuid uuid, user_uuid uuid)
RETURNS group_member_role
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  user_role group_member_role;
BEGIN
  SELECT role INTO user_role
  FROM group_members
  WHERE group_id = group_uuid AND user_id = user_uuid;

  RETURN user_role;
END;
$function$;

-- get_pending_group_invites
CREATE OR REPLACE FUNCTION public.get_pending_group_invites(user_uuid uuid)
RETURNS TABLE(invite_id uuid, group_id uuid, group_name character varying, group_emoji character varying, invited_by uuid, inviter_name text, invited_at timestamp with time zone)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    gi.id as invite_id,
    gi.group_id,
    g.name as group_name,
    g.emoji as group_emoji,
    gi.invited_by,
    u.full_name as inviter_name,
    gi.created_at as invited_at
  FROM group_invites gi
  JOIN groups g ON g.id = gi.group_id
  JOIN users u ON u.id = gi.invited_by
  WHERE gi.invited_user_id = user_uuid
  ORDER BY gi.created_at DESC;
END;
$function$;

-- get_user_groups (SQL function - different syntax)
CREATE OR REPLACE FUNCTION public.get_user_groups(user_uuid uuid)
RETURNS TABLE(group_id uuid, name text, emoji text, created_by uuid, created_at timestamp with time zone, member_count bigint, members_can_invite boolean)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT
    g.id AS group_id,
    g.name,
    g.emoji,
    g.created_by,
    g.created_at,
    COUNT(gm2.id) AS member_count,
    g.members_can_invite
  FROM groups g
  INNER JOIN group_members gm ON g.id = gm.group_id AND gm.user_id = user_uuid
  LEFT JOIN group_members gm2 ON g.id = gm2.group_id
  GROUP BY g.id, g.name, g.emoji, g.created_by, g.created_at, g.members_can_invite
  ORDER BY g.created_at DESC;
$function$;

-- transfer_group_ownership
CREATE OR REPLACE FUNCTION public.transfer_group_ownership(p_group_id uuid, p_new_owner_id uuid, p_current_owner_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_current_role group_member_role;
  v_new_owner_exists BOOLEAN;
BEGIN
  -- Verify current user is the owner
  SELECT role INTO v_current_role
  FROM group_members
  WHERE group_id = p_group_id AND user_id = p_current_owner_id;

  IF v_current_role IS NULL OR v_current_role != 'owner' THEN
    RAISE EXCEPTION 'Only the owner can transfer ownership';
  END IF;

  -- Verify new owner is a member of the group
  SELECT EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = p_group_id AND user_id = p_new_owner_id
  ) INTO v_new_owner_exists;

  IF NOT v_new_owner_exists THEN
    RAISE EXCEPTION 'New owner must be a member of the group';
  END IF;

  -- Atomic update: promote new owner
  UPDATE group_members
  SET role = 'owner'
  WHERE group_id = p_group_id AND user_id = p_new_owner_id;

  -- Atomic update: demote current owner
  UPDATE group_members
  SET role = 'member'
  WHERE group_id = p_group_id AND user_id = p_current_owner_id;

  RETURN TRUE;

EXCEPTION WHEN OTHERS THEN
  -- Transaction automatically rolls back on exception
  RAISE;
END;
$function$;

-- sync_event_to_shadow_calendar (already has SET search_path in shadow_calendar_schema.sql)
-- Just recreate to ensure consistency
CREATE OR REPLACE FUNCTION public.sync_event_to_shadow_calendar()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- Handle INSERT
  IF TG_OP = 'INSERT' THEN
    -- Only sync non-private events
    IF NEW.visibility != 'private'::event_visibility THEN
      INSERT INTO shadow_calendar (
        event_id,
        user_id,
        start_time,
        end_time,
        visibility,
        event_title
      ) VALUES (
        NEW.id,
        NEW.user_id,
        NEW.start_time,
        NEW.end_time,
        NEW.visibility::event_visibility,
        CASE WHEN NEW.visibility = 'sharedWithName' THEN NEW.title ELSE NULL END
      );
    END IF;
    RETURN NEW;
  END IF;

  -- Handle UPDATE
  IF TG_OP = 'UPDATE' THEN
    -- Case 1: Event changed TO private - remove from shadow calendar
    IF NEW.visibility = 'private' AND OLD.visibility != 'private' THEN
      DELETE FROM shadow_calendar WHERE event_id = NEW.id;
      RETURN NEW;
    END IF;

    -- Case 2: Event changed FROM private - add to shadow calendar
    IF NEW.visibility != 'private' AND OLD.visibility = 'private' THEN
      INSERT INTO shadow_calendar (
        event_id,
        user_id,
        start_time,
        end_time,
        visibility,
        event_title
      ) VALUES (
        NEW.id,
        NEW.user_id,
        NEW.start_time,
        NEW.end_time,
        NEW.visibility::event_visibility,
        CASE WHEN NEW.visibility = 'sharedWithName' THEN NEW.title ELSE NULL END
      );
      RETURN NEW;
    END IF;

    -- Case 3: Event is non-private and something changed - update shadow calendar
    IF NEW.visibility != 'private' THEN
      UPDATE shadow_calendar
      SET
        start_time = NEW.start_time,
        end_time = NEW.end_time,
        visibility = NEW.visibility::event_visibility,
        event_title = CASE WHEN NEW.visibility = 'sharedWithName' THEN NEW.title ELSE NULL END,
        updated_at = now()
      WHERE event_id = NEW.id;
    END IF;

    RETURN NEW;
  END IF;

  -- Handle DELETE (CASCADE handles this, but explicit for clarity)
  IF TG_OP = 'DELETE' THEN
    DELETE FROM shadow_calendar WHERE event_id = OLD.id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$function$;

-- get_group_shadow_calendar (already has SET search_path)
-- Recreate to ensure consistency
CREATE OR REPLACE FUNCTION public.get_group_shadow_calendar(
  p_user_ids UUID[],
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_end_date TIMESTAMP WITH TIME ZONE
)
RETURNS TABLE (
  user_id UUID,
  start_time TIMESTAMP WITH TIME ZONE,
  end_time TIMESTAMP WITH TIME ZONE,
  visibility TEXT,
  event_title TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- Verify caller is a group member with at least one of the requested users
  IF NOT EXISTS (
    SELECT 1 FROM group_members gm1
    JOIN group_members gm2 ON gm1.group_id = gm2.group_id
    WHERE gm1.user_id = auth.uid()
    AND gm2.user_id = ANY(p_user_ids)
  ) AND NOT (auth.uid() = ANY(p_user_ids)) THEN
    RAISE EXCEPTION 'Access denied: You must be in a group with the requested users';
  END IF;

  RETURN QUERY
  SELECT
    sc.user_id,
    sc.start_time,
    sc.end_time,
    sc.visibility::TEXT,
    sc.event_title
  FROM shadow_calendar sc
  WHERE sc.user_id = ANY(p_user_ids)
    AND sc.start_time < p_end_date
    AND sc.end_time > p_start_date
  ORDER BY sc.user_id, sc.start_time;
END;
$function$;

-- Drop test function if it exists (it's not needed in production)
DROP FUNCTION IF EXISTS public.test_auth_uid();

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this query to verify all functions now have search_path set:
-- SELECT proname, prosecdef, proconfig
-- FROM pg_proc
-- WHERE pronamespace = 'public'::regnamespace
-- AND proname IN ('update_updated_at_column', 'handle_updated_at', 'are_friends', ...)
-- ORDER BY proname;
