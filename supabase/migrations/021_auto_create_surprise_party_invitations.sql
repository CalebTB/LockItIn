-- Migration 021: Auto-create invitations for surprise party events
-- Trigger automatically creates invitations for all group members (except guest of honor)
-- when a surprise party event is created or updated

-- Function to auto-create invitations
CREATE OR REPLACE FUNCTION auto_create_surprise_party_invitations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guest_of_honor_id UUID;
BEGIN
  -- Only run for surprise party events
  IF NEW.template_data->>'type' = 'surprise_party' THEN
    v_guest_of_honor_id := (NEW.template_data->>'guestOfHonorId')::UUID;

    -- Create invitations for all group members except guest of honor
    INSERT INTO event_invitations (event_id, user_id, rsvp_status)
    SELECT
      NEW.id,
      gm.user_id,
      'pending'::rsvp_status
    FROM group_members gm
    WHERE gm.group_id = NEW.group_id
      AND gm.user_id != v_guest_of_honor_id  -- Exclude guest of honor
    ON CONFLICT (event_id, user_id) DO NOTHING;  -- Skip if invitation already exists
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger on events table
DROP TRIGGER IF EXISTS trigger_auto_create_surprise_party_invitations ON events;

CREATE TRIGGER trigger_auto_create_surprise_party_invitations
  AFTER INSERT OR UPDATE OF template_data ON events
  FOR EACH ROW
  EXECUTE FUNCTION auto_create_surprise_party_invitations();

COMMENT ON FUNCTION auto_create_surprise_party_invitations() IS
'Automatically creates event_invitations records for all group members (except guest of honor) when a surprise party event is created or the guest of honor is changed';
