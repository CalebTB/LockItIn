import 'package:flutter_test/flutter_test.dart';
import 'package:lockitin_app/core/utils/logger.dart';

void main() {
  group('Logger', () {
    group('API', () {
      test('info should accept tag and message', () {
        // This test verifies the API signature is correct
        // Actual printing only happens in debug mode
        expect(() => Logger.info('TestTag', 'Test message'), returnsNormally);
      });

      test('error should accept tag, message, and optional error', () {
        expect(
          () => Logger.error('TestTag', 'Error message'),
          returnsNormally,
        );
      });

      test('error should accept tag, message, error object, and stackTrace', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        expect(
          () => Logger.error('TestTag', 'Error message', error, stackTrace),
          returnsNormally,
        );
      });

      test('warning should accept tag and message', () {
        expect(() => Logger.warning('TestTag', 'Warning message'), returnsNormally);
      });

      test('success should accept tag and message', () {
        expect(() => Logger.success('TestTag', 'Success message'), returnsNormally);
      });

      test('debug should accept tag and message', () {
        expect(() => Logger.debug('TestTag', 'Debug message'), returnsNormally);
      });
    });

    group('Method Signatures', () {
      test('all methods should handle empty tag', () {
        expect(() => Logger.info('', 'Message with empty tag'), returnsNormally);
        expect(() => Logger.error('', 'Error with empty tag'), returnsNormally);
        expect(() => Logger.warning('', 'Warning with empty tag'), returnsNormally);
        expect(() => Logger.success('', 'Success with empty tag'), returnsNormally);
        expect(() => Logger.debug('', 'Debug with empty tag'), returnsNormally);
      });

      test('all methods should handle empty message', () {
        expect(() => Logger.info('Tag', ''), returnsNormally);
        expect(() => Logger.error('Tag', ''), returnsNormally);
        expect(() => Logger.warning('Tag', ''), returnsNormally);
        expect(() => Logger.success('Tag', ''), returnsNormally);
        expect(() => Logger.debug('Tag', ''), returnsNormally);
      });

      test('all methods should handle special characters', () {
        const specialChars = 'Special chars: !@#\$%^&*()_+-=[]{}|;:,.<>?';
        expect(() => Logger.info('Tag', specialChars), returnsNormally);
        expect(() => Logger.error('Tag', specialChars), returnsNormally);
        expect(() => Logger.warning('Tag', specialChars), returnsNormally);
        expect(() => Logger.success('Tag', specialChars), returnsNormally);
        expect(() => Logger.debug('Tag', specialChars), returnsNormally);
      });

      test('all methods should handle unicode', () {
        const unicode = 'Unicode: 日本語 한국어 العربية 🎉🔥💡';
        expect(() => Logger.info('Tag', unicode), returnsNormally);
        expect(() => Logger.error('Tag', unicode), returnsNormally);
        expect(() => Logger.warning('Tag', unicode), returnsNormally);
        expect(() => Logger.success('Tag', unicode), returnsNormally);
        expect(() => Logger.debug('Tag', unicode), returnsNormally);
      });

      test('all methods should handle multiline messages', () {
        const multiline = 'Line 1\nLine 2\nLine 3';
        expect(() => Logger.info('Tag', multiline), returnsNormally);
        expect(() => Logger.error('Tag', multiline), returnsNormally);
        expect(() => Logger.warning('Tag', multiline), returnsNormally);
        expect(() => Logger.success('Tag', multiline), returnsNormally);
        expect(() => Logger.debug('Tag', multiline), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('error should handle null error object gracefully', () {
        expect(() => Logger.error('Tag', 'Message', null), returnsNormally);
      });

      test('error should handle various error types', () {
        expect(() => Logger.error('Tag', 'Message', 'String error'), returnsNormally);
        expect(() => Logger.error('Tag', 'Message', 42), returnsNormally);
        expect(() => Logger.error('Tag', 'Message', Exception('Test')), returnsNormally);
        expect(() => Logger.error('Tag', 'Message', Error()), returnsNormally);
        expect(() => Logger.error('Tag', 'Message', {'key': 'value'}), returnsNormally);
      });

      test('error should handle null stackTrace gracefully', () {
        final error = Exception('Test');
        expect(() => Logger.error('Tag', 'Message', error, null), returnsNormally);
      });
    });
  });
}
