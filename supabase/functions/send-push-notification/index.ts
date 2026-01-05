// Supabase Edge Function: send-push-notification
// Sends push notifications to iOS (APNs) and Android (FCM) devices
// Invoked by: Database triggers, manual RPC calls, scheduled jobs

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// =====================================================
// Types
// =====================================================

interface NotificationPayload {
  user_ids: string[];  // Array of user IDs to notify
  title: string;
  body: string;
  data?: Record<string, any>;  // Custom data (proposal_id, group_id, etc.)
  priority?: 'high' | 'normal';
  badge_increment?: number;  // iOS badge count increment
}

interface DeviceToken {
  user_id: string;
  token: string;
  platform: 'ios' | 'android';
}

interface NotificationResult {
  success: boolean;
  platform: string;
  token: string;
  error?: string;
}

// =====================================================
// Configuration
// =====================================================

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// APNs Configuration (iOS)
// TODO: Set these in Supabase Dashboard → Edge Functions → Secrets
const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID');  // e.g., "ABC123DEFG"
const APNS_TEAM_ID = Deno.env.get('APNS_TEAM_ID');  // e.g., "DEF123GHIJ"
const APNS_TOPIC = Deno.env.get('APNS_TOPIC');  // e.g., "com.lockit.app"
const APNS_KEY_P8 = Deno.env.get('APNS_KEY_P8');  // .p8 private key content
const APNS_ENVIRONMENT = Deno.env.get('APNS_ENVIRONMENT') || 'sandbox';  // 'sandbox' or 'production'

// FCM Configuration (Android)
// TODO: Set these in Supabase Dashboard → Edge Functions → Secrets
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY');  // Firebase Server Key

// =====================================================
// APNs Helper Functions
// =====================================================

async function sendToAPNs(
  token: string,
  title: string,
  body: string,
  data: Record<string, any> = {},
  priority: 'high' | 'normal' = 'high',
  badgeIncrement: number = 1
): Promise<{ success: boolean; error?: string }> {
  if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_TOPIC || !APNS_KEY_P8) {
    return { success: false, error: 'APNs credentials not configured' };
  }

  try {
    // Generate JWT for APNs authentication
    const jwt = await generateAPNsJWT();

    // APNs endpoint
    const apnsEndpoint = APNS_ENVIRONMENT === 'production'
      ? 'https://api.push.apple.com'
      : 'https://api.sandbox.push.apple.com';

    // APNs payload
    const payload = {
      aps: {
        alert: {
          title: title,
          body: body,
        },
        badge: badgeIncrement,  // Increment badge count
        sound: 'default',
        'mutable-content': 1,  // Enable notification service extension
      },
      data: data,  // Custom data for deep linking
    };

    // Send to APNs
    const response = await fetch(`${apnsEndpoint}/3/device/${token}`, {
      method: 'POST',
      headers: {
        'authorization': `bearer ${jwt}`,
        'apns-topic': APNS_TOPIC,
        'apns-priority': priority === 'high' ? '10' : '5',
        'apns-push-type': 'alert',
      },
      body: JSON.stringify(payload),
    });

    if (response.ok) {
      return { success: true };
    } else {
      const errorBody = await response.text();
      return { success: false, error: `APNs error: ${response.status} ${errorBody}` };
    }
  } catch (error) {
    return { success: false, error: `APNs exception: ${error.message}` };
  }
}

// Generate JWT for APNs authentication
async function generateAPNsJWT(): Promise<string> {
  // TODO: Implement JWT generation using APNS_KEY_P8
  // For now, this is a placeholder
  // In production, use a JWT library like jose or implement ES256 signing

  // Pseudo-code:
  // 1. Create header: { alg: "ES256", kid: APNS_KEY_ID }
  // 2. Create payload: { iss: APNS_TEAM_ID, iat: now() }
  // 3. Sign with APNS_KEY_P8 private key
  // 4. Return base64url(header).base64url(payload).base64url(signature)

  throw new Error('APNs JWT generation not implemented yet');
}

// =====================================================
// FCM Helper Functions
// =====================================================

async function sendToFCM(
  token: string,
  title: string,
  body: string,
  data: Record<string, any> = {},
  priority: 'high' | 'normal' = 'high'
): Promise<{ success: boolean; error?: string }> {
  if (!FCM_SERVER_KEY) {
    return { success: false, error: 'FCM credentials not configured' };
  }

  try {
    // FCM endpoint
    const fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

    // FCM payload
    const payload = {
      to: token,
      priority: priority,
      notification: {
        title: title,
        body: body,
        sound: 'default',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      data: data,  // Custom data for deep linking
    };

    // Send to FCM
    const response = await fetch(fcmEndpoint, {
      method: 'POST',
      headers: {
        'Authorization': `key=${FCM_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    if (response.ok) {
      const result = await response.json();
      if (result.success === 1) {
        return { success: true };
      } else {
        return { success: false, error: `FCM error: ${JSON.stringify(result)}` };
      }
    } else {
      const errorBody = await response.text();
      return { success: false, error: `FCM HTTP error: ${response.status} ${errorBody}` };
    }
  } catch (error) {
    return { success: false, error: `FCM exception: ${error.message}` };
  }
}

// =====================================================
// Main Handler
// =====================================================

serve(async (req: Request) => {
  try {
    // Parse request body
    const payload: NotificationPayload = await req.json();

    // Validate payload
    if (!payload.user_ids || !Array.isArray(payload.user_ids) || payload.user_ids.length === 0) {
      return new Response(
        JSON.stringify({ error: 'user_ids array is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!payload.title || !payload.body) {
      return new Response(
        JSON.stringify({ error: 'title and body are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get device tokens for all target users
    const { data: deviceTokens, error: dbError } = await supabase
      .rpc('get_users_device_tokens', { p_user_ids: payload.user_ids });

    if (dbError) {
      throw new Error(`Database error: ${dbError.message}`);
    }

    if (!deviceTokens || deviceTokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No active device tokens found for users', sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Send notifications to all devices
    const results: NotificationResult[] = [];

    for (const device of deviceTokens as DeviceToken[]) {
      let result: { success: boolean; error?: string };

      if (device.platform === 'ios') {
        result = await sendToAPNs(
          device.token,
          payload.title,
          payload.body,
          payload.data || {},
          payload.priority || 'high',
          payload.badge_increment || 1
        );
      } else if (device.platform === 'android') {
        result = await sendToFCM(
          device.token,
          payload.title,
          payload.body,
          payload.data || {},
          payload.priority || 'high'
        );
      } else {
        result = { success: false, error: 'Unknown platform' };
      }

      results.push({
        success: result.success,
        platform: device.platform,
        token: device.token.substring(0, 20) + '...',  // Log partial token for debugging
        error: result.error,
      });

      // If token is invalid, deactivate it
      if (result.error && (
        result.error.includes('Unregistered') ||
        result.error.includes('InvalidRegistration') ||
        result.error.includes('BadDeviceToken')
      )) {
        await supabase
          .from('device_tokens')
          .update({ is_active: false })
          .eq('token', device.token);
      }
    }

    // Count successes
    const successCount = results.filter(r => r.success).length;
    const failureCount = results.length - successCount;

    return new Response(
      JSON.stringify({
        message: 'Notifications sent',
        sent: successCount,
        failed: failureCount,
        results: results,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error sending push notifications:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
