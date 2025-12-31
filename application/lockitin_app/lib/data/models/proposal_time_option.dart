/// Represents a time option for a group proposal
/// Users vote on multiple time options to find the best meeting time
class ProposalTimeOption {
  final String? id;
  final DateTime startTime;
  final DateTime endTime;
  final int voteCount;
  final bool isSelected;

  const ProposalTimeOption({
    this.id,
    required this.startTime,
    required this.endTime,
    this.voteCount = 0,
    this.isSelected = false,
  });

  /// Create a copy with modified fields
  ProposalTimeOption copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? voteCount,
    bool? isSelected,
  }) {
    return ProposalTimeOption(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      voteCount: voteCount ?? this.voteCount,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Get the duration of this time option
  Duration get duration => endTime.difference(startTime);

  /// Check if two time options overlap
  bool overlapsWith(ProposalTimeOption other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'vote_count': voteCount,
    };
  }

  /// Create from JSON
  factory ProposalTimeOption.fromJson(Map<String, dynamic> json) {
    return ProposalTimeOption(
      id: json['id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      voteCount: json['vote_count'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'ProposalTimeOption(startTime: $startTime, endTime: $endTime, voteCount: $voteCount)';
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
