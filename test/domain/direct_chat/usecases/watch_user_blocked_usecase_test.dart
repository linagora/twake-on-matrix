import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/direct_chat/repositories/ignored_users_repository.dart';
import 'package:twake_chat/domain/direct_chat/usecases/watch_user_blocked_usecase.dart';

class _FakeIgnoredUsersRepository implements IgnoredUsersRepository {
  final controller = StreamController<bool>();
  int watchCalls = 0;

  @override
  Stream<bool> watchIsIgnored(String userId) {
    watchCalls++;
    return controller.stream;
  }
}

void main() {
  test('a blank id is never blocked and is not watched', () async {
    final repository = _FakeIgnoredUsersRepository();

    final values = await WatchUserBlockedUseCase(
      repository,
    ).execute('').toList();

    expect(values, [false]);
    expect(repository.watchCalls, 0);
  });

  test('emits each change of the ignore list once', () async {
    final repository = _FakeIgnoredUsersRepository();
    final values = <bool>[];
    final sub = WatchUserBlockedUseCase(
      repository,
    ).execute('@alice:server').listen(values.add);

    repository.controller
      ..add(false)
      ..add(false)
      ..add(true)
      ..add(true)
      ..add(false);
    await pumpEventQueue();

    expect(values, [false, true, false]);
    await sub.cancel();
    await repository.controller.close();
  });
}
