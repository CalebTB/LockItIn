import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/event_indexer.dart';
import '../../core/utils/logger.dart';
import '../../data/models/event_model.dart';
import '../../data/repositories/calendar_repository.dart';

/// Provider for personal calendar state management
///
/// Manages personal calendar events with:
/// - Repository pattern for data access
/// - Version-based caching (handled by repository)
/// - Comprehensive error handling (preserves stale data)
/// - Loading/error/data states for reactive UI
class PersonalCalendarProvider extends ChangeNotifier {
  final CalendarRepository _repository;

  // State
  Map<String, List<EventModel>> _indexedEvents = {};
  bool _isLoading = false;
  String? _error;

  PersonalCalendarProvider(this._repository);

  // Getters
  Map<String, List<EventModel>> get indexedEvents => _indexedEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasData => _indexedEvents.isNotEmpty;

  /// Get events for a specific day
  List<EventModel> getEventsForDay(DateTime day) {
    return EventIndexer.getEventsForDay(_indexedEvents, day);
  }

  /// Get all events sorted by start time
  List<EventModel> getAllEvents() {
    return EventIndexer.getAllEvents(_indexedEvents);
  }

  /// Get upcoming events (future events only)
  List<EventModel> getUpcomingEvents({DateTime? fromDate, int? limit}) {
    return EventIndexer.getUpcomingEvents(
      _indexedEvents,
      fromDate: fromDate,
      limit: limit,
    );
  }

  /// Check if a specific day has events
  bool hasEventsForDay(DateTime day) {
    return EventIndexer.hasEventsForDay(_indexedEvents, day);
  }

  /// Fetch personal calendar events for date range
  ///
  /// Comprehensive error handling:
  /// - PostgrestException: Database errors (RLS, permissions, invalid data)
  /// - SocketException: Network errors (offline, timeout)
  /// - Generic exceptions: Unexpected errors
  ///
  /// On error:
  /// - Sets error message for UI display
  /// - Preserves stale data (doesn't clear existing events)
  /// - Sets loading to false
  /// - Notifies listeners for UI update
  Future<void> fetchEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final events = await _repository.getPersonalEvents(
        startDate: startDate,
        endDate: endDate,
      );

      _indexedEvents = EventIndexer.groupByDate(events);
      _isLoading = false;
      _error = null;
      notifyListeners();

      Logger.debug('PersonalCalendarProvider',
          'Fetched ${events.length} personal events');
    } on PostgrestException catch (e) {
      // Database errors (RLS failures, permission denied, invalid data)
      final errorMessage = 'Database error: ${e.message}';
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();

      Logger.error(
          'PersonalCalendarProvider', 'PostgrestException: ${e.message}');

      // Preserve stale data - don't clear _indexedEvents
    } on SocketException catch (e) {
      // Network errors (offline, timeout, connection refused)
      final errorMessage = 'Network error: Check your connection';
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();

      Logger.error('PersonalCalendarProvider', 'SocketException: ${e.message}');

      // Preserve stale data - don't clear _indexedEvents
    } catch (e, stackTrace) {
      // Unexpected errors
      final errorMessage = 'Unexpected error: $e';
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();

      Logger.error(
          'PersonalCalendarProvider', 'Unexpected error: $e', stackTrace);

      // Preserve stale data - don't clear _indexedEvents
    }
  }

  /// Refresh personal calendar (for pull-to-refresh)
  ///
  /// Same as fetchEvents but clears error state first.
  Future<void> refresh({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _error = null; // Clear error before refresh
    await fetchEvents(startDate: startDate, endDate: endDate);
  }

  /// Clear error state
  ///
  /// Call this when user dismisses error banner or retries.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.disposeWatchers();
    super.dispose();
  }
}
