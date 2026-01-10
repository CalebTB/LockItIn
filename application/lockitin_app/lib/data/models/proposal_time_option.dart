import 'vote_model.dart';
import '../../core/utils/timezone_utils.dart';

/// Represents a time option for a group proposal
/// Users vote on multiple time options to find the best meeting time
class ProposalTimeOption {
  final String? id;
  final String? proposalId;
  final DateTime startTime;
  final DateTime endTime;
  final int optionOrder;

  // Vote counts (from vote summary)
  final int yesCount;
  final int maybeCount;
  final int noCount;

  // UI state
  final bool isSelected;

  // User's vote on this option (if any)
  final VoteType? userVote;

  const ProposalTimeOption({
    this.id,
    this.proposalId,
    required this.startTime,
    required this.endTime,
    this.optionOrder = 1,
    this.yesCount = 0,
    this.maybeCount = 0,
    this.noCount = 0,
    this.isSelected = false,
    this.userVote,
  });

  /// Total number of votes cast on this option
  int get totalVotes => yesCount + maybeCount + noCount;

  /// Legacy getter for backward compatibility
  int get voteCount => yesCount;

  /// Weighted score for ranking (yes=2, maybe=1, no=0)
  int get score => (yesCount * 2) + maybeCount;

  /// Create a copy with modified fields
  ProposalTimeOption copyWith({
    String? id,
    String? proposalId,
    DateTime? startTime,
    DateTime? endTime,
    int? optionOrder,
    int? yesCount,
    int? maybeCount,
    int? noCount,
    bool? isSelected,
    VoteType? userVote,
  }) {
    return ProposalTimeOption(
      id: id ?? this.id,
      proposalId: proposalId ?? this.proposalId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      optionOrder: optionOrder ?? this.optionOrder,
      yesCount: yesCount ?? this.yesCount,
      maybeCount: maybeCount ?? this.maybeCount,
      noCount: noCount ?? this.noCount,
      isSelected: isSelected ?? this.isSelected,
      userVote: userVote ?? this.userVote,
    );
  }

  /// Get the duration of this time option
  Duration get duration => endTime.difference(startTime);

  /// Check if two time options overlap
  bool overlapsWith(ProposalTimeOption other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  /// Convert to JSON for API (insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (proposalId != null) 'proposal_id': proposalId,
      'start_time': TimezoneUtils.toUtcString(startTime),
      'end_time': TimezoneUtils.toUtcString(endTime),
      'option_order': optionOrder,
    };
  }

  /// Convert to JSON for creating proposals (minimal data)
  Map<String, dynamic> toCreateJson() {
    return {
      'start_time': TimezoneUtils.toUtcString(startTime),
      'end_time': TimezoneUtils.toUtcString(endTime),
    };
  }

  /// Create from JSON (database response)
  factory ProposalTimeOption.fromJson(Map<String, dynamic> json) {
    return ProposalTimeOption(
      id: json['id'] as String?,
      proposalId: json['proposal_id'] as String?,
      startTime: _parseDateTime(json['start_time']),
      endTime: _parseDateTime(json['end_time']),
      optionOrder: json['option_order'] as int? ?? 1,
      yesCount: json['yes_count'] as int? ?? 0,
      maybeCount: json['maybe_count'] as int? ?? 0,
      noCount: json['no_count'] as int? ?? 0,
      userVote: json['user_vote'] != null
          ? VoteType.fromString(json['user_vote'] as String)
          : null,
    );
  }

  /// Create from vote summary RPC response
  factory ProposalTimeOption.fromVoteSummary(Map<String, dynamic> json) {
    return ProposalTimeOption(
      id: json['time_option_id'] as String,
      startTime: _parseDateTime(json['start_time']),
      endTime: _parseDateTime(json['end_time']),
      yesCount: json['yes_count'] as int? ?? 0,
      maybeCount: json['maybe_count'] as int? ?? 0,
      noCount: json['no_count'] as int? ?? 0,
    );
  }

  /// Helper to parse DateTime from JSON (handles both String and DateTime types)
  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value.isUtc ? value : value.toUtc();
    } else if (value is String) {
      return TimezoneUtils.parseUtc(value);
    } else {
      throw ArgumentError('Invalid datetime value: $value');
    }
  }

  @override
  String toString() {
    return 'ProposalTimeOption(startTime: $startTime, endTime: $endTime, yes: $yesCount, maybe: $maybeCount, no: $noCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProposalTimeOption &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode => Object.hash(id, startTime, endTime);
}
