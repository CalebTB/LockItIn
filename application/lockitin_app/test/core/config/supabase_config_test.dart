import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    group('supabaseUrl', () {
      test('should be a valid URL', () {
        expect(SupabaseConfig.supabaseUrl, startsWith('https://'));
        expect(SupabaseConfig.supabaseUrl, contains('supabase.co'));
      });

      test('should not be empty', () {
        expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      });

      test('should not contain trailing slash', () {
        expect(SupabaseConfig.supabaseUrl, isNot(endsWith('/')));
      });
    });

    group('supabaseAnonKey', () {
      test('should be a JWT token', () {
        // JWT tokens have 3 parts separated by dots
        final parts = SupabaseConfig.supabaseAnonKey.split('.');
        expect(parts.length, 3);
      });

      test('should not be empty', () {
        expect(SupabaseConfig.supabaseAnonKey, isNotEmpty);
      });

      test('should start with expected JWT header', () {
        // Base64 encoded JWT header typically starts with 'ey'
        expect(SupabaseConfig.supabaseAnonKey, startsWith('ey'));
      });
    });

    group('enableDebugLogging', () {
      test('should be a boolean', () {
        expect(SupabaseConfig.enableDebugLogging, isA<bool>());
      });
    });

    group('Configuration Validation', () {
      test('all required config values should be set', () {
        expect(SupabaseConfig.supabaseUrl, isNotEmpty);
        expect(SupabaseConfig.supabaseAnonKey, isNotEmpty);
      });

      test('URL and key should be different values', () {
        expect(
          SupabaseConfig.supabaseUrl,
          isNot(equals(SupabaseConfig.supabaseAnonKey)),
        );
      });
    });
  });
}
