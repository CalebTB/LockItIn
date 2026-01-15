import 'package:equatable/equatable.dart';
import '../../core/utils/timezone_utils.dart';

/// Represents an availability block from the shadow calendar
/// Used for group availability queries without exposing full event details
class ShadowCalendarEntry extends Equatable {
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final ShadowVisibility visibility;
  final String? eventTitle; // Only present for sharedWithName
  final bool isGroupEvent; // True if this event belongs to the requesting group

  const ShadowCalendarEntry({
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.visibility,
    this.eventTitle,
    this.isGroupEvent = false,
  });

  /// Create from Supabase RPC response
  factory ShadowCalendarEntry.fromJson(Map<String, dynamic> json) {
    return ShadowCalendarEntry(
      userId: json['user_id'] as String,
      startTime: TimezoneUtils.parseUtc(json['start_time'] as String),
      endTime: TimezoneUtils.parseUtc(json['end_time'] as String),
      visibility: _visibilityFromString(json['visibility'] as String),
      eventTitle: json['event_title'] as String?,
      isGroupEvent: json['is_group_event'] as bool? ?? false,
    );
  }

  static ShadowVisibility _visibilityFromString(String visibility) {
    switch (visibility) {
      case 'sharedWithName':
        return ShadowVisibility.sharedWithName;
      case 'busyOnly':
        return ShadowVisibility.busyOnly;
      default:
        return ShadowVisibility.busyOnly;
    }
  }

  /// Whether this entry represents a "busy" block (hides event details)
  bool get isBusyOnly => visibility == ShadowVisibility.busyOnly;

  /// Display text for this entry
  /// Returns event title for sharedWithName, "Busy" for busyOnly
  String get displayText => isBusyOnly ? 'Busy' : (eventTitle ?? 'Busy');

  @override
  List<Object?> get props => [userId, startTime, endTime, visibility, eventTitle, isGroupEvent];
}

/// Shadow calendar visibility levels
enum ShadowVisibility {
  busyOnly,       // Show as "Busy" without details
  sharedWithName, // Show event title
}
