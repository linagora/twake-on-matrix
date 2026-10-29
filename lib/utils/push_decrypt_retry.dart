import 'dart:async';

import 'package:matrix/matrix.dart';

/// Calls [attempt] on every [triggers] event and when [kick] completes, until
/// it returns non-null or [timeout] elapses. Returns null on timeout.
Future<T?> retryUntil<T>(
  Future<T?> Function() attempt,
  Stream<Object?> triggers, {
  Future<void>? kick,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final done = Completer<T?>();
  void run() => attempt().then((v) {
    if (v != null && !done.isCompleted) done.complete(v);
  }, onError: (e, s) => Logs().w('[Push] Decryption attempt failed', e, s));
  final sub = triggers.listen((_) => run());
  kick?.then((_) => run(), onError: (_) {});
  try {
    return await done.future.timeout(timeout, onTimeout: () => null);
  } finally {
    await sub.cancel();
  }
}
