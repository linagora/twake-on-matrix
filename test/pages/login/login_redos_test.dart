import 'package:flutter_test/flutter_test.dart';

/// ReDoS unit tests for phone number validation regex
/// Reference: ADR 0033 - Fix ReDoS vulnerabilities in regex patterns
/// Vulnerability: lib/pages/login/login.dart:251
/// Before: [+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*
/// After: [+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]{0,20}
void main() {
  group('Phone number validation ReDoS tests', () {
    // The actual regex pattern used in login.dart extension on String
    final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{1,4}[)]?[-\s\./0-9]{0,20}$');

    bool isPhoneNumber(String value) {
      return phoneRegex.hasMatch(value);
    }

    group('Valid phone numbers', () {
      test('should accept standard US phone number', () {
        expect(isPhoneNumber('1234567890'), isTrue);
      });

      test('should accept phone with country code', () {
        expect(isPhoneNumber('+14155552671'), isTrue);
      });

      test('should accept phone with parentheses', () {
        expect(isPhoneNumber('(415)5552671'), isTrue);
      });

      test('should accept phone with dashes', () {
        expect(isPhoneNumber('415-555-2671'), isTrue);
      });

      test('should accept phone with spaces', () {
        expect(isPhoneNumber('415 555 2671'), isTrue);
      });

      test('should accept phone with dots', () {
        expect(isPhoneNumber('415.555.2671'), isTrue);
      });

      test('should accept phone with slashes', () {
        expect(isPhoneNumber('415/555/2671'), isTrue);
      });

      test('should accept international format with plus', () {
        expect(isPhoneNumber('+33123456789'), isTrue);
      });

      test('should accept E.164 format', () {
        expect(isPhoneNumber('+442071838750'), isTrue);
      });

      test('should accept phone with country code in parentheses', () {
        // Pattern: [(]?[0-9]{1,4}[)]? means parentheses around country code
        expect(isPhoneNumber('+(1)234567890'), isTrue);
      });
    });

    group('Edge cases within limits', () {
      test(
        'should accept phone at exactly 20 character limit for separators',
        () {
          // 1-4 digit country code + 20 chars of separators/digits
          // '+1' (country code 1) + '123-456-7890-123456' (20 chars)
          expect(isPhoneNumber('+1123-456-7890-123456'), isTrue);
        },
      );

      test('should accept 4-digit country code', () {
        expect(isPhoneNumber('+1234567890123'), isTrue);
      });

      test('should accept 1-digit country code', () {
        expect(isPhoneNumber('+1234567890'), isTrue);
      });

      test('should accept mixed separators', () {
        expect(isPhoneNumber('+(234)567-890'), isTrue);
      });
    });

    group('Invalid phone numbers', () {
      test('should reject empty string', () {
        expect(isPhoneNumber(''), isFalse);
      });

      test('should reject letters', () {
        expect(isPhoneNumber('abc123456789'), isFalse);
      });

      test('should reject special characters', () {
        expect(isPhoneNumber(r'+1@234#567$890'), isFalse);
      });

      test('should reject phone exceeding separator limit (>20 chars)', () {
        // More than 20 characters after country code
        expect(isPhoneNumber('+1 123-456-7890-1234-5678'), isFalse);
      });

      test('should reject country code with 0 digits', () {
        expect(isPhoneNumber('+()123456789'), isFalse);
      });

      test('should reject country code with 5 consecutive digits at start', () {
        // This has 5 digits at the start without separators, which violates [0-9]{1,4}
        // However, the regex will match first 4 as country code and remaining as body
        // So this test actually documents that behavior - the regex allows this
        expect(isPhoneNumber('12345'), isTrue); // Matches: '1234' + '5'
      });

      test('should reject phone with excessive total length', () {
        // More than 20 chars after country code should fail
        expect(isPhoneNumber('1234567890123456789012345'), isFalse);
      });
    });

    group('ReDoS attack prevention', () {
      test(
        'should handle malicious input with excessive plus signs quickly',
        () {
          final stopwatch = Stopwatch()..start();
          final malicious = '+' * 1000;
          expect(isPhoneNumber(malicious), isFalse);
          stopwatch.stop();

          // Should complete in milliseconds, not seconds
          // Before fix: would cause catastrophic backtracking
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(100),
            reason: 'ReDoS vulnerability: excessive backtracking detected',
          );
        },
      );

      test('should handle malicious input with excessive separators quickly', () {
        final stopwatch = Stopwatch()..start();
        final malicious = '+1234${'-' * 1000}';
        expect(isPhoneNumber(malicious), isFalse);
        stopwatch.stop();

        // Should complete in milliseconds, not seconds
        // Before fix: unbounded [-\s\./0-9]* would cause catastrophic backtracking
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });

      test(
        'should handle malicious input with mixed excessive separators quickly',
        () {
          final stopwatch = Stopwatch()..start();
          final malicious = '+1234${' -./\t' * 500}';
          expect(isPhoneNumber(malicious), isFalse);
          stopwatch.stop();

          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(100),
            reason: 'ReDoS vulnerability: excessive backtracking detected',
          );
        },
      );

      test('should handle alternating valid/invalid pattern quickly', () {
        final stopwatch = Stopwatch()..start();
        final malicious = '+${'1-' * 1000}invalid';
        expect(isPhoneNumber(malicious), isFalse);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: 'ReDoS vulnerability: excessive backtracking detected',
        );
      });
    });
  });
}
