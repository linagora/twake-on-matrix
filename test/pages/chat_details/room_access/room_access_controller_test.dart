import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/room_access/room_access_repository.provider.dart';
import 'package:twake_chat/domain/exception/room_access/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_controller.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import '../../../domain/room_access/fake_room_access_repository.dart';
import 'public_groups_summary.dart';

void main() {
  const roomId = '!room:example.com';

  late FakeRoomAccessRepository repository;

  setUp(() {
    repository = FakeRoomAccessRepository();
  });

  ProviderContainer createContainer({bool isPublicGroupsEnabled = true}) {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        roomAccessRepositoryProvider.overrideWithValue(repository),
        loginHomeserverSummaryProvider.overrideWithBuild(
          (_, _) => summaryWith(isPublicGroupsEnabled: isPublicGroupsEnabled),
        ),
      ],
    );
    container.listen(roomAccessControllerProvider(roomId), (_, _) {});
    return container;
  }

  test('build_whenPublicGroupsAreDisabled_showsNothing', () async {
    // Arrange
    final container = createContainer(isPublicGroupsEnabled: false);

    // Act
    final state = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(state, isNull);
  });

  test('build_whenTheUserCannotChangeTheRule_showsNothing', () async {
    // Arrange
    repository.access = repository.access.copyWith(canChange: false);
    final container = createContainer();

    // Act
    final state = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(state, isNull);
  });

  test('build_always_startsFromTheSavedAccess', () async {
    // Arrange
    final container = createContainer();

    // Act
    final state = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(state?.joinRule, JoinRuleChoice.invite);
    expect(state?.isListed, isFalse);
    expect(state?.isDirty, isFalse);
  });

  test('chooseJoinRule_public_turnsTheListingOn', () async {
    // Arrange
    final container = createContainer();
    await container.read(roomAccessControllerProvider(roomId).future);

    // Act
    container
        .read(roomAccessControllerProvider(roomId).notifier)
        .chooseJoinRule(JoinRuleChoice.public);

    // Assert
    final state = container.read(roomAccessControllerProvider(roomId)).value;
    expect(state?.joinRule, JoinRuleChoice.public);
    expect(state?.isListed, isTrue);
    expect(state?.isDirty, isTrue);
  });

  test('chooseJoinRule_knock_keepsTheListing', () async {
    // Arrange
    repository.access = repository.access.copyWith(isListed: true);
    final container = createContainer();
    await container.read(roomAccessControllerProvider(roomId).future);

    // Act
    container
        .read(roomAccessControllerProvider(roomId).notifier)
        .chooseJoinRule(JoinRuleChoice.knock);

    // Assert
    final state = container.read(roomAccessControllerProvider(roomId)).value;
    expect(state?.joinRule, JoinRuleChoice.knock);
    expect(state?.isListed, isTrue);
  });

  test('save_afterPublicThenUnlisted_sendsOnlyTheRule', () async {
    // Arrange
    final container = createContainer();
    await container.read(roomAccessControllerProvider(roomId).future);
    final controller = container.read(
      roomAccessControllerProvider(roomId).notifier,
    );
    controller
      ..chooseJoinRule(JoinRuleChoice.public)
      ..setListed(false);

    // Act
    await controller.save();

    // Assert
    expect(repository.calls, ['joinRule:public']);
    expect(
      container.read(roomAccessControllerProvider(roomId)).value?.isDirty,
      isFalse,
    );
  });

  test('save_whenRefused_keepsTheChoiceToRetry', () async {
    // Arrange
    repository.setListedError = const RoomAccessForbiddenException(cause: 'x');
    final container = createContainer();
    await container.read(roomAccessControllerProvider(roomId).future);
    final controller = container.read(
      roomAccessControllerProvider(roomId).notifier,
    );
    controller.chooseJoinRule(JoinRuleChoice.public);

    // Act
    final result = controller.save();

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessForbiddenException>()));
    final state = container.read(roomAccessControllerProvider(roomId)).value;
    expect(state?.joinRule, JoinRuleChoice.public);
    expect(state?.isDirty, isTrue);
  });

  test('offeredJoinRules_onAnEncryptedRoom_leavesOutPublic', () async {
    // Arrange
    repository.access = repository.access.copyWith(isEncrypted: true);
    final container = createContainer();

    // Act
    final state = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(state?.offeredJoinRules, [
      JoinRuleChoice.invite,
      JoinRuleChoice.knock,
    ]);
    expect(state?.showsListing, isFalse);
  });

  test('offeredJoinRules_onAnEncryptedPublicListedRoom_keepsThem', () async {
    // Arrange
    repository.access = const RoomAccess(
      joinRule: JoinRuleChoice.public,
      isListed: true,
      isEncrypted: true,
      canChange: true,
    );
    final container = createContainer();

    // Act
    final state = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(state?.offeredJoinRules, JoinRuleChoice.values);
    expect(state?.showsListing, isTrue);
  });
}
