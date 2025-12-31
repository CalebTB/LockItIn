import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';
import '../../data/models/notification_model.dart';

/// Service for managing in-app notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;

  /// Get user's notifications with pagination
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      Logger.info('NotificationService', 'Fetching notifications (limit: $limit, offset: $offset)');

      final result = await _supabase.rpc(
        'get_user_notifications',
        params: {
          'p_limit': limit,
          'p_offset': offset,
          'p_unread_only': unreadOnly,
        },
      );

      final notifications = (result as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info('NotificationService', 'Fetched ${notifications.length} notifications');
      return notifications;
    } catch (e) {
      Logger.error('NotificationService: Failed to fetch notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final result = await _supabase.rpc('get_unread_notification_count');
      return result as int;
    } catch (e) {
      Logger.error('NotificationService: Failed to get unread count: $e');
      return 0;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );
      Logger.info('NotificationService', 'Marked notification as read: $notificationId');
    } catch (e) {
      Logger.error('NotificationService: Failed to mark as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final result = await _supabase.rpc('mark_all_notifications_read');
      final count = result as int;
      Logger.info('NotificationService', 'Marked $count notifications as read');
      return count;
    } catch (e) {
      Logger.error('NotificationService: Failed to mark all as read: $e');
      rethrow;
    }
  }

  /// Dismiss a notification
  Future<void> dismiss(String notificationId) async {
    try {
      await _supabase.rpc(
        'dismiss_notification',
        params: {'p_notification_id': notificationId},
      );
      Logger.info('NotificationService', 'Dismissed notification: $notificationId');
    } catch (e) {
      Logger.error('NotificationService: Failed to dismiss notification: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> delete(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      Logger.info('NotificationService', 'Deleted notification: $notificationId');
    } catch (e) {
      Logger.error('NotificationService: Failed to delete notification: $e');
      rethrow;
    }
  }

  /// Subscribe to new notifications
  RealtimeChannel subscribeToNotifications({
    required void Function(NotificationModel notification) onNewNotification,
    required void Function() onNotificationUpdate,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    Logger.info('NotificationService', 'Subscribing to notifications for user: $userId');

    return _supabase.channel('notifications:$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          Logger.info('NotificationService', 'New notification received');
          try {
            final notification = NotificationModel.fromJson(payload.newRecord);
            onNewNotification(notification);
          } catch (e) {
            Logger.error('NotificationService: Failed to parse notification: $e');
          }
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          Logger.info('NotificationService', 'Notification updated');
          onNotificationUpdate();
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          Logger.info('NotificationService', 'Notification deleted');
          onNotificationUpdate();
        },
      )
      .subscribe();
  }

  /// Unsubscribe from notifications channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
    Logger.info('NotificationService', 'Unsubscribed from notifications');
  }
}
