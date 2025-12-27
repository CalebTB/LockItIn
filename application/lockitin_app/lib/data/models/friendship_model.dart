import 'package:equatable/equatable.dart';

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
class FriendProfile extends Equatable {
  final String id;
  final String? friendshipId; // ID of the friendship record (for deletion)
  final String? fullName;
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
  factory FriendProfile.fromUserJson(Map<String, dynamic> json) {
    return FriendProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Display name (full name or email if no name)
  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  /// Initials for avatar placeholder
  String get initials {
    if (fullName?.isNotEmpty == true) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  List<Object?> get props => [id, friendshipId, fullName, email, avatarUrl, friendshipSince];
}

/// Model for pending friend request with requester info
class FriendRequest extends Equatable {
  final String requestId;
  final String requesterId;
  final String? fullName;
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

  /// Display name (full name or email if no name)
  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  /// Initials for avatar placeholder
  String get initials {
    if (fullName?.isNotEmpty == true) {
      final parts = fullName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return fullName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  List<Object?> get props =>
      [requestId, requesterId, fullName, email, avatarUrl, requestedAt];
}
