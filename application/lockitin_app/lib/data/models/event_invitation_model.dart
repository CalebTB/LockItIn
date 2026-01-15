import 'package:equatable/equatable.dart';
import '../../core/utils/timezone_utils.dart';

/// RSVP status for event invitations
enum RSVPStatus {
  pending,   // Not yet responded
  accepted,  // User confirmed attendance
  declined,  // User declined invitation
  maybe,     // User is tentative
}

/// Event invitation model for Quick Event RSVP tracking
/// Matches Supabase event_invitations table
class EventInvitationModel extends Equatable {
  final String id;
  final String eventId;
  final String userId;
  final RSVPStatus rsvpStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EventInvitationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rsvpStatus,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create EventInvitationModel from Supabase JSON
  factory EventInvitationModel.fromJson(Map<String, dynamic> json) {
    return EventInvitationModel(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      rsvpStatus: _rsvpStatusFromString(json['rsvp_status'] as String),
      createdAt: TimezoneUtils.parseUtc(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtc(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert EventInvitationModel to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'rsvp_status': _rsvpStatusToString(rsvpStatus),
      'created_at': TimezoneUtils.toUtcString(createdAt),
      'updated_at': updatedAt != null ? TimezoneUtils.toUtcString(updatedAt!) : null,
    };
  }

  /// Convert RSVP status enum to string
  static String _rsvpStatusToString(RSVPStatus status) {
    switch (status) {
      case RSVPStatus.pending:
        return 'pending';
      case RSVPStatus.accepted:
        return 'accepted';
      case RSVPStatus.declined:
        return 'declined';
      case RSVPStatus.maybe:
        return 'maybe';
    }
  }

  /// Convert string to RSVP status enum
  static RSVPStatus _rsvpStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RSVPStatus.pending;
      case 'accepted':
        return RSVPStatus.accepted;
      case 'declined':
        return RSVPStatus.declined;
      case 'maybe':
        return RSVPStatus.maybe;
      default:
        return RSVPStatus.pending;
    }
  }

  /// Create a copy with updated fields
  EventInvitationModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    RSVPStatus? rsvpStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventInvitationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        rsvpStatus,
        createdAt,
        updatedAt,
      ];

  /// Helper: Check if invitation is pending
  bool get isPending => rsvpStatus == RSVPStatus.pending;

  /// Helper: Check if invitation is accepted
  bool get isAccepted => rsvpStatus == RSVPStatus.accepted;

  /// Helper: Check if invitation is declined
  bool get isDeclined => rsvpStatus == RSVPStatus.declined;

  /// Helper: Check if invitation is maybe
  bool get isMaybe => rsvpStatus == RSVPStatus.maybe;

  /// Get user-friendly RSVP status label
  String get statusLabel {
    switch (rsvpStatus) {
      case RSVPStatus.pending:
        return 'Not Responded';
      case RSVPStatus.accepted:
        return 'Going';
      case RSVPStatus.declined:
        return 'Can\'t Go';
      case RSVPStatus.maybe:
        return 'Maybe';
    }
  }
}
