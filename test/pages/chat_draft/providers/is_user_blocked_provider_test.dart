import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/direct_chat/repositories/ignored_users_repository.dart';
import 'package:twake_chat/pages/chat_draft/providers/is_user_blocked_provider.dart';
import 'package:twake_chat/providers/direct_chat_provider.dart';

class _FakeIgnoredUsersRepository implements IgnoredUsersRepository {
  final controllers = <String, StreamController<bool>>{};

  @override
  Stream<bool> watchIsIgnored(String userId) =>
      (controllers[userId] ??= StreamController<bool>.broadcast()).stream;
}

void main() {
  const alice = '@alice:server';
  const bob = '@bob:server';
  late _FakeIgnoredUsersRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeIgnoredUsersRepository();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [ignoredUsersRepositoryProvider.overrideWithValue(repository)],
    );
  });

  test('follows the blocked state of the user', () async {
    final values = <bool>[];
    container.listen(isUserBlockedProvider(alice), (_, next) {
      final value = next.value;
      if (value != null) values.add(value);
    });
    await pumpEventQueue();

    repository.controllers[alice]!
      ..add(true)
      ..add(false);
    await pumpEventQueue();

    expect(values, [true, false]);
  });

  test('a blank id reads as not blocked', () async {
    final state = container.listen(isUserBlockedProvider(''), (_, _) {});
    await pumpEventQueue();

    expect(state.read().value, isFalse);
  });

  test('each user has its own state', () async {
    final aliceState = container.listen(
      isUserBlockedProvider(alice),
      (_, _) {},
    );
    final bobState = container.listen(isUserBlockedProvider(bob), (_, _) {});
    await pumpEventQueue();

    repository.controllers[alice]!.add(true);
    await pumpEventQueue();

    expect(aliceState.read().value, isTrue);
    expect(bobState.read().hasValue, isFalse);
  });
}
