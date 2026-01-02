/// Type of vote a user can cast
enum VoteType {
  yes,
  no,
  maybe;

  static VoteType fromString(String value) {
    return VoteType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VoteType.maybe,
    );
  }

  /// Human-readable label
  String get label {
    switch (this) {
      case VoteType.yes:
        return 'Available';
      case VoteType.no:
        return 'Unavailable';
      case VoteType.maybe:
        return 'If needed';
    }
  }

  /// Icon name for the vote type
  String get iconName {
    switch (this) {
      case VoteType.yes:
        return 'check_circle';
      case VoteType.no:
        return 'cancel';
      case VoteType.maybe:
        return 'help';
    }
  }
}

/// Represents a user's vote on a proposal time option
class VoteModel {
  final String id;
  final String proposalId;
  final String timeOptionId;
  final String userId;
  final VoteType vote;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Optional joined user data
  final String? userFullName;
  final String? userAvatarUrl;

  const VoteModel({
    required this.id,
    required this.proposalId,
    required this.timeOptionId,
    required this.userId,
    required this.vote,
    required this.createdAt,
    this.updatedAt,
    this.userFullName,
    this.userAvatarUrl,
  });

  /// Create from JSON (Supabase response)
  factory VoteModel.fromJson(Map<String, dynamic> json) {
    return VoteModel(
      id: json['id'] as String,
      proposalId: json['proposal_id'] as String,
      timeOptionId: json['time_option_id'] as String,
      userId: json['user_id'] as String,
      vote: VoteType.fromString(json['vote'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userFullName: json['full_name'] as String?,
      userAvatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Create from RPC response (get_time_option_votes)
  factory VoteModel.fromRpcJson(Map<String, dynamic> json, String proposalId, String timeOptionId) {
    return VoteModel(
      id: '', // RPC doesn't return ID
      proposalId: proposalId,
      timeOptionId: timeOptionId,
      userId: json['user_id'] as String,
      vote: VoteType.fromString(json['vote'] as String),
      createdAt: DateTime.parse(json['voted_at'] as String),
      userFullName: json['full_name'] as String?,
      userAvatarUrl: json['avatar_url'] as String?,
    );
  }

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'proposal_id': proposalId,
      'time_option_id': timeOptionId,
      'user_id': userId,
      'vote': vote.name,
    };
  }

  /// Create a copy with modified fields
  VoteModel copyWith({
    String? id,
    String? proposalId,
    String? timeOptionId,
    String? userId,
    VoteType? vote,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userFullName,
    String? userAvatarUrl,
  }) {
    return VoteModel(
      id: id ?? this.id,
      proposalId: proposalId ?? this.proposalId,
      timeOptionId: timeOptionId ?? this.timeOptionId,
      userId: userId ?? this.userId,
      vote: vote ?? this.vote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userFullName: userFullName ?? this.userFullName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }

  @override
  String toString() {
    return 'VoteModel(userId: $userId, vote: $vote, timeOptionId: $timeOptionId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoteModel &&
        other.proposalId == proposalId &&
        other.timeOptionId == timeOptionId &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(proposalId, timeOptionId, userId);
}

/// Summary of votes for a time option
class VoteSummary {
  final String timeOptionId;
  final DateTime startTime;
  final DateTime endTime;
  final int yesCount;
  final int maybeCount;
  final int noCount;
  final int totalVotes;

  const VoteSummary({
    required this.timeOptionId,
    required this.startTime,
    required this.endTime,
    this.yesCount = 0,
    this.maybeCount = 0,
    this.noCount = 0,
    this.totalVotes = 0,
  });

  /// Create from RPC response (get_proposal_vote_summary)
  factory VoteSummary.fromJson(Map<String, dynamic> json) {
    return VoteSummary(
      timeOptionId: json['time_option_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      yesCount: json['yes_count'] as int? ?? 0,
      maybeCount: json['maybe_count'] as int? ?? 0,
      noCount: json['no_count'] as int? ?? 0,
      totalVotes: json['total_votes'] as int? ?? 0,
    );
  }

  /// Calculate a weighted score for ranking (yes=2, maybe=1, no=0)
  int get score => (yesCount * 2) + maybeCount;

  /// Percentage of yes votes (0-100)
  double get yesPercentage =>
      totalVotes > 0 ? (yesCount / totalVotes) * 100 : 0;

  /// Percentage of maybe votes (0-100)
  double get maybePercentage =>
      totalVotes > 0 ? (maybeCount / totalVotes) * 100 : 0;

  /// Percentage of no votes (0-100)
  double get noPercentage =>
      totalVotes > 0 ? (noCount / totalVotes) * 100 : 0;

  @override
  String toString() {
    return 'VoteSummary(timeOptionId: $timeOptionId, yes: $yesCount, maybe: $maybeCount, no: $noCount)';
  }
}
