/// Type of notification
enum NotificationType {
  // Proposal notifications
  proposalCreated,
  proposalVoteCast,
  proposalConfirmed,
  proposalCancelled,
  proposalExpired,
  votingReminder,

  // Group notifications
  groupInvite,
  groupInviteAccepted,
  memberJoined,
  memberLeft,
  memberRemoved,
  roleChanged,

  // Friend notifications
  friendRequest,
  friendAccepted,

  // Event notifications
  eventCreated,
  eventUpdated,
  eventCancelled,
  eventReminder,

  // System notifications
  systemAnnouncement;

  static NotificationType fromString(String value) {
    // Convert snake_case to camelCase for matching
    final camelCase = value.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
    return NotificationType.values.firstWhere(
      (e) => e.name == camelCase,
      orElse: () => NotificationType.systemAnnouncement,
    );
  }

  /// Human-readable category
  String get category {
    switch (this) {
      case NotificationType.proposalCreated:
      case NotificationType.proposalVoteCast:
      case NotificationType.proposalConfirmed:
      case NotificationType.proposalCancelled:
      case NotificationType.proposalExpired:
      case NotificationType.votingReminder:
        return 'Proposals';
      case NotificationType.groupInvite:
      case NotificationType.groupInviteAccepted:
      case NotificationType.memberJoined:
      case NotificationType.memberLeft:
      case NotificationType.memberRemoved:
      case NotificationType.roleChanged:
        return 'Groups';
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
        return 'Friends';
      case NotificationType.eventCreated:
      case NotificationType.eventUpdated:
      case NotificationType.eventCancelled:
      case NotificationType.eventReminder:
        return 'Events';
      case NotificationType.systemAnnouncement:
        return 'System';
    }
  }

  /// Whether this notification type requires action
  bool get requiresAction {
    switch (this) {
      case NotificationType.proposalCreated:
      case NotificationType.votingReminder:
      case NotificationType.groupInvite:
      case NotificationType.friendRequest:
        return true;
      default:
        return false;
    }
  }
}

/// Represents an in-app notification
class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? actionedAt;
  final DateTime? dismissedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isExpired;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.readAt,
    this.actionedAt,
    this.dismissedAt,
    required this.createdAt,
    this.expiresAt,
    this.isExpired = false,
  });

  /// Whether the notification has been read
  bool get isRead => readAt != null;

  /// Whether the notification has been acted upon
  bool get isActioned => actionedAt != null;

  /// Whether the notification has been dismissed
  bool get isDismissed => dismissedAt != null;

  /// Get proposal ID from data (if applicable)
  String? get proposalId => data['proposal_id'] as String?;

  /// Get group ID from data (if applicable)
  String? get groupId => data['group_id'] as String?;

  /// Get friend/user ID from data (if applicable)
  String? get relatedUserId =>
      data['sender_id'] as String? ??
      data['friend_id'] as String? ??
      data['created_by'] as String? ??
      data['invited_by'] as String?;

  /// Create from JSON (database or RPC response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? {},
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      actionedAt: json['actioned_at'] != null
          ? DateTime.parse(json['actioned_at'] as String)
          : null,
      dismissedAt: json['dismissed_at'] != null
          ? DateTime.parse(json['dismissed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isExpired: json['is_expired'] as bool? ?? false,
    );
  }

  /// Create a copy with modified fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? readAt,
    DateTime? actionedAt,
    DateTime? dismissedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isExpired,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      readAt: readAt ?? this.readAt,
      actionedAt: actionedAt ?? this.actionedAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
