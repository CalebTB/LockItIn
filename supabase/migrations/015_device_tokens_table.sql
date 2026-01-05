-- Migration: Device Tokens for Push Notifications
-- Description: Store device tokens for APNs (iOS) and FCM (Android) to enable push notifications
-- Created: 2026-01-04

-- =====================================================
-- Device Tokens Table
-- =====================================================

CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(512) NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios')),
    device_model VARCHAR(100),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    -- One active token per user per device
    UNIQUE(user_id, token)
);

-- =====================================================
-- Indexes
-- =====================================================

CREATE INDEX idx_device_tokens_user_active
    ON device_tokens(user_id, is_active)
    WHERE is_active = true;

CREATE INDEX idx_device_tokens_user
    ON device_tokens(user_id);

CREATE INDEX idx_device_tokens_token
    ON device_tokens(token);

-- =====================================================
-- Row Level Security (RLS)
-- =====================================================

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own device tokens"
    ON device_tokens FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own device tokens"
    ON device_tokens FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device tokens"
    ON device_tokens FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device tokens"
    ON device_tokens FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- =====================================================
-- Triggers
-- =====================================================

-- Update updated_at timestamp on row update
CREATE TRIGGER device_tokens_updated_at
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- RPC Functions
-- =====================================================

-- Upsert device token (register or refresh token)
CREATE OR REPLACE FUNCTION upsert_device_token(
    p_token VARCHAR,
    p_platform VARCHAR,
    p_device_model VARCHAR DEFAULT NULL,
    p_os_version VARCHAR DEFAULT NULL,
    p_app_version VARCHAR DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_token_id UUID;
BEGIN
    -- Deactivate any existing tokens for this user/device combination
    UPDATE device_tokens
    SET is_active = false,
        updated_at = now()
    WHERE user_id = auth.uid()
      AND token = p_token;

    -- Insert or update token
    INSERT INTO device_tokens (
        user_id,
        token,
        platform,
        device_model,
        os_version,
        app_version,
        is_active,
        last_used_at
    ) VALUES (
        auth.uid(),
        p_token,
        p_platform,
        p_device_model,
        p_os_version,
        p_app_version,
        true,
        now()
    )
    ON CONFLICT (user_id, token)
    DO UPDATE SET
        is_active = true,
        last_used_at = now(),
        device_model = COALESCE(EXCLUDED.device_model, device_tokens.device_model),
        os_version = COALESCE(EXCLUDED.os_version, device_tokens.os_version),
        app_version = COALESCE(EXCLUDED.app_version, device_tokens.app_version),
        updated_at = now()
    RETURNING id INTO v_token_id;

    RETURN v_token_id;
END;
$$;

-- Deactivate device token (logout, token refresh)
CREATE OR REPLACE FUNCTION deactivate_device_token(p_token VARCHAR)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE device_tokens
    SET is_active = false,
        updated_at = now()
    WHERE user_id = auth.uid()
      AND token = p_token;
END;
$$;

-- Get active device tokens for a user (for server-side notification sending)
-- This function bypasses RLS and is intended for use by Edge Functions
CREATE OR REPLACE FUNCTION get_user_device_tokens(p_user_id UUID)
RETURNS TABLE (
    token VARCHAR,
    platform VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT dt.token, dt.platform
    FROM device_tokens dt
    WHERE dt.user_id = p_user_id
      AND dt.is_active = true;
END;
$$;

-- Get all device tokens for multiple users (batch notification sending)
CREATE OR REPLACE FUNCTION get_users_device_tokens(p_user_ids UUID[])
RETURNS TABLE (
    user_id UUID,
    token VARCHAR,
    platform VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT dt.user_id, dt.token, dt.platform
    FROM device_tokens dt
    WHERE dt.user_id = ANY(p_user_ids)
      AND dt.is_active = true;
END;
$$;

-- =====================================================
-- Comments
-- =====================================================

COMMENT ON TABLE device_tokens IS 'Stores device push notification tokens for APNs (iOS) and FCM (Android)';
COMMENT ON COLUMN device_tokens.token IS 'Device-specific push notification token from APNs or FCM';
COMMENT ON COLUMN device_tokens.platform IS 'Platform: android (FCM) or ios (APNs)';
COMMENT ON COLUMN device_tokens.is_active IS 'Whether this token is currently valid and should receive notifications';
COMMENT ON FUNCTION upsert_device_token IS 'Register or update a device token for the current user';
COMMENT ON FUNCTION deactivate_device_token IS 'Deactivate a device token (e.g., on logout)';
COMMENT ON FUNCTION get_user_device_tokens IS 'Get all active device tokens for a user (used by Edge Functions to send notifications)';
COMMENT ON FUNCTION get_users_device_tokens IS 'Get all active device tokens for multiple users (batch notification sending)';
