import 'dart:io';
import 'dart:math';

import 'package:matrix/matrix.dart';

typedef LoginWait = Future<void> Function(Duration delay);
typedef LoginJitter = int Function(int maxMilliseconds);

/// Runs [login] again only when the homeserver reports `M_LIMIT_EXCEEDED`.
///
/// The server-provided `Retry-After` header takes precedence over the Matrix
/// `retry_after_ms` body field. When neither exists, retries use exponential
/// backoff. A small jitter is always added so concurrent FTL workers do not
/// retry at the exact same instant.
Future<T> loginWithRateLimitRetry<T>(
  Future<T> Function() login, {
  int maxAttempts = 4,
  Duration fallbackDelay = const Duration(seconds: 5),
  Duration maxJitter = const Duration(seconds: 3),
  LoginWait? wait,
  LoginJitter? jitterMilliseconds,
  DateTime Function()? now,
  void Function(String message)? log,
}) async {
  if (maxAttempts < 1) {
    throw ArgumentError.value(maxAttempts, 'maxAttempts', 'must be at least 1');
  }
  if (fallbackDelay.isNegative) {
    throw ArgumentError.value(
      fallbackDelay,
      'fallbackDelay',
      'must not be negative',
    );
  }
  if (maxJitter.isNegative) {
    throw ArgumentError.value(maxJitter, 'maxJitter', 'must not be negative');
  }

  final delay = wait ?? Future<void>.delayed;
  final randomJitter = jitterMilliseconds ?? Random().nextInt;
  final currentTime = now ?? DateTime.now;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await login();
    } on MatrixException catch (exception) {
      final canRetry =
          exception.error == MatrixError.M_LIMIT_EXCEEDED &&
          attempt < maxAttempts;
      if (!canRetry) rethrow;

      final serverDelay = _serverRetryDelay(exception, currentTime());
      final backoffMultiplier = 1 << (attempt - 1);
      final baseDelay = serverDelay ?? fallbackDelay * backoffMultiplier;
      final jitterRange = maxJitter.inMilliseconds;
      final jitter = jitterRange == 0 ? 0 : randomJitter(jitterRange + 1);
      final retryDelay = baseDelay + Duration(milliseconds: jitter);

      log?.call(
        'Matrix login rate limited on attempt $attempt/$maxAttempts; '
        'retrying in ${retryDelay.inMilliseconds} ms.',
      );
      await delay(retryDelay);
    }
  }

  throw StateError('Unreachable login retry state');
}

Duration? _serverRetryDelay(MatrixException exception, DateTime now) {
  String? retryAfterHeader;
  for (final entry
      in exception.response?.headers.entries ??
          const <MapEntry<String, String>>[]) {
    if (entry.key.toLowerCase() == 'retry-after') {
      retryAfterHeader = entry.value.trim();
      break;
    }
  }

  final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');
  if (retryAfterSeconds != null && retryAfterSeconds >= 0) {
    return Duration(seconds: retryAfterSeconds);
  }
  if (retryAfterHeader != null) {
    try {
      final retryAt = HttpDate.parse(retryAfterHeader).toUtc();
      final delay = retryAt.difference(now.toUtc());
      return delay.isNegative ? Duration.zero : delay;
    } on HttpException {
      // Fall through to the Matrix body field or local backoff.
    } on FormatException {
      // Fall through to the Matrix body field or local backoff.
    }
  }

  final retryAfterMs = exception.retryAfterMs;
  if (retryAfterMs != null && retryAfterMs >= 0) {
    return Duration(milliseconds: retryAfterMs);
  }
  return null;
}
