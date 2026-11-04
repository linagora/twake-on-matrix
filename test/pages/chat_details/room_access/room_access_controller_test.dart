import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/room_access/repositories/room_access_repository.provider.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_controller.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_draft.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import 'public_groups_summary.dart';
import 'room_access_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RoomAccessRepository>()])
void main() {
  const roomId = '!room:example.com';
  const invite = RoomAccess(
    joinRule: JoinRuleChoice.invite,
    isListed: false,
    isEncrypted: false,
    canChange: true,
    hasPublicPage: false,
  );

  late MockRoomAccessRepository repository;

  setUp(() {
    repository = MockRoomAccessRepository();
    when(repository.isEncrypted(roomId)).thenReturn(false);
  });

  ProviderContainer createContainer({
    RoomAccess access = invite,
    Stream<RoomAccess>? updates,
    bool isPublicGroupsEnabled = true,
  }) {
    when(
      repository.watchRoomAccess(roomId),
    ).thenAnswer((_) => updates ?? Stream.value(access));
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
    final access = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(access, isNull);
    verifyNever(repository.watchRoomAccess(any));
  });

  test('build_whenTheUserCannotChangeTheRule_showsNothing', () async {
    // Arrange
    final container = createContainer(
      access: invite.copyWith(canChange: false),
    );

    // Act
    final access = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(access, isNull);
  });

  test('build_always_emitsTheSavedAccess', () async {
    // Arrange
    final container = createContainer();

    // Act
    final access = await container.read(
      roomAccessControllerProvider(roomId).future,
    );

    // Assert
    expect(access, invite);
  });

  test('save_publicThenUnlisted_sendsOnlyTheRuleAndKeepsIt', () async {
    // Arrange
    final container = createContainer();
    await container.read(roomAccessControllerProvider(roomId).future);
    final draft = const RoomAccessDraft()
        .choose(JoinRuleChoice.public)
        .copyWith(isListed: false);

    // Act
    await container
        .read(roomAccessControllerProvider(roomId).notifier)
        .save(draft);

    // Assert
    verify(repository.setJoinRule(roomId, JoinRuleChoice.public)).called(1);
    verifyNever(repository.setListed(any, isListed: anyNamed('isListed')));
    expect(
      container.read(roomAccessControllerProvider(roomId)).value?.joinRule,
      JoinRuleChoice.public,
    );
  });

  test('save_whenRefused_keepsTheSavedAccess', () async {
    // Arrange
    when(
      repository.setListed(roomId, isListed: true),
    ).thenThrow(const RoomAccessForbiddenException(cause: 'x'));
    final container = createContainer();
    await container.read(roomAccessControllerProvider(roomId).future);

    // Act
    final result = container
        .read(roomAccessControllerProvider(roomId).notifier)
        .save(const RoomAccessDraft().choose(JoinRuleChoice.public));

    // Assert
    await expectLater(result, throwsA(isA<RoomAccessForbiddenException>()));
    expect(container.read(roomAccessControllerProvider(roomId)).value, invite);
  });

  test('save_whenTheRoomChangesMeanwhile_keepsTheNewState', () async {
    // Arrange
    final updates = StreamController<RoomAccess>();
    final listed = Completer<void>();
    final container = createContainer(updates: updates.stream);
    when(
      repository.setListed(roomId, isListed: true),
    ).thenAnswer((_) => listed.future);
    updates.add(invite);
    await container.read(roomAccessControllerProvider(roomId).future);

    // Act
    final saving = container
        .read(roomAccessControllerProvider(roomId).notifier)
        .save(const RoomAccessDraft(isListed: true));
    updates.add(invite.copyWith(isEncrypted: true));
    await pumpEventQueue();
    listed.complete();
    await saving;

    // Assert
    final access = container.read(roomAccessControllerProvider(roomId)).value;
    expect(access?.isEncrypted, isTrue);
    expect(access?.isListed, isTrue);
    await updates.close();
  });

  test('save_whenTheSectionHidesMeanwhile_staysHidden', () async {
    // Arrange
    final updates = StreamController<RoomAccess>();
    final listed = Completer<void>();
    final container = createContainer(updates: updates.stream);
    when(
      repository.setListed(roomId, isListed: true),
    ).thenAnswer((_) => listed.future);
    updates.add(invite);
    await container.read(roomAccessControllerProvider(roomId).future);

    // Act
    final saving = container
        .read(roomAccessControllerProvider(roomId).notifier)
        .save(const RoomAccessDraft(isListed: true));
    updates.add(invite.copyWith(canChange: false));
    await pumpEventQueue();
    listed.complete();
    await saving;

    // Assert
    expect(container.read(roomAccessControllerProvider(roomId)).value, isNull);
    await updates.close();
  });

  test('save_unchangedDraft_sendsNothing', () async {
    // Arrange
    final container = createContainer();
    await container.read(roomAccessControllerProvider(roomId).future);

    // Act
    await container
        .read(roomAccessControllerProvider(roomId).notifier)
        .save(const RoomAccessDraft(joinRule: JoinRuleChoice.invite));

    // Assert
    verifyNever(repository.setJoinRule(any, any));
  });

  test('save_whenTheSectionIsHidden_sendsNothing', () async {
    // Arrange
    final container = createContainer(isPublicGroupsEnabled: false);
    await container.read(roomAccessControllerProvider(roomId).future);

    // Act
    await container
        .read(roomAccessControllerProvider(roomId).notifier)
        .save(const RoomAccessDraft(joinRule: JoinRuleChoice.public));

    // Assert
    verifyNever(repository.setJoinRule(any, any));
    verifyNever(repository.setListed(any, isListed: anyNamed('isListed')));
  });
}
