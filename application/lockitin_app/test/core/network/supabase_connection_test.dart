import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/network/supabase_client.dart';
import 'package:lockitin_app/core/utils/supabase_test_utils.dart';

/// Integration tests for Supabase connection
///
/// These tests require:
/// 1. Supabase to be initialized (call SupabaseClientManager.initialize() first)
/// 2. Valid Supabase credentials in supabase_config.dart
/// 3. The events table to exist in your Supabase database
///
/// Run these tests manually to verify your Supabase setup:
/// ```
/// flutter test test/core/network/supabase_connection_test.dart
/// ```
void main() {
  group('Supabase Connection Tests', () {
    setUpAll(() async {
      // Initialize Supabase before running tests
      // Note: In a real app, this is done in main.dart
      try {
        await SupabaseClientManager.initialize();
      } catch (e) {
        print('Supabase initialization failed: $e');
        print('This is expected if running without proper setup');
      }
    });

    test('Supabase should be initialized', () {
      expect(() => SupabaseClientManager.client, returnsNormally);
    });

    test('Config info should be retrievable', () {
      final config = SupabaseTestUtils.getConfigInfo();
      expect(config, isNotEmpty);
      expect(config.containsKey('Supabase URL'), true);
      expect(config.containsKey('Is Authenticated'), true);
    });

    // Note: The following tests will fail if:
    // - Supabase is not properly configured
    // - The events table doesn't exist
    // - RLS policies are blocking access
    // These are expected to fail in CI/CD - they're for manual verification

    test('Basic connection test', () async {
      final result = await SupabaseTestUtils.testConnection();
      // This might fail if not connected to internet or Supabase is down
      // Don't enforce this in automated tests
      print('Connection test result: $result');
    }, skip: 'Manual verification only');

    test('Events table test', () async {
      final result = await SupabaseTestUtils.testEventsTable();
      print('Events table test result: $result');
    }, skip: 'Manual verification only');

    test('Authentication test', () async {
      final result = await SupabaseTestUtils.testAuth();
      print('Authentication test result: $result');
    }, skip: 'Manual verification only');

    test('Insert/Delete test', () async {
      final result = await SupabaseTestUtils.testInsertAndDelete();
      print('Insert/Delete test result: $result');
    }, skip: 'Manual verification only');
  });

  group('Supabase Comprehensive Diagnostic', () {
    test('Run all diagnostic tests', () async {
      try {
        await SupabaseClientManager.initialize();
      } catch (e) {
        print('Initialization error: $e');
      }

      SupabaseTestUtils.printConfigInfo();
      print('');

      final results = await SupabaseTestUtils.runAllTests();

      // Print results
      print('');
      print('Test Results:');
      results.forEach((test, passed) {
        print('  $test: ${passed ? "✅ PASS" : "❌ FAIL"}');
      });
    }, skip: 'Manual verification only - enable this to run full diagnostics');
  });
}
