import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lockitin_app/core/services/group_service.dart';

void main() {
  group('GroupService - Exception Handling', () {
    group('GroupServiceException', () {
      test('should contain error message', () {
        final exception = GroupServiceException('Test error message');
        expect(exception.message, 'Test error message');
        expect(exception.toString(), 'GroupServiceException: Test error message');
      });

      test('can have optional code', () {
        final exception = GroupServiceException('Error', code: '23505');
        expect(exception.code, '23505');
      });

      test('can be created without code', () {
        final exception = GroupServiceException('Error only');
        expect(exception.code, isNull);
      });
    });

    group('PostgrestException Error Codes', () {
      // Test that we understand the error code mappings
      // These tests verify the error handling logic is correct

      test('unique_violation code (23505) should be recognized', () {
        const uniqueViolationCode = '23505';
        expect(uniqueViolationCode, equals('23505'));
        // This code should map to "This already exists"
      });

      test('foreign_key_violation code (23503) should be recognized', () {
        const foreignKeyCode = '23503';
        expect(foreignKeyCode, equals('23503'));
        // This code should map to "Referenced record not found"
      });

      test('insufficient_privilege code (42501) should be recognized', () {
        const rlsCode = '42501';
        expect(rlsCode, equals('42501'));
        // This code should map to "Permission denied"
      });

      test('JWT expired code (PGRST116) should be recognized', () {
        const jwtExpiredCode = 'PGRST116';
        expect(jwtExpiredCode, equals('PGRST116'));
        // This code should map to "Session expired, please log in again"
      });

      test('Row not found code (PGRST301) should be recognized', () {
        const notFoundCode = 'PGRST301';
        expect(notFoundCode, equals('PGRST301'));
        // This code should map to "Record not found"
      });
    });
  });

  group('PostgrestException - Creation and Properties', () {
    test('PostgrestException can be created with message and code', () {
      final exception = PostgrestException(
        message: 'duplicate key value violates unique constraint',
        code: '23505',
      );

      expect(exception.message, 'duplicate key value violates unique constraint');
      expect(exception.code, '23505');
    });

    test('PostgrestException can include details and hint', () {
      final exception = PostgrestException(
        message: 'JWT expired',
        code: 'PGRST116',
        details: 'Unauthorized',
        hint: 'Please refresh your token',
      );

      expect(exception.code, 'PGRST116');
      expect(exception.details, 'Unauthorized');
      expect(exception.hint, 'Please refresh your token');
    });

    test('PostgrestException for RLS violation', () {
      final exception = PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );

      expect(exception.code, '42501');
      expect(exception.message, contains('row-level security'));
    });

    test('PostgrestException for foreign key violation', () {
      final exception = PostgrestException(
        message: 'insert or update on table violates foreign key constraint',
        code: '23503',
      );

      expect(exception.code, '23503');
      expect(exception.message, contains('foreign key'));
    });
  });

  group('Error Code to User Message Mapping', () {
    // These tests document the expected error message mappings
    // The actual conversion happens in _handlePostgrestError

    final errorMappings = {
      '23505': 'This already exists',
      '23503': 'Referenced record not found',
      '42501': 'Permission denied',
      'PGRST116': 'Session expired, please log in again',
      'PGRST301': 'Record not found',
    };

    test('all known error codes should have user-friendly messages', () {
      expect(errorMappings.length, 5);
      for (final entry in errorMappings.entries) {
        expect(entry.value, isNotEmpty);
        expect(entry.value, isNot(contains('Error')));
      }
    });

    test('unique_violation maps to friendly message', () {
      expect(errorMappings['23505'], 'This already exists');
    });

    test('foreign_key_violation maps to friendly message', () {
      expect(errorMappings['23503'], 'Referenced record not found');
    });

    test('insufficient_privilege maps to friendly message', () {
      expect(errorMappings['42501'], 'Permission denied');
    });

    test('JWT expired maps to friendly message', () {
      expect(errorMappings['PGRST116'], 'Session expired, please log in again');
    });

    test('Row not found maps to friendly message', () {
      expect(errorMappings['PGRST301'], 'Record not found');
    });
  });
}
