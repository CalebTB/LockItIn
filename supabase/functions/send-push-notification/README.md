# send-push-notification Edge Function

Supabase Edge Function for sending push notifications to iOS (APNs) and Android (FCM) devices.

## Overview

This function:
- Accepts a notification payload with user IDs, title, body, and optional data
- Looks up active device tokens for those users
- Sends notifications to iOS devices via APNs (Apple Push Notification service)
- Sends notifications to Android devices via FCM (Firebase Cloud Messaging)
- Deactivates invalid tokens automatically
- Returns success/failure status for each device

## Prerequisites

### iOS (APNs) Setup

1. **Apple Developer Account** (required)

2. **Generate APNs Authentication Key:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
   - Click "+" to create a new key
   - Check "Apple Push Notifications service (APNs)"
   - Download the `.p8` file (save it securely - can only download once!)
   - Note the **Key ID** (10-character string)
   - Note your **Team ID** (found in account settings)

3. **App Bundle ID:**
   - Your iOS app's Bundle Identifier (e.g., `com.lockit.app`)
   - Found in Xcode → Runner → General → Identity

### Android (FCM) Setup

1. **Firebase Project** (free)

2. **Create Firebase Project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project or use existing
   - Add Android app with package name `com.example.lockitin_app`

3. **Get FCM Server Key:**
   - Firebase Console → Project Settings → Cloud Messaging
   - Under "Cloud Messaging API (Legacy)", find **Server key**
   - Copy the server key (looks like `AAAAxxxxxxx:APA91bH...`)

## Configuration

Set the following secrets in Supabase Dashboard:

```bash
# Navigate to: Supabase Dashboard → Edge Functions → send-push-notification → Secrets

# iOS (APNs) Configuration
APNS_KEY_ID=ABC123DEFG            # Your APNs Key ID (10 chars)
APNS_TEAM_ID=DEF123GHIJ           # Your Apple Team ID (10 chars)
APNS_TOPIC=com.lockit.app         # Your iOS Bundle ID
APNS_KEY_P8=-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGBy...              # Full content of .p8 file (multiline)
-----END PRIVATE KEY-----
APNS_ENVIRONMENT=sandbox          # Use 'sandbox' for dev, 'production' for release

# Android (FCM) Configuration
FCM_SERVER_KEY=AAAAxxxxxxx:APA91bH...  # Your FCM Server Key
```

## Deployment

```bash
# Deploy the Edge Function
cd supabase
supabase functions deploy send-push-notification

# Test with curl
supabase functions invoke send-push-notification \
  --body '{"user_ids":["user-uuid"], "title":"Test", "body":"Hello!"}'
```

## Usage

### From Database Trigger

```sql
-- Example: Send notification when proposal is created
CREATE OR REPLACE FUNCTION notify_proposal_created()
RETURNS TRIGGER AS $$
BEGIN
    -- Get all group members except creator
    SELECT array_agg(user_id) INTO v_user_ids
    FROM group_members
    WHERE group_id = NEW.group_id
      AND user_id != NEW.created_by;

    -- Call Edge Function
    PERFORM net.http_post(
        url := 'https://your-project.supabase.co/functions/v1/send-push-notification',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('request.headers')::json->>'authorization'
        ),
        body := jsonb_build_object(
            'user_ids', v_user_ids,
            'title', (SELECT full_name FROM users WHERE id = NEW.created_by) || ' proposed ' || NEW.title,
            'body', 'Vote needed • Closes in 24 hours',
            'data', jsonb_build_object(
                'proposal_id', NEW.id,
                'group_id', NEW.group_id,
                'type', 'proposal_created'
            ),
            'priority', 'high',
            'badge_increment', 1
        )
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### From Flutter App (Manual Notification)

```dart
// Example: Send test notification
await supabase.functions.invoke(
  'send-push-notification',
  body: {
    'user_ids': ['user-uuid-1', 'user-uuid-2'],
    'title': 'Game Night confirmed!',
    'body': 'Saturday at 7:00 PM',
    'data': {
      'proposal_id': 'proposal-uuid',
      'type': 'proposal_confirmed',
    },
    'priority': 'high',
    'badge_increment': 1,
  },
);
```

## Payload Schema

```typescript
{
  "user_ids": string[],        // REQUIRED: Array of user IDs to notify
  "title": string,             // REQUIRED: Notification title
  "body": string,              // REQUIRED: Notification body text
  "data": {                    // OPTIONAL: Custom data for deep linking
    "proposal_id": string,
    "group_id": string,
    "type": string,
    // ... any other key-value pairs
  },
  "priority": "high" | "normal",  // OPTIONAL: Default "high"
  "badge_increment": number       // OPTIONAL: iOS badge count increment (default 1)
}
```

## Response Schema

```typescript
{
  "message": "Notifications sent",
  "sent": number,           // Number of successful sends
  "failed": number,         // Number of failed sends
  "results": [
    {
      "success": boolean,
      "platform": "ios" | "android",
      "token": string,      // Partial token (for debugging)
      "error": string       // Error message if failed
    }
  ]
}
```

## Error Handling

The function automatically:
- Deactivates invalid tokens (Unregistered, BadDeviceToken)
- Returns detailed error messages for debugging
- Continues sending to other devices if one fails

## Testing

### Test APNs (iOS)

```bash
# Send test notification to iOS device
supabase functions invoke send-push-notification \
  --body '{
    "user_ids": ["your-user-id"],
    "title": "Test iOS Notification",
    "body": "If you see this, APNs is working!",
    "data": {"test": true},
    "priority": "high"
  }'
```

### Test FCM (Android)

```bash
# Send test notification to Android device
supabase functions invoke send-push-notification \
  --body '{
    "user_ids": ["your-user-id"],
    "title": "Test Android Notification",
    "body": "If you see this, FCM is working!",
    "data": {"test": true},
    "priority": "high"
  }'
```

## TODO

- [ ] Implement APNs JWT generation (currently placeholder)
- [ ] Add retry logic for failed sends
- [ ] Add batching for large user lists (>1000 users)
- [ ] Add notification analytics (track delivery, open rates)
- [ ] Support silent notifications for background data sync
- [ ] Add rate limiting to prevent abuse

## Troubleshooting

**"APNs credentials not configured"**
- Verify APNS_* secrets are set in Supabase Dashboard
- Check .p8 key content is complete (including -----BEGIN/END PRIVATE KEY-----)

**"FCM credentials not configured"**
- Verify FCM_SERVER_KEY is set in Supabase Dashboard
- Ensure using Server Key, not Web API Key

**"BadDeviceToken" (iOS)**
- Token is for wrong environment (sandbox vs production)
- Set APNS_ENVIRONMENT correctly
- Verify app Bundle ID matches APNS_TOPIC

**"InvalidRegistration" (Android)**
- Token may be expired or invalid
- Function will automatically deactivate the token

**"No active device tokens found"**
- User hasn't registered a device token yet
- Check `device_tokens` table for user's tokens

## Security

- Uses Supabase Service Role Key (server-side only)
- Device tokens are protected by RLS policies
- Invalid tokens are automatically deactivated
- Partial tokens logged (first 20 chars only)

## License

Private - LockItIn App
