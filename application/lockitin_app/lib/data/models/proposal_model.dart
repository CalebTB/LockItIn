import 'proposal_time_option.dart';
import '../../core/utils/timezone_utils.dart';

/// Status of an event proposal
enum ProposalStatus {
  voting,
  confirmed,
  cancelled,
  expired;

  static ProposalStatus fromString(String value) {
    return ProposalStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProposalStatus.voting,
    );
  }
}

/// Represents an event proposal for group voting
class ProposalModel {
  final String id;
  final String groupId;
  final String createdBy;
  final String title;
  final String? description;
  final String? location;
  final DateTime votingDeadline;
  final int minVotesRequired;
  final bool autoConfirm;
  final ProposalStatus status;
  final String? confirmedTimeOptionId;
  final String? confirmedEventId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Optional joined data
  final String? creatorName;
  final List<ProposalTimeOption>? timeOptions;
  final int? totalVoters;
  final bool? userHasVoted;

  const ProposalModel({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    this.description,
    this.location,
    required this.votingDeadline,
    this.minVotesRequired = 1,
    this.autoConfirm = true,
    this.status = ProposalStatus.voting,
    this.confirmedTimeOptionId,
    this.confirmedEventId,
    required this.createdAt,
    this.updatedAt,
    this.creatorName,
    this.timeOptions,
    this.totalVoters,
    this.userHasVoted,
  });

  /// Check if voting is still open
  bool get isVotingOpen =>
      status == ProposalStatus.voting && TimezoneUtils.nowUtc().isBefore(votingDeadline);

  /// Check if voting deadline has passed
  bool get isExpired => TimezoneUtils.nowUtc().isAfter(votingDeadline);

  /// Time remaining until voting deadline
  Duration get timeRemaining => votingDeadline.difference(TimezoneUtils.nowUtc());

  /// Create from JSON (Supabase response)
  factory ProposalModel.fromJson(Map<String, dynamic> json) {
    return ProposalModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      votingDeadline: _parseDateTime(json['voting_deadline']),
      minVotesRequired: json['min_votes_required'] as int? ?? 1,
      autoConfirm: json['auto_confirm'] as bool? ?? true,
      status: ProposalStatus.fromString(json['status'] as String? ?? 'voting'),
      confirmedTimeOptionId: json['confirmed_time_option_id'] as String?,
      confirmedEventId: json['confirmed_event_id'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? _parseDateTime(json['updated_at'])
          : null,
      creatorName: json['creator_name'] as String?,
      timeOptions: json['time_options'] != null
          ? (json['time_options'] as List)
              .map((e) => ProposalTimeOption.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      totalVoters: json['total_votes'] as int?,
      userHasVoted: json['user_has_voted'] as bool?,
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

  /// Convert to JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'created_by': createdBy,
      'title': title,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      'voting_deadline': TimezoneUtils.toUtcString(votingDeadline),
      'min_votes_required': minVotesRequired,
      'auto_confirm': autoConfirm,
      'status': status.name,
    };
  }

  /// Create a copy with modified fields
  ProposalModel copyWith({
    String? id,
    String? groupId,
    String? createdBy,
    String? title,
    String? description,
    String? location,
    DateTime? votingDeadline,
    int? minVotesRequired,
    bool? autoConfirm,
    ProposalStatus? status,
    String? confirmedTimeOptionId,
    String? confirmedEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorName,
    List<ProposalTimeOption>? timeOptions,
    int? totalVoters,
    bool? userHasVoted,
  }) {
    return ProposalModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      votingDeadline: votingDeadline ?? this.votingDeadline,
      minVotesRequired: minVotesRequired ?? this.minVotesRequired,
      autoConfirm: autoConfirm ?? this.autoConfirm,
      status: status ?? this.status,
      confirmedTimeOptionId: confirmedTimeOptionId ?? this.confirmedTimeOptionId,
      confirmedEventId: confirmedEventId ?? this.confirmedEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorName: creatorName ?? this.creatorName,
      timeOptions: timeOptions ?? this.timeOptions,
      totalVoters: totalVoters ?? this.totalVoters,
      userHasVoted: userHasVoted ?? this.userHasVoted,
    );
  }

  @override
  String toString() {
    return 'ProposalModel(id: $id, title: $title, status: $status, deadline: $votingDeadline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProposalModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
