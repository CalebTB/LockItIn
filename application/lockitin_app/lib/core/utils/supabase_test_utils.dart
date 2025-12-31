import '../network/supabase_client.dart';
import '../utils/logger.dart';

/// Utility class for testing Supabase connection and database setup
/// Use this to verify your Supabase configuration is working correctly
class SupabaseTestUtils {
  static const _tag = 'SupabaseTest';

  /// Test the basic Supabase connection
  ///
  /// Returns true if connection is successful, false otherwise
  static Future<bool> testConnection() async {
    try {
      Logger.info(_tag, 'Testing Supabase connection...');

      // Attempt a simple query to verify connection
      final response = await SupabaseClientManager.client
          .from('events')
          .select('id')
          .limit(1);

      Logger.info(_tag, '✅ Supabase connection successful');
      Logger.info(_tag, 'Response: $response');
      return true;
    } catch (e) {
      Logger.error(_tag, '❌ Supabase connection failed: $e');
      return false;
    }
  }

  /// Test authentication status
  ///
  /// Returns true if user is authenticated, false otherwise
  static Future<bool> testAuth() async {
    try {
      Logger.info(_tag, 'Testing Supabase authentication...');

      final user = SupabaseClientManager.currentUser;
      final userId = SupabaseClientManager.currentUserId;
      final isAuthenticated = SupabaseClientManager.isAuthenticated;

      Logger.info(_tag, 'Is Authenticated: $isAuthenticated');
      Logger.info(_tag, 'User ID: $userId');
      Logger.info(_tag, 'User Email: ${user?.email}');

      if (isAuthenticated) {
        Logger.info(_tag, '✅ User is authenticated');
      } else {
        Logger.warning(_tag, '⚠️  User is not authenticated (anonymous mode)');
      }

      return isAuthenticated;
    } catch (e) {
      Logger.error(_tag, '❌ Authentication test failed: $e');
      return false;
    }
  }

  /// Test the events table exists and has correct structure
  ///
  /// Returns true if table is accessible, false otherwise
  static Future<bool> testEventsTable() async {
    try {
      Logger.info(_tag, 'Testing events table...');

      // Try to query the events table
      final response = await SupabaseClientManager.client
          .from('events')
          .select('*')
          .limit(1);

      Logger.info(_tag, '✅ Events table accessible');
      Logger.info(_tag, 'Sample query result: $response');
      return true;
    } catch (e) {
      Logger.error(_tag, '❌ Events table test failed: $e');
      Logger.error(
        _tag,
        'This might mean:\n'
        '  1. The events table doesn\'t exist in your Supabase database\n'
        '  2. Row Level Security (RLS) is blocking access\n'
        '  3. Your Supabase credentials are incorrect',
      );
      return false;
    }
  }

  /// Test inserting and deleting a test event
  ///
  /// Returns true if insert/delete works, false otherwise
  static Future<bool> testInsertAndDelete() async {
    try {
      Logger.info(_tag, 'Testing event insert/delete...');

      final testEvent = {
        'user_id': SupabaseClientManager.currentUserId ?? 'test_user',
        'title': 'Test Event - Delete Me',
        'start_time': DateTime.now().toIso8601String(),
        'end_time': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'visibility': 'private',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert test event
      Logger.info(_tag, 'Inserting test event...');
      final insertResponse = await SupabaseClientManager.client
          .from('events')
          .insert(testEvent)
          .select()
          .single();

      final testEventId = insertResponse['id'];
      Logger.info(_tag, '✅ Test event inserted with ID: $testEventId');

      // Delete test event
      Logger.info(_tag, 'Deleting test event...');
      await SupabaseClientManager.client
          .from('events')
          .delete()
          .eq('id', testEventId);

      Logger.info(_tag, '✅ Test event deleted successfully');
      Logger.info(_tag, '✅ Insert/Delete test passed');
      return true;
    } catch (e) {
      Logger.error(_tag, '❌ Insert/Delete test failed: $e');
      Logger.error(
        _tag,
        'This might mean:\n'
        '  1. RLS policies are preventing insert/delete\n'
        '  2. Required columns are missing from the events table\n'
        '  3. Authentication is required for these operations',
      );
      return false;
    }
  }

  /// Run all Supabase tests
  ///
  /// Returns a map with test results
  static Future<Map<String, bool>> runAllTests() async {
    Logger.info(_tag, '🧪 Running Supabase diagnostic tests...\n');

    final results = <String, bool>{};

    // Test 1: Connection
    results['connection'] = await testConnection();
    Logger.info(_tag, '');

    // Test 2: Authentication
    results['authentication'] = await testAuth();
    Logger.info(_tag, '');

    // Test 3: Events Table
    results['events_table'] = await testEventsTable();
    Logger.info(_tag, '');

    // Test 4: Insert/Delete (only if previous tests passed)
    if (results['connection'] == true && results['events_table'] == true) {
      results['insert_delete'] = await testInsertAndDelete();
    } else {
      Logger.warning(_tag, '⚠️  Skipping insert/delete test (prerequisites failed)');
      results['insert_delete'] = false;
    }

    Logger.info(_tag, '');
    Logger.info(_tag, '📊 Test Results Summary:');
    Logger.info(_tag, '─────────────────────────────────');
    results.forEach((test, passed) {
      final icon = passed ? '✅' : '❌';
      Logger.info(_tag, '$icon $test: ${passed ? 'PASSED' : 'FAILED'}');
    });
    Logger.info(_tag, '─────────────────────────────────');

    final allPassed = results.values.every((result) => result);
    if (allPassed) {
      Logger.info(_tag, '🎉 All tests passed! Supabase is ready to use.');
    } else {
      Logger.warning(_tag, '⚠️  Some tests failed. Check the logs above for details.');
    }

    return results;
  }

  /// Get Supabase configuration info (for debugging)
  static Map<String, String> getConfigInfo() {
    return {
      'Is Authenticated': SupabaseClientManager.isAuthenticated.toString(),
      'User ID': SupabaseClientManager.currentUserId ?? 'Not authenticated',
      'User Email': SupabaseClientManager.currentUser?.email ?? 'Not authenticated',
    };
  }

  /// Print configuration info
  static void printConfigInfo() {
    Logger.info(_tag, '📋 Supabase Configuration:');
    Logger.info(_tag, '─────────────────────────────────');
    getConfigInfo().forEach((key, value) {
      Logger.info(_tag, '$key: $value');
    });
    Logger.info(_tag, '─────────────────────────────────');
  }
}
