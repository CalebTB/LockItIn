# Push Notifications Setup Guide

**Status:** ✅ Backend infrastructure complete, manual setup required

This document explains how to complete the push notification setup for LockItIn.

---

## 📋 What's Already Done

### ✅ Supabase Backend (Complete)
- **Database Migration**: `supabase/migrations/015_device_tokens_table.sql`
  - `device_tokens` table for storing iOS/Android tokens
  - RPC functions: `upsert_device_token`, `deactivate_device_token`, `get_user_device_tokens`, `get_users_device_tokens`
  - Row Level Security policies

- **Edge Function**: `supabase/functions/send-push-notification`
  - Sends notifications to both iOS (APNs) and Android (FCM)
  - Handles token validation and deactivation
  - See `supabase/functions/send-push-notification/README.md` for full documentation

### ✅ Flutter App (Complete)
- **Service**: `lib/core/services/push_notification_service.dart`
  - Requests notification permissions
  - Gets device tokens (FCM for Android, APNs for iOS)
  - Registers tokens with Supabase
  - Displays local notifications
  - Handles notification taps (navigation stubbed)

- **Dependencies**: Added to `pubspec.yaml`
  - `firebase_core` & `firebase_messaging` (token generation only)
  - `flutter_local_notifications` (display notifications)

- **Android Configuration**: `android/app/src/main/AndroidManifest.xml`
  - Notification permissions
  - Firebase Messaging Service

- **iOS Configuration**: `ios/Runner/Info.plist`
  - Background modes for remote notifications
  - Firebase delegate proxy disabled (manual control)

---

## 🚧 What Still Needs to Be Done

### Step 1: Apply Database Migration

```bash
# Link your Supabase project (if not already linked)
cd /Users/calebbyers/Code/LockItIn
supabase link --project-ref your-project-ref

# Apply the migration
supabase db push
```

**Verify migration:**
```sql
-- In Supabase SQL Editor
SELECT * FROM device_tokens LIMIT 1;  -- Should exist
SELECT * FROM pg_proc WHERE proname = 'upsert_device_token';  -- Should return 1 row
```

### Step 2: Deploy Supabase Edge Function

```bash
# Deploy the function
cd /Users/calebbyers/Code/LockItIn/supabase
supabase functions deploy send-push-notification
```

### Step 3: Set Up Firebase Project (for Token Generation)

**Why Firebase?** We use `firebase_messaging` package ONLY to get device tokens. Notifications are sent via Supabase Edge Functions, NOT Firebase backend.

#### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Name: `lockitin-app`
4. Disable Google Analytics (optional)

#### 3.2 Add Android App

1. In Firebase Console → Project Overview → Add app → Android
2. Package name: `com.example.lockitin_app`
3. Download `google-services.json`
4. Place file at: `application/lockitin_app/android/app/google-services.json`

#### 3.3 Add iOS App

1. In Firebase Console → Project Overview → Add app → iOS
2. Bundle ID: (get from Xcode → Runner → General → Bundle Identifier)
3. Download `GoogleService-Info.plist`
4. Place file at: `application/lockitin_app/ios/Runner/GoogleService-Info.plist`
5. **Important**: Open `ios/Runner.xcworkspace` in Xcode
   - Right-click `Runner` folder → "Add Files to Runner"
   - Select `GoogleService-Info.plist`
   - Ensure "Copy items if needed" is UNCHECKED
   - Ensure "Runner" target is checked

#### 3.4 Update Android Build Files

**File**: `android/build.gradle.kts`

Add Google services classpath:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

**File**: `android/app/build.gradle.kts`

Add at the very end (after flutter block):
```kotlin
apply(plugin = "com.google.gms.google-services")
```

### Step 4: Get FCM Server Key (Android)

1. Firebase Console → Project Settings → Cloud Messaging
2. Under "Cloud Messaging API (Legacy)", find **Server key**
3. Copy the key (format: `AAAAxxxxxxx:APA91bH...`)
4. Save for Step 6

### Step 5: Get APNs Authentication Key (iOS)

**Requirements:** Apple Developer Account ($99/year)

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click "+" to create a new key
3. Name: "LockItIn APNs"
4. Check "Apple Push Notifications service (APNs)"
5. Click "Continue" → "Register" → Download `.p8` file
6. **IMPORTANT**: Save the `.p8` file securely (can only download once!)
7. Note the **Key ID** (10-character string, e.g., `ABC123DEFG`)
8. Note your **Team ID** (Apple Developer Account → Membership → Team ID)

### Step 6: Configure Supabase Edge Function Secrets

Set these in Supabase Dashboard → Edge Functions → `send-push-notification` → Secrets:

```bash
# iOS (APNs) Configuration
APNS_KEY_ID=ABC123DEFG                    # Your APNs Key ID
APNS_TEAM_ID=DEF123GHIJ                   # Your Apple Team ID
APNS_TOPIC=com.yourcompany.lockitin       # Your iOS Bundle ID
APNS_ENVIRONMENT=sandbox                  # Use 'sandbox' for dev, 'production' for App Store
APNS_KEY_P8=-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM...                  # Full content of .p8 file (paste entire file)
-----END PRIVATE KEY-----

# Android (FCM) Configuration
FCM_SERVER_KEY=AAAAxxxxxxx:APA91bH...     # Your FCM Server Key from Step 4
```

### Step 7: Enable Push Notification Capability (iOS Only)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select `Runner` project in Project Navigator
3. Select `Runner` target
4. Click "Signing & Capabilities" tab
5. Click "+ Capability"
6. Add "Push Notifications"
7. Add "Background Modes" → Check "Remote notifications"

### Step 8: Initialize Push Notifications in Flutter

**File**: `lib/main.dart`

Add Firebase initialization:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for token generation)
  await Firebase.initializeApp();

  // Initialize Supabase (existing)
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize push notifications
  await PushNotificationService.instance.initialize();

  runApp(const MyApp());
}
```

### Step 9: Install Flutter Dependencies

```bash
cd application/lockitin_app
flutter pub get
```

---

## 🧪 Testing

### Test 1: Check Device Token Registration

1. Run the app on a physical device (simulator won't work for push notifications)
2. Accept notification permission when prompted
3. Check logs for device token:
   ```
   [PushNotificationService] Device token: xxxxxxxxxxxxxxxx...
   [PushNotificationService] Device token saved to Supabase
   ```
4. Verify in Supabase:
   ```sql
   SELECT * FROM device_tokens WHERE user_id = 'your-user-id';
   ```

### Test 2: Send Test Notification via Edge Function

```bash
# Get your user_id from Supabase auth.users table
# Then send test notification:

supabase functions invoke send-push-notification \
  --body '{
    "user_ids": ["your-user-id"],
    "title": "Test Notification",
    "body": "If you see this, push notifications are working!",
    "data": {
      "test": true
    },
    "priority": "high"
  }'
```

### Test 3: Test Local Notification (No Backend)

In Flutter code:
```dart
await PushNotificationService.instance.sendTestNotification();
```

Should show a local notification immediately.

---

## 📊 How It Works

### Architecture Flow

```
1. Flutter App
   ├─ firebase_messaging gets device token
   ├─ PushNotificationService saves token to Supabase
   └─ Displays notifications via flutter_local_notifications

2. Supabase Database
   └─ device_tokens table stores tokens by user/platform

3. Notification Trigger (e.g., proposal created)
   └─ Database trigger or app calls Edge Function

4. Supabase Edge Function
   ├─ Gets device tokens from database
   ├─ Sends to APNs (iOS) or FCM (Android)
   └─ Handles token validation/deactivation

5. Device Receives Notification
   ├─ App in background: OS shows notification
   ├─ App in foreground: PushNotificationService shows local notification
   └─ User taps: Navigate to relevant screen
```

### Token Lifecycle

- **Registration**: App launches → gets token → saves to Supabase
- **Refresh**: Token changes → old token deactivated → new token saved
- **Logout**: User logs out → token deactivated
- **Invalid**: Edge Function detects invalid token → auto-deactivates

---

## 🔒 Security

- Device tokens stored with Row Level Security (RLS)
- Users can only view/manage their own tokens
- Edge Function uses Service Role Key (server-side only)
- Invalid tokens automatically deactivated
- APNs .p8 key stored as Supabase secret (encrypted)

---

## 📝 Next Steps (Future Work)

Once push notification infrastructure is working:

**Issue #39 - Proposal Notifications:**
- [ ] Trigger notification when proposal created
- [ ] Send voting deadline reminders
- [ ] Send proposal confirmed notifications
- [ ] Add deep linking to proposal screens
- [ ] Implement notification content templates

**Enhancement Ideas:**
- [ ] Notification preferences UI (let users opt-out per type)
- [ ] Badge count management
- [ ] Notification inbox screen
- [ ] Silent notifications for real-time data sync
- [ ] Scheduled local notifications (event reminders)

---

## 🐛 Troubleshooting

### "Cannot find project ref" when running supabase commands
**Solution**: Link your project first:
```bash
supabase link --project-ref your-project-ref
```

### "APNs credentials not configured" in Edge Function
**Solution**: Verify all APNS_* secrets are set in Supabase Dashboard → Edge Functions → Secrets

### "FCM credentials not configured" in Edge Function
**Solution**: Verify FCM_SERVER_KEY is set in Supabase Dashboard

### iOS: "No valid 'aps-environment' entitlement"
**Solution**:
1. Open Xcode → Runner → Signing & Capabilities
2. Ensure "Push Notifications" capability is added
3. Clean build: Product → Clean Build Folder

### Android: "google-services.json not found"
**Solution**: Download from Firebase Console and place in `android/app/google-services.json`

### Notification not showing on Android
**Solution**:
1. Check notification permission is granted (Android 13+)
2. Verify notification channel is created
3. Check `AndroidManifest.xml` has POST_NOTIFICATIONS permission

### Token not being saved to Supabase
**Solution**:
1. Check app is authenticated (user logged in)
2. Verify RLS policies allow INSERT
3. Check logs for error messages
4. Verify `upsert_device_token` function exists

---

## 📚 Resources

- **Firebase Console**: https://console.firebase.google.com/
- **Apple Developer Portal**: https://developer.apple.com/account/
- **Supabase Edge Functions Docs**: https://supabase.com/docs/guides/functions
- **Firebase Messaging Plugin**: https://pub.dev/packages/firebase_messaging
- **Flutter Local Notifications**: https://pub.dev/packages/flutter_local_notifications

---

**Last Updated**: January 4, 2026
**Status**: Backend ready, manual setup required
**Estimated Setup Time**: 2-3 hours
