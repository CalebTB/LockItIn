import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../data/models/shadow_calendar_entry.dart';
import '../../data/repositories/calendar_repository.dart';

/// Provider for group calendar state management
///
/// Manages group availability (shadow calendar) with:
/// - Repository pattern for data access
/// - Per-group caching (handled by repository)
/// - Comprehensive error handling (preserves stale data)
/// - Loading/error/data states for reactive UI
///
/// Used by group detail screen and group availability heatmap.
class GroupCalendarProvider extends ChangeNotifier {
  final CalendarRepository _repository;

  // State (per-group)
  final Map<String, List<ShadowCalendarEntry>> _availabilityByGroup = {};
  final Map<String, bool> _loadingByGroup = {};
  final Map<String, String?> _errorByGroup = {};

  GroupCalendarProvider(this._repository);

  // Getters for specific group
  List<ShadowCalendarEntry> getAvailability(String groupId) {
    return _availabilityByGroup[groupId] ?? [];
  }

  bool isLoading(String groupId) {
    return _loadingByGroup[groupId] ?? false;
  }

  String? getError(String groupId) {
    return _errorByGroup[groupId];
  }

  bool hasError(String groupId) {
    return _errorByGroup[groupId] != null;
  }

  bool hasData(String groupId) {
    return _availabilityByGroup[groupId]?.isNotEmpty ?? false;
  }

  /// Get availability entries for a specific user within a group
  ///
  /// Used to highlight which members are free/busy at a given time.
  List<ShadowCalendarEntry> getAvailabilityForUser(
    String groupId,
    String userId,
  ) {
    final availability = _availabilityByGroup[groupId] ?? [];
    return availability.where((entry) => entry.userId == userId).toList();
  }

  /// Get all unique user IDs in group availability data
  ///
  /// Used to render member list in group calendar views.
  Set<String> getUserIds(String groupId) {
    final availability = _availabilityByGroup[groupId] ?? [];
    return availability.map((entry) => entry.userId).toSet();
  }

  /// Check if a specific user is busy at a given time
  ///
  /// Used for availability heatmap calculations.
  bool isUserBusy(String groupId, String userId, DateTime time) {
    final userAvailability = getAvailabilityForUser(groupId, userId);
    return userAvailability.any(
      (entry) =>
          time.isAfter(entry.startTime) && time.isBefore(entry.endTime),
    );
  }

  /// Fetch group availability for date range
  ///
  /// Comprehensive error handling:
  /// - PostgrestException: Database errors (RLS, not a member, invalid data)
  /// - SocketException: Network errors (offline, timeout)
  /// - Generic exceptions: Unexpected errors
  ///
  /// On error:
  /// - Sets error message for UI display
  /// - Preserves stale data (doesn't clear existing availability)
  /// - Sets loading to false
  /// - Notifies listeners for UI update
  Future<void> fetchAvailability({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _loadingByGroup[groupId] = true;
    _errorByGroup[groupId] = null;
    notifyListeners();

    try {
      final availability = await _repository.getGroupAvailability(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

      _availabilityByGroup[groupId] = availability;
      _loadingByGroup[groupId] = false;
      _errorByGroup[groupId] = null;
      notifyListeners();

      Logger.debug('GroupCalendarProvider',
          'Fetched ${availability.length} shadow calendar entries for group $groupId');
    } on PostgrestException catch (e) {
      // Database errors (RLS failures, not a member, permission denied)
      final errorMessage = e.message.contains('Access denied')
          ? 'Access denied: Not a member of this group'
          : 'Database error: ${e.message}';

      _errorByGroup[groupId] = errorMessage;
      _loadingByGroup[groupId] = false;
      notifyListeners();

      Logger.error(
          'GroupCalendarProvider', 'PostgrestException for group $groupId: ${e.message}');

      // Preserve stale data - don't clear _availabilityByGroup[groupId]
    } on SocketException catch (e) {
      // Network errors (offline, timeout, connection refused)
      final errorMessage = 'Network error: Check your connection';
      _errorByGroup[groupId] = errorMessage;
      _loadingByGroup[groupId] = false;
      notifyListeners();

      Logger.error('GroupCalendarProvider',
          'SocketException for group $groupId: ${e.message}');

      // Preserve stale data - don't clear _availabilityByGroup[groupId]
    } catch (e, stackTrace) {
      // Unexpected errors
      final errorMessage = 'Unexpected error: $e';
      _errorByGroup[groupId] = errorMessage;
      _loadingByGroup[groupId] = false;
      notifyListeners();

      Logger.error('GroupCalendarProvider',
          'Unexpected error for group $groupId: $e', stackTrace);

      // Preserve stale data - don't clear _availabilityByGroup[groupId]
    }
  }

  /// Refresh group availability (for pull-to-refresh)
  ///
  /// Same as fetchAvailability but clears error state first.
  Future<void> refresh({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _errorByGroup[groupId] = null; // Clear error before refresh
    await fetchAvailability(
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Clear error state for specific group
  ///
  /// Call this when user dismisses error banner or retries.
  void clearError(String groupId) {
    _errorByGroup[groupId] = null;
    notifyListeners();
  }

  /// Clear all data for specific group
  ///
  /// Call this when user leaves a group or group is deleted.
  void clearGroup(String groupId) {
    _availabilityByGroup.remove(groupId);
    _loadingByGroup.remove(groupId);
    _errorByGroup.remove(groupId);
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.disposeWatchers();
    super.dispose();
  }
}
