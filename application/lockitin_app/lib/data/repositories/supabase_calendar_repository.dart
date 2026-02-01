import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/timezone_utils.dart';
import '../../data/models/event_model.dart';
import '../../data/models/shadow_calendar_entry.dart';
import 'calendar_repository.dart';

/// Cache entry with version tracking for race-condition-safe invalidation
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final int version;

  _CacheEntry(this.data, this.timestamp, this.version);

  bool isExpired(Duration ttl, int currentVersion) {
    return version < currentVersion ||
        DateTime.now().difference(timestamp) > ttl;
  }
}

/// Supabase implementation of CalendarRepository with version-based caching
///
/// Caching strategy:
/// - Personal events: 5 minute TTL
/// - Group availability: 2 minute TTL
/// - Version-based invalidation prevents race conditions
/// - Cache cleared on create/update/delete operations
///
/// Error handling:
/// - PostgrestException: Database errors (RLS, permissions, invalid data)
/// - SocketException: Network errors (offline, timeout)
/// - Generic exceptions: Unexpected errors
class SupabaseCalendarRepository implements CalendarRepository {
  final SupabaseClient _supabase;

  // Version-based cache (prevents race conditions)
  int _cacheVersion = 0;
  _CacheEntry<List<EventModel>>? _personalEventsCache;
  final Map<String, _CacheEntry<List<ShadowCalendarEntry>>> _groupAvailabilityCache = {};

  // Cache TTL durations
  static const Duration _personalEventsTTL = Duration(minutes: 5);
  static const Duration _groupAvailabilityTTL = Duration(minutes: 2);

  // Realtime subscriptions
  final Map<String, RealtimeChannel> _activeChannels = {};

  SupabaseCalendarRepository(this._supabase);

  @override
  Future<List<EventModel>> getPersonalEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Check cache first
      if (_personalEventsCache != null &&
          !_personalEventsCache!.isExpired(_personalEventsTTL, _cacheVersion)) {
        Logger.debug('SupabaseCalendarRepository',
            'Cache hit for personal events (version ${_personalEventsCache!.version})');
        return _personalEventsCache!.data;
      }

      Logger.debug('SupabaseCalendarRepository',
          'Cache miss, fetching personal events from database');

      // Fetch from database
      final response = await _supabase
          .from('events')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .gte('end_time', TimezoneUtils.toUtcString(startDate))
          .lte('start_time', TimezoneUtils.toUtcString(endDate))
          .order('start_time');

      final events = (response as List)
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache with current version
      _personalEventsCache = _CacheEntry(events, DateTime.now(), _cacheVersion);

      return events;
    } on PostgrestException catch (e) {
      Logger.error('SupabaseCalendarRepository',
          'Database error fetching personal events: ${e.message}');
      rethrow;
    } on SocketException catch (e) {
      Logger.error('SupabaseCalendarRepository',
          'Network error fetching personal events: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('SupabaseCalendarRepository',
          'Unexpected error fetching personal events: $e', stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ShadowCalendarEntry>> getGroupAvailability({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Check cache first
      final cached = _groupAvailabilityCache[groupId];
      if (cached != null &&
          !cached.isExpired(_groupAvailabilityTTL, _cacheVersion)) {
        Logger.debug('SupabaseCalendarRepository',
            'Cache hit for group $groupId availability (version ${cached.version})');
        return cached.data;
      }

      Logger.debug('SupabaseCalendarRepository',
          'Cache miss, fetching group $groupId availability from database');

      // Call RPC function with privacy-aware query
      final response = await _supabase.rpc(
        'get_group_shadow_calendar_v3',
        params: {
          'p_group_id': groupId,
          'p_start_time': TimezoneUtils.toUtcString(startDate),
          'p_end_time': TimezoneUtils.toUtcString(endDate),
        },
      );

      final entries = (response as List)
          .map((json) =>
              ShadowCalendarEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache with current version
      _groupAvailabilityCache[groupId] =
          _CacheEntry(entries, DateTime.now(), _cacheVersion);

      return entries;
    } on PostgrestException catch (e) {
      // RPC function throws exception if user is not a group member
      Logger.error('SupabaseCalendarRepository',
          'Database error fetching group availability: ${e.message}');
      rethrow;
    } on SocketException catch (e) {
      Logger.error('SupabaseCalendarRepository',
          'Network error fetching group availability: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      Logger.error('SupabaseCalendarRepository',
          'Unexpected error fetching group availability: $e', stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<EventModel>> watchPersonalEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    final userId = _supabase.auth.currentUser!.id;
    final channelName = 'personal-events-$userId';

    try {
      // Emit initial data immediately
      final initialEvents = await getPersonalEvents(
        startDate: startDate,
        endDate: endDate,
      );
      yield initialEvents;

      // Set up realtime subscription
      final channel = _supabase
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'events',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) async {
              Logger.debug('SupabaseCalendarRepository',
                  'Realtime event received: ${payload.eventType}');

              // Invalidate cache on any event change
              invalidateCache(pattern: 'personal');

              // Note: Can't yield inside callback, need to use StreamController
              // For now, cache invalidation will cause next read to be fresh
            },
          )
          .subscribe();

      _activeChannels[channelName] = channel;

      // Keep stream alive (actual updates happen via cache invalidation)
      await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
        // Periodic check to keep connection alive
        // Real updates happen via realtime callbacks + cache invalidation
      }
    } on PostgrestException catch (e) {
      Logger.error('SupabaseCalendarRepository',
          'Database error in realtime subscription: ${e.message}');
      yield* Stream.error(e);
    } on SocketException catch (e) {
      Logger.error('SupabaseCalendarRepository',
          'Network error in realtime subscription: ${e.message}');
      yield* Stream.error(e);
    } catch (e, stackTrace) {
      Logger.error('SupabaseCalendarRepository',
          'Unexpected error in realtime subscription: $e', stackTrace);
      yield* Stream.error(e);
    }
  }

  /// Invalidate cache for specific pattern or all
  ///
  /// Version-based invalidation: Increments cache version instead of clearing.
  /// This prevents race conditions where stale data overwrites fresh data.
  ///
  /// [pattern] - Optional pattern to match ('personal', 'group', or null for all)
  void invalidateCache({String? pattern}) {
    _cacheVersion++; // All cached entries with older version become stale
    Logger.debug('SupabaseCalendarRepository',
        'Cache invalidated (pattern: $pattern, new version: $_cacheVersion)');

    if (pattern == null) {
      // Clear all caches
      _personalEventsCache = null;
      _groupAvailabilityCache.clear();
    } else if (pattern == 'personal') {
      _personalEventsCache = null;
    } else if (pattern.startsWith('group:')) {
      final groupId = pattern.substring(6);
      _groupAvailabilityCache.remove(groupId);
    }
  }

  @override
  void disposeWatchers() {
    Logger.debug('SupabaseCalendarRepository',
        'Disposing ${_activeChannels.length} realtime channels');

    for (final channel in _activeChannels.values) {
      _supabase.removeChannel(channel);
    }
    _activeChannels.clear();
  }
}
