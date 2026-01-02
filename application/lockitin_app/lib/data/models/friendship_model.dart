import 'package:equatable/equatable.dart';
import 'user_display_mixin.dart';

/// Helper to mask email addresses for privacy
/// e.g., "john.doe@example.com" -> "j***@example.com"
String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email; // Invalid email, return as-is

  final localPart = parts[0];
  final domain = parts[1];

  // Show first character, mask the rest
  final maskedLocal =
      localPart.length > 1 ? '${localPart[0]}***' : '$localPart***';

  return '$maskedLocal@$domain';
}

/// Friendship status for friend connections
enum FriendshipStatus {
  pending, // Friend request sent, awaiting response
  accepted, // Friend request accepted
  blocked, // User has blocked this person
}

/// Friendship model matching Supabase friendships table
class FriendshipModel extends Equatable {
  final String id;
  final String userId; // The user who sent the request
  final String friendId; // The user who received the request
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? updatedAt;

  const FriendshipModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.updatedAt,
  });

  /// Create FriendshipModel from Supabase JSON
  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      friendId: json['friend_id'] as String,
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert FriendshipModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Convert for creating a new friendship request (minimal fields)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'friend_id': friendId,
    };
  }

  /// Convert status enum to string
  static String _statusToString(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.pending:
        return 'pending';
      case FriendshipStatus.accepted:
        return 'accepted';
      case FriendshipStatus.blocked:
        return 'blocked';
    }
  }

  /// Convert string to status enum
  static FriendshipStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return FriendshipStatus.pending;
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }

  /// Check if this user sent the request
  bool isSender(String currentUserId) => userId == currentUserId;

  /// Check if this user received the request
  bool isReceiver(String currentUserId) => friendId == currentUserId;

  /// Get the other user's ID (the friend)
  String getOtherUserId(String currentUserId) {
    return userId == currentUserId ? friendId : userId;
  }

  /// Create a copy with updated fields
  FriendshipModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? updatedAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        friendId,
        status,
        createdAt,
        acceptedAt,
        updatedAt,
      ];
}

/// Simplified user profile model for friend display
class FriendProfile extends Equatable with UserDisplayMixin {
  final String id;
  final String? friendshipId; // ID of the friendship record (for deletion)
  @override
  final String? fullName;
  @override
  final String email;
  final String? avatarUrl;
  final DateTime? friendshipSince;

  const FriendProfile({
    required this.id,
    this.friendshipId,
    this.fullName,
    required this.email,
    this.avatarUrl,
    this.friendshipSince,
  });

  /// Create from Supabase get_friends function result
  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['friend_id'] as String,
      friendshipId: json['friendship_id'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      friendshipSince: json['friendship_since'] != null
          ? DateTime.parse(json['friendship_since'] as String)
          : null,
    );
  }

  /// Create from users table (for search results)
  /// Note: Email is masked for privacy in search results
  factory FriendProfile.fromUserJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: maskEmail(json['email'] as String), // Mask email for privacy
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, friendshipId, fullName, email, avatarUrl, friendshipSince];
}

/// Model for sent friend request with recipient info
class SentRequest extends Equatable with UserDisplayMixin {
  final String requestId;
  final String recipientId;
  @override
  final String? fullName;
  @override
  final String email;
  final String? avatarUrl;
  final DateTime sentAt;

  const SentRequest({
    required this.requestId,
    required this.recipientId,
    this.fullName,
    required this.email,
    this.avatarUrl,
    required this.sentAt,
  });

  /// Create from Supabase get_sent_requests function result
  factory SentRequest.fromJson(Map<String, dynamic> json) {
    return SentRequest(
      requestId: json['request_id'] as String,
      recipientId: json['recipient_id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [requestId, recipientId, fullName, email, avatarUrl, sentAt];
}

/// Model for pending friend request with requester info
class FriendRequest extends Equatable with UserDisplayMixin {
  final String requestId;
  final String requesterId;
  @override
  final String? fullName;
  @override
  final String email;
  final String? avatarUrl;
  final DateTime requestedAt;

  const FriendRequest({
    required this.requestId,
    required this.requesterId,
    this.fullName,
    required this.email,
    this.avatarUrl,
    required this.requestedAt,
  });

  /// Create from Supabase get_pending_requests function result
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      requestId: json['request_id'] as String,
      requesterId: json['requester_id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [requestId, requesterId, fullName, email, avatarUrl, requestedAt];
}

/// Availability status for a friend
enum AvailabilityStatus {
  free,    // No events in the next hour
  busy,    // Currently in an event or event starting within 15 minutes
  unknown, // Friend's calendar not shared
}

/// Model for friend availability status
class FriendAvailability extends Equatable {
  final String friendId;
  final AvailabilityStatus status;
  final DateTime? busyUntil;

  const FriendAvailability({
    required this.friendId,
    required this.status,
    this.busyUntil,
  });

  /// Create from Supabase get_friends_availability function result
  factory FriendAvailability.fromJson(Map<String, dynamic> json) {
    return FriendAvailability(
      friendId: json['friend_id'] as String,
      status: _statusFromString(json['status'] as String),
      busyUntil: json['busy_until'] != null
          ? DateTime.parse(json['busy_until'] as String)
          : null,
    );
  }

  /// Convert string to status enum
  static AvailabilityStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'free':
        return AvailabilityStatus.free;
      case 'busy':
        return AvailabilityStatus.busy;
      case 'unknown':
      default:
        return AvailabilityStatus.unknown;
    }
  }

  /// Convert status to display string
  String get statusLabel {
    switch (status) {
      case AvailabilityStatus.free:
        return 'Free';
      case AvailabilityStatus.busy:
        return 'Busy';
      case AvailabilityStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  List<Object?> get props => [friendId, status, busyUntil];
}
