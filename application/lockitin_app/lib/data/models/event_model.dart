import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/timezone_utils.dart';

/// Event privacy visibility settings
enum EventVisibility {
  private, // Hidden from all groups
  sharedWithName, // Groups see event title & time
  busyOnly, // Groups see "busy" block without details
}

/// Event category for color coding and organization
enum EventCategory {
  work, // Work-related events (green)
  holiday, // Holidays and special occasions (red)
  friend, // Social events with friends (purple)
  other, // Everything else (yellow)
}

/// Event model matching Supabase events table
class EventModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final EventVisibility visibility;
  final EventCategory category;
  final String? emoji; // Custom emoji for the event icon
  final String? nativeCalendarId; // iOS EventKit or Android CalendarContract ID
  final bool allDay; // True if this is an all-day event (no specific time)
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EventModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.visibility,
    this.category = EventCategory.other,
    this.emoji,
    this.nativeCalendarId,
    this.allDay = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create EventModel from Supabase JSON
  /// Times are stored in UTC (timestamptz), all-day events stored as local midnight
  factory EventModel.fromJson(Map<String, dynamic> json) {
    final allDay = json['all_day'] as bool? ?? false;

    return EventModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      // All-day events: Keep as local midnight (no UTC conversion)
      // Timed events: Parse as UTC
      startTime: allDay
          ? DateTime.parse(json['start_time'] as String)
          : TimezoneUtils.parseUtc(json['start_time'] as String),
      endTime: allDay
          ? DateTime.parse(json['end_time'] as String)
          : TimezoneUtils.parseUtc(json['end_time'] as String),
      location: json['location'] as String?,
      visibility: _visibilityFromString(json['visibility'] as String),
      category: json['category'] != null
          ? _categoryFromString(json['category'] as String)
          : EventCategory.other,
      emoji: json['emoji'] as String?, // Local-only field, will be null from DB
      nativeCalendarId: json['native_calendar_id'] as String?,
      allDay: allDay,
      createdAt: TimezoneUtils.parseUtc(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtc(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert EventModel to JSON for Supabase
  /// Note: emoji is excluded as it's a local-only field (not in DB schema yet)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      // All-day events: Store as local midnight (no UTC conversion)
      // Timed events: Convert to UTC
      'start_time': allDay
          ? DateTime(startTime.year, startTime.month, startTime.day)
              .toIso8601String()
          : TimezoneUtils.toUtcString(startTime),
      'end_time': allDay
          ? DateTime(endTime.year, endTime.month, endTime.day)
              .toIso8601String()
          : TimezoneUtils.toUtcString(endTime),
      'location': location,
      'visibility': _visibilityToString(visibility),
      'category': _categoryToString(category),
      // 'emoji': emoji, // TODO: Add to Supabase schema when ready
      'native_calendar_id': nativeCalendarId,
      'all_day': allDay,
      'created_at': TimezoneUtils.toUtcString(createdAt),
      'updated_at': updatedAt != null ? TimezoneUtils.toUtcString(updatedAt!) : null,
    };
  }

  /// Convert visibility enum to string
  static String _visibilityToString(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.private:
        return AppConstants.privacyPrivate;
      case EventVisibility.sharedWithName:
        return AppConstants.privacySharedWithName;
      case EventVisibility.busyOnly:
        return AppConstants.privacyBusyOnly;
    }
  }

  /// Convert string to visibility enum
  static EventVisibility _visibilityFromString(String visibility) {
    switch (visibility) {
      case AppConstants.privacyPrivate:
        return EventVisibility.private;
      case AppConstants.privacySharedWithName:
        return EventVisibility.sharedWithName;
      case AppConstants.privacyBusyOnly:
        return EventVisibility.busyOnly;
      default:
        return EventVisibility.private;
    }
  }

  /// Convert category enum to string
  static String _categoryToString(EventCategory category) {
    switch (category) {
      case EventCategory.work:
        return 'work';
      case EventCategory.holiday:
        return 'holiday';
      case EventCategory.friend:
        return 'friend';
      case EventCategory.other:
        return 'other';
    }
  }

  /// Convert string to category enum
  static EventCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return EventCategory.work;
      case 'holiday':
        return EventCategory.holiday;
      case 'friend':
        return EventCategory.friend;
      case 'other':
        return EventCategory.other;
      default:
        return EventCategory.other;
    }
  }

  /// Create a copy with updated fields
  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    EventVisibility? visibility,
    EventCategory? category,
    String? emoji,
    String? nativeCalendarId,
    bool? allDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      visibility: visibility ?? this.visibility,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      nativeCalendarId: nativeCalendarId ?? this.nativeCalendarId,
      allDay: allDay ?? this.allDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        startTime,
        endTime,
        location,
        visibility,
        category,
        emoji,
        nativeCalendarId,
        allDay,
        createdAt,
        updatedAt,
      ];
}
