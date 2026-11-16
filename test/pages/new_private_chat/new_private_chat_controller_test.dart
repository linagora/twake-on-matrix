import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.provider.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/pages/new_private_chat/new_private_chat_controller.dart';
import 'package:twake_chat/pages/new_private_chat/new_private_chat_state.dart';

class _FakeDirectChatRepository extends Fake implements DirectChatRepository {
  final rooms = <String, String>{};
  Object? error;

  @override
  String? findDirectChat({required String contactMxId}) {
    final failure = error;
    if (failure != null) throw failure;
    return rooms[contactMxId];
  }
}

void main() {
  const contact = '@alice:server';

  late _FakeDirectChatRepository repository;
  late ProviderContainer container;
  late List<NewPrivateChatState> states;

  setUp(() {
    repository = _FakeDirectChatRepository();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [directChatRepositoryProvider.overrideWithValue(repository)],
    );
    states = [];
    container.listen(
      newPrivateChatControllerProvider,
      (_, next) => states.add(next),
    );
  });

  NewPrivateChatController controller() =>
      container.read(newPrivateChatControllerProvider.notifier);

  test('build_always_startsIdle', () {
    // Assert
    expect(
      container.read(newPrivateChatControllerProvider),
      const NewPrivateChatState.idle(),
    );
  });

  test('openContact_withExistingDirectChat_opensTheRoom', () async {
    // Arrange
    repository.rooms[contact] = '!dm:server';

    // Act
    await controller().openContact(matrixId: contact, displayName: 'Alice');

    // Assert
    expect(states, const [
      NewPrivateChatState.opening(),
      NewPrivateChatState.room('!dm:server'),
    ]);
  });

  test('openContact_withoutDirectChat_opensADraft', () async {
    // Act
    await controller().openContact(matrixId: contact, displayName: 'Alice');

    // Assert
    expect(
      states.last,
      const NewPrivateChatState.draft(matrixId: contact, displayName: 'Alice'),
    );
  });

  test('openContact_twiceOnTheSameRoom_notifiesTwice', () async {
    // Arrange
    repository.rooms[contact] = '!dm:server';

    // Act
    await controller().openContact(matrixId: contact);
    await controller().openContact(matrixId: contact);

    // Assert
    expect(states.whereType<NewPrivateChatRoom>(), hasLength(2));
  });

  test('openContact_whenTheLookupFails_backToIdle', () async {
    // Arrange
    repository.error = StateError('No active Matrix client');

    // Act + Assert
    await expectLater(
      controller().openContact(matrixId: contact),
      throwsStateError,
    );

    expect(
      container.read(newPrivateChatControllerProvider),
      const NewPrivateChatState.idle(),
    );
  });
}
