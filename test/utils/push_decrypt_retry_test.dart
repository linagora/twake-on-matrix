import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/push_decrypt_retry.dart';

void main() {
  test('retries on each trigger and returns first non-null', () async {
    final triggers = StreamController<int>();
    var calls = 0;
    final future = retryUntil<String>(() async {
      calls++;
      return calls < 3 ? null : 'ok';
    }, triggers.stream);
    for (var i = 0; i < 3; i++) {
      triggers.add(i);
      await Future<void>.delayed(Duration.zero);
    }
    expect(await future, 'ok');
    await triggers.close();
  });

  test('kick completion triggers an attempt', () async {
    final result = await retryUntil<int>(
      () async => 1,
      const Stream.empty(),
      kick: Future<void>.value(),
    );
    expect(result, 1);
  });

  test('returns null on timeout', () async {
    final result = await retryUntil<int>(
      () async => null,
      const Stream.empty(),
      timeout: const Duration(milliseconds: 50),
    );
    expect(result, isNull);
  });
}
