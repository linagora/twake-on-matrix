import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';

import '../../integration_test/base/matrix_login_retry.dart';

void main() {
  test('retries a rate-limited login using retry_after_ms', () async {
    var attempts = 0;
    final waits = <Duration>[];

    final result = await loginWithRateLimitRetry(
      () async {
        attempts++;
        if (attempts == 1) {
          throw MatrixException.fromJson({
            'errcode': 'M_LIMIT_EXCEEDED',
            'error': 'Too Many Requests',
            'retry_after_ms': 1500,
          });
        }
        return 'logged-in';
      },
      wait: (delay) async => waits.add(delay),
      jitterMilliseconds: (_) => 0,
    );

    expect(result, 'logged-in');
    expect(attempts, 2);
    expect(waits, [const Duration(milliseconds: 1500)]);
  });

  test('prefers Retry-After over retry_after_ms', () async {
    var attempts = 0;
    final waits = <Duration>[];

    final result = await loginWithRateLimitRetry(
      () async {
        attempts++;
        if (attempts == 1) {
          throw MatrixException(
            http.Response(
              '{'
              '"errcode":"M_LIMIT_EXCEEDED",'
              '"error":"Too Many Requests",'
              '"retry_after_ms":1500'
              '}',
              429,
              headers: {'Retry-After': '7'},
            ),
          );
        }
        return 'logged-in';
      },
      wait: (delay) async => waits.add(delay),
      jitterMilliseconds: (_) => 0,
    );

    expect(result, 'logged-in');
    expect(attempts, 2);
    expect(waits, [const Duration(seconds: 7)]);
  });

  test('supports Retry-After in HTTP-date format', () async {
    var attempts = 0;
    final waits = <Duration>[];

    await loginWithRateLimitRetry(
      () async {
        attempts++;
        if (attempts == 1) {
          throw MatrixException(
            http.Response(
              '{"errcode":"M_LIMIT_EXCEEDED","error":"Too Many Requests"}',
              429,
              headers: {'Retry-After': 'Wed, 29 Jul 2026 10:00:07 GMT'},
            ),
          );
        }
      },
      now: () => DateTime.utc(2026, 7, 29, 10),
      wait: (delay) async => waits.add(delay),
      jitterMilliseconds: (_) => 0,
    );

    expect(waits, [const Duration(seconds: 7)]);
  });

  test(
    'falls back to retry_after_ms for an invalid Retry-After header',
    () async {
      var attempts = 0;
      final waits = <Duration>[];

      await loginWithRateLimitRetry(
        () async {
          attempts++;
          if (attempts == 1) {
            throw MatrixException(
              http.Response(
                '{'
                '"errcode":"M_LIMIT_EXCEEDED",'
                '"error":"Too Many Requests",'
                '"retry_after_ms":2200'
                '}',
                429,
                headers: {'Retry-After': 'not-a-date'},
              ),
            );
          }
        },
        wait: (delay) async => waits.add(delay),
        jitterMilliseconds: (_) => 0,
      );

      expect(waits, [const Duration(milliseconds: 2200)]);
    },
  );

  test('does not retry Matrix errors other than M_LIMIT_EXCEEDED', () async {
    var attempts = 0;
    final waits = <Duration>[];
    final exception = MatrixException.fromJson({
      'errcode': 'M_FORBIDDEN',
      'error': 'Forbidden',
    });

    await expectLater(
      loginWithRateLimitRetry(() async {
        attempts++;
        throw exception;
      }, wait: (delay) async => waits.add(delay)),
      throwsA(same(exception)),
    );

    expect(attempts, 1);
    expect(waits, isEmpty);
  });

  test('stops after the configured maximum number of attempts', () async {
    var attempts = 0;
    final waits = <Duration>[];

    await expectLater(
      loginWithRateLimitRetry<void>(
        () async {
          attempts++;
          throw MatrixException.fromJson({
            'errcode': 'M_LIMIT_EXCEEDED',
            'error': 'Too Many Requests',
            'retry_after_ms': 1000,
          });
        },
        maxAttempts: 3,
        wait: (delay) async => waits.add(delay),
        jitterMilliseconds: (_) => 0,
      ),
      throwsA(
        isA<MatrixException>().having(
          (exception) => exception.error,
          'error',
          MatrixError.M_LIMIT_EXCEEDED,
        ),
      ),
    );

    expect(attempts, 3);
    expect(waits, [const Duration(seconds: 1), const Duration(seconds: 1)]);
  });

  test(
    'uses exponential fallback and jitter when no server delay exists',
    () async {
      var attempts = 0;
      final waits = <Duration>[];

      final result = await loginWithRateLimitRetry(
        () async {
          attempts++;
          if (attempts < 3) {
            throw MatrixException.fromJson({
              'errcode': 'M_LIMIT_EXCEEDED',
              'error': 'Too Many Requests',
            });
          }
          return 'logged-in';
        },
        maxAttempts: 3,
        fallbackDelay: const Duration(seconds: 5),
        wait: (delay) async => waits.add(delay),
        jitterMilliseconds: (_) => 250,
      );

      expect(result, 'logged-in');
      expect(waits, [
        const Duration(milliseconds: 5250),
        const Duration(milliseconds: 10250),
      ]);
    },
  );
}
