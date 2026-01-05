import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

/// Top-level function required for background message handling
/// This runs in a separate isolate when app is terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Logger.info('PushNotificationService', 'Background message: ${message.messageId}');

  // Background notifications are handled by the OS
  // This is just for logging/tracking
}

/// Service for managing push notifications
///
/// Architecture:
/// - Uses Firebase Messaging ONLY for getting device tokens (FCM for Android, APNs for iOS)
/// - Device tokens are registered with Supabase
/// - Notifications are SENT via Supabase Edge Functions (not Firebase backend)
/// - Local notifications displayed via flutter_local_notifications
class PushNotificationService {
  static const _tag = 'PushNotificationService';
  static final PushNotificationService _instance = PushNotificationService._internal();
  static PushNotificationService get instance => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;

  bool _isInitialized = false;
  String? _deviceToken;

  /// Initialize push notifications
  Future<void> initialize() async {
    if (_isInitialized) {
      Logger.info(_tag, 'Already initialized');
      return;
    }

    try {
      Logger.info(_tag, 'Initializing push notifications');

      // 1. Initialize local notifications (for displaying notifications)
      await _initializeLocalNotifications();

      // 2. Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request notification permissions
      final granted = await _requestPermissions();
      if (!granted) {
        Logger.warning(_tag, 'Notification permissions denied');
        _isInitialized = true;
        return;  // Still mark as initialized, but won't register token
      }

      // 4. Get device token and register with Supabase
      await _registerDeviceToken();

      // 5. Handle foreground messages (app is open)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Handle notification taps (app opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 7. Check if app was opened from terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        Logger.info(_tag, 'App opened from terminated state via notification');
        _handleNotificationTap(initialMessage);
      }

      // 8. Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      _isInitialized = true;
      Logger.info(_tag, 'Push notifications initialized successfully');
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to initialize push notifications: $e', e, stackTrace);
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel (required Android 8.0+)
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    Logger.info(_tag, 'Local notifications initialized');
  }

  /// Create Android notification channel (required Android 8.0+)
  Future<void> _createAndroidNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'lockitin_proposals',  // id
      'Proposals & Voting',  // name
      description: 'Notifications for event proposals and voting updates',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    Logger.info(_tag, 'Android notification channel created');
  }

  /// Request notification permissions from user
  Future<bool> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    Logger.info(_tag, 'Permission status: ${settings.authorizationStatus}');

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Get device token and register with Supabase
  Future<void> _registerDeviceToken() async {
    try {
      // Get device token (FCM for Android, APNs for iOS)
      final token = await _messaging.getToken();

      if (token == null) {
        Logger.warning(_tag, 'Failed to get device token');
        return;
      }

      _deviceToken = token;
      Logger.info(_tag, 'Device token: ${token.substring(0, 20)}...');

      // Store in Supabase
      await _saveTokenToSupabase(token);
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to register device token: $e', e, stackTrace);
    }
  }

  /// Save device token to Supabase
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final osVersion = Platform.operatingSystemVersion;

      // Call RPC function to upsert device token
      await _supabase.rpc(
        'upsert_device_token',
        params: {
          'p_token': token,
          'p_platform': platform,
          'p_os_version': osVersion,
          'p_app_version': '0.1.0',  // TODO: Get from package_info
        },
      );

      Logger.info(_tag, 'Device token saved to Supabase');
    } catch (e, stackTrace) {
      Logger.error(_tag, 'Failed to save token to Supabase: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Handle token refresh (token can change)
  Future<void> _onTokenRefresh(String newToken) async {
    Logger.info(_tag, 'Token refreshed');

    // Deactivate old token
    if (_deviceToken != null && _deviceToken != newToken) {
      try {
        await _supabase.rpc(
          'deactivate_device_token',
          params: {'p_token': _deviceToken},
        );
        Logger.info(_tag, 'Old token deactivated');
      } catch (e) {
        Logger.error(_tag, 'Failed to deactivate old token: $e');
      }
    }

    // Register new token
    _deviceToken = newToken;
    await _saveTokenToSupabase(newToken);
  }

  /// Handle foreground messages (app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    Logger.info(_tag, 'Foreground message: ${message.notification?.title}');

    // Show local notification when app is in foreground
    // (Firebase Messaging doesn't show notifications when app is foregrounded)
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      data: message.data,
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lockitin_proposals',
      'Proposals & Voting',
      channelDescription: 'Notifications for event proposals and voting updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    Logger.info(_tag, 'Local notification shown: $title');
  }

  /// Handle notification tap (app opened from background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    Logger.info(_tag, 'Notification tapped: ${message.messageId}');

    // TODO: Navigate to appropriate screen based on notification data
    final data = message.data;

    if (data.containsKey('proposal_id')) {
      final proposalId = data['proposal_id'];
      Logger.info(_tag, 'Navigate to proposal: $proposalId');
      // TODO: navigationService.navigateToProposal(proposalId);
    } else if (data.containsKey('group_id')) {
      final groupId = data['group_id'];
      Logger.info(_tag, 'Navigate to group: $groupId');
      // TODO: navigationService.navigateToGroup(groupId);
    } else if (data.containsKey('event_id')) {
      final eventId = data['event_id'];
      Logger.info(_tag, 'Navigate to event: $eventId');
      // TODO: navigationService.navigateToEvent(eventId);
    }
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    Logger.info(_tag, 'Local notification tapped: ${response.payload}');
    // TODO: Parse payload and navigate
  }

  /// Deactivate current device token (e.g., on logout)
  Future<void> deactivateToken() async {
    if (_deviceToken == null) return;

    try {
      await _supabase.rpc(
        'deactivate_device_token',
        params: {'p_token': _deviceToken},
      );
      Logger.info(_tag, 'Device token deactivated');
    } catch (e) {
      Logger.error(_tag, 'Failed to deactivate token: $e');
    }
  }

  /// Send a test notification (for development/testing)
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'If you see this, local notifications are working!',
      payload: 'test',
    );
  }

  /// Get current device token
  String? get deviceToken => _deviceToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}
