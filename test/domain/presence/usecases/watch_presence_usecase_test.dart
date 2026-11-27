import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/domain/presence/repositories/presence_repository.dart';
import 'package:twake_chat/domain/presence/usecases/watch_presence_usecase.dart';

class _FakePresenceRepository implements PresenceRepository {
  final controller = StreamController<PersonPresence?>();
  int watchCalls = 0;
  final serverReads = <bool>[];

  @override
  Stream<PersonPresence?> watchPresence(
    String userId, {
    required bool readFromServer,
  }) {
    watchCalls++;
    serverReads.add(readFromServer);
    return controller.stream;
  }
}

const _online = PersonPresence(status: PresenceStatus.online);
const _away = PersonPresence(status: PresenceStatus.away);

void main() {
  test('a blank id has no presence and is not watched', () async {
    final repository = _FakePresenceRepository();

    final values = await WatchPresenceUseCase(
      repository,
    ).execute('', readFromServer: true).toList();

    expect(values, [null]);
    expect(repository.watchCalls, 0);
  });

  test('emits each change once', () async {
    final repository = _FakePresenceRepository();
    final values = <PersonPresence?>[];
    final sub = WatchPresenceUseCase(
      repository,
    ).execute('@alice:server', readFromServer: true).listen(values.add);

    repository.controller
      ..add(_online)
      ..add(_online)
      ..add(_away)
      ..add(_away)
      ..add(_online);
    await pumpEventQueue();

    expect(values, [_online, _away, _online]);
    await sub.cancel();
    await repository.controller.close();
  });

  test('passes on whether to read the server', () {
    final repository = _FakePresenceRepository();

    WatchPresenceUseCase(
      repository,
    ).execute('@alice:server', readFromServer: false).listen((_) {});

    expect(repository.serverReads, [false]);
  });
}
