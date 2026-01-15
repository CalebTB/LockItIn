import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Template for a Provider with Supabase realtime subscription
///
/// Features:
/// - Fetch initial data from Supabase
/// - Subscribe to realtime updates via WebSocket
/// - Handle connection failures with automatic reconnection
/// - Fallback to polling if realtime fails
/// - Proper lifecycle management and cleanup
/// - Error handling with user-friendly messages
///
/// Usage:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => YourDataProvider()..subscribe(id),
///   child: Consumer<YourDataProvider>(
///     builder: (context, provider, _) {
///       if (provider.isLoading) return LoadingIndicator();
///       if (provider.error != null) return ErrorMessage(provider.error!);
///       return DataList(items: provider.items);
///     },
///   ),
/// )
/// ```
class DataProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // State
  List<DataModel> _items = [];
  bool _isLoading = false;
  String? _error;

  // Realtime
  RealtimeChannel? _channel;
  bool _isRealtimeActive = false;

  // Reconnection & Fallback
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  String? _currentId;

  // Getters
  List<DataModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRealtimeActive => _isRealtimeActive;

  /// Subscribe to data for given ID
  Future<void> subscribe(String id) async {
    _currentId = id;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch initial data
      await _fetchData();

      // 2. Setup realtime subscription
      _setupRealtimeSubscription(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = _getUserFriendlyError(e);
      _isLoading = false;
      notifyListeners();

      // Fallback to polling on error
      _startPolling();
    }
  }

  /// Fetch data from Supabase
  Future<void> _fetchData() async {
    if (_currentId == null) return;

    final data = await _supabase
        .from('your_table')
        .select('*')
        .eq('filter_column', _currentId)
        .order('created_at', ascending: false);

    _items = data.map((json) => DataModel.fromJson(json)).toList();
  }

  /// Setup realtime subscription with error handling
  void _setupRealtimeSubscription(String id) {
    try {
      _channel = _supabase
          .channel('your-channel:$id')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'your_table',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'filter_column',
              value: id,
            ),
            callback: _handleRealtimeUpdate,
          )
          .subscribe((status, error) {
        if (status == RealtimeListenTypes.subscribed) {
          _isRealtimeActive = true;
          _stopPolling(); // Stop fallback polling
          notifyListeners();
        } else if (status == RealtimeListenTypes.closed) {
          _isRealtimeActive = false;
          _scheduleReconnect();
          _startPolling(); // Fallback to polling
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Realtime subscription failed: $e');
      _startPolling(); // Immediate fallback
    }
  }

  /// Handle realtime updates (optimistic updates)
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.update) {
      final index = _items.indexWhere(
        (item) => item.id == payload.newRecord['id'],
      );
      if (index != -1) {
        _items[index] = DataModel.fromJson(payload.newRecord);
        notifyListeners();
      }
    } else if (payload.eventType == PostgresChangeEvent.insert) {
      _items.add(DataModel.fromJson(payload.newRecord));
      notifyListeners();
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      _items.removeWhere((item) => item.id == payload.oldRecord['id']);
      notifyListeners();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentId != null) {
        _setupRealtimeSubscription(_currentId!);
      }
    });
  }

  /// Start polling as fallback (when realtime fails)
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isRealtimeActive) {
        try {
          await _fetchData();
          notifyListeners();
        } catch (e) {
          debugPrint('Polling failed: $e');
        }
      }
    });
  }

  /// Stop polling
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Refresh data manually
  Future<void> refresh() async {
    _error = null;
    try {
      await _fetchData();
      notifyListeners();
    } catch (e) {
      _error = _getUserFriendlyError(e);
      notifyListeners();
    }
  }

  /// Convert error to user-friendly message
  String _getUserFriendlyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('rate_limit')) {
      return 'Too many requests. Please wait a moment.';
    } else if (errorStr.contains('network')) {
      return 'Network connection lost. Please check your internet.';
    } else if (errorStr.contains('permission') || errorStr.contains('rls')) {
      return 'You don\'t have permission to view this data.';
    } else if (errorStr.contains('unique')) {
      return 'This item already exists.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    // Clean up subscriptions and timers
    _channel?.unsubscribe();
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}

/// Example data model
class DataModel {
  final String id;
  final String name;
  final DateTime createdAt;

  DataModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
