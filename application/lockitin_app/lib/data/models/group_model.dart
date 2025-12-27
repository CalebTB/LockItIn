import 'package:equatable/equatable.dart';

/// Role of a member within a group
enum GroupMemberRole {
  owner, // Created the group, full control
  admin, // Can manage members and settings
  member, // Regular member
}

/// Group model matching Supabase groups table
class GroupModel extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Member count (populated from join query)
  final int memberCount;

  const GroupModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.memberCount = 0,
  });

  /// Create GroupModel from Supabase JSON
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '👥',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  /// Create from get_user_groups RPC result
  factory GroupModel.fromRpcJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['group_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '👥',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  /// Convert GroupModel to JSON for Supabase insert
  Map<String, dynamic> toInsertJson() {
    return {
      'name': name,
      'emoji': emoji,
      'created_by': createdBy,
    };
  }

  /// Convert GroupModel to JSON for Supabase update
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'emoji': emoji,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  GroupModel copyWith({
    String? id,
    String? name,
    String? emoji,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        emoji,
        createdBy,
        createdAt,
        updatedAt,
        memberCount,
      ];
}

/// Group member model matching Supabase group_members table
class GroupMemberModel extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final GroupMemberRole role;
  final DateTime joinedAt;

  const GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  /// Create GroupMemberModel from Supabase JSON
  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: roleFromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  /// Convert role enum to string
  static String roleToString(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.owner:
        return 'owner';
      case GroupMemberRole.admin:
        return 'admin';
      case GroupMemberRole.member:
        return 'member';
    }
  }

  /// Convert string to role enum
  static GroupMemberRole roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return GroupMemberRole.owner;
      case 'admin':
        return GroupMemberRole.admin;
      case 'member':
      default:
        return GroupMemberRole.member;
    }
  }

  /// Convert GroupMemberModel to JSON for Supabase insert
  Map<String, dynamic> toInsertJson() {
    return {
      'group_id': groupId,
      'user_id': userId,
      'role': roleToString(role),
    };
  }

  /// Check if this member can manage other members
  bool get canManageMembers =>
      role == GroupMemberRole.owner || role == GroupMemberRole.admin;

  /// Check if this member can delete the group
  bool get canDeleteGroup => role == GroupMemberRole.owner;

  @override
  List<Object?> get props => [id, groupId, userId, role, joinedAt];
}

/// Group member with profile info for display
class GroupMemberProfile extends Equatable {
  final String memberId; // group_members.id
  final String userId;
  final String? fullName;
  final String email;
  final String? avatarUrl;
  final GroupMemberRole role;
  final DateTime joinedAt;

  const GroupMemberProfile({
    required this.memberId,
    required this.userId,
    this.fullName,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  /// Create from get_group_members RPC result
  factory GroupMemberProfile.fromJson(Map<String, dynamic> json) {
    return GroupMemberProfile(
      memberId: json['member_id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: GroupMemberModel.roleFromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
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

  /// Role display string
  String get roleDisplayName {
    switch (role) {
      case GroupMemberRole.owner:
        return 'Owner';
      case GroupMemberRole.admin:
        return 'Admin';
      case GroupMemberRole.member:
        return 'Member';
    }
  }

  @override
  List<Object?> get props => [
        memberId,
        userId,
        fullName,
        email,
        avatarUrl,
        role,
        joinedAt,
      ];
}

/// Group invite model for pending invitations
class GroupInvite extends Equatable {
  final String id;
  final String groupId;
  final String groupName;
  final String groupEmoji;
  final String invitedBy;
  final String inviterName;
  final DateTime invitedAt;

  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.groupEmoji,
    required this.invitedBy,
    required this.inviterName,
    required this.invitedAt,
  });

  /// Create from get_pending_group_invites RPC result
  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      id: json['invite_id'] as String,
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String,
      groupEmoji: json['group_emoji'] as String? ?? '👥',
      invitedBy: json['invited_by'] as String,
      inviterName: json['inviter_name'] as String? ?? 'Someone',
      invitedAt: DateTime.parse(json['invited_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        groupName,
        groupEmoji,
        invitedBy,
        inviterName,
        invitedAt,
      ];
}
