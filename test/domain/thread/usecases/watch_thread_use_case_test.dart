import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/thread/usecases/watch_thread_use_case.dart';

import '../fake_thread_prefs_repository.dart';

/// THR-M-07 and THR-M-08: what the account says of a thread, then each
/// change (a sync, the web), without reopening the thread.
void main() {
  late FakeThreadPrefsRepository repository;

  setUp(() => repository = FakeThreadPrefsRepository());
  tearDown(() => repository.close());

  test('gives what the account says of the thread, as it changes', () async {
    final shown = WatchThreadUseCase(repository).execute(lunchThread);
    final seen = expectLater(
      shown,
      emitsInOrder([statusOf(followed), statusOf(muted, isResolved: true)]),
    );

    repository.show(statusOf(followed));
    repository.show(statusOf(muted, isResolved: true));

    await seen;
  });
}
