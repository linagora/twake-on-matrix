import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/pages/space_home/space_home_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';

import 'space_home_controller_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SpaceRepository>()])
void main() {
  const spaceId = '!s';
  const space = SpaceSummary(
    id: spaceId,
    name: 'Team',
    memberCount: 2,
    isPublic: false,
    canInvite: true,
    canAddChildren: true,
  );
  late MockSpaceRepository repository;
  late StreamController<int> changes;
  late ProviderContainer container;

  setUp(() {
    repository = MockSpaceRepository();
    changes = StreamController<int>.broadcast();
    addTearDown(changes.close);
    when(repository.watchRoomChanges()).thenAnswer((_) => changes.stream);
    when(repository.getRoomListEntries()).thenReturn(const []);
    when(repository.getSpace(spaceId)).thenReturn(space);
    when(
      repository.getSpaceChildren(spaceId),
    ).thenAnswer((_) async => const [SpaceChannel(roomId: '!c', name: 'Dev')]);
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [spaceRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(spaceHomeControllerProvider(spaceId), (_, _) {});
  });

  SpaceHomeState state() =>
      container.read(spaceHomeControllerProvider(spaceId));

  group('SpaceHomeController', () {
    test('whenBuilt_readsTheSpaceAtOnce', () {
      expect(state().space, space);
    });

    test('whenRoomIsNoSpace_readsNoHierarchy', () async {
      when(repository.getSpace('!room')).thenReturn(null);
      container.listen(spaceHomeControllerProvider('!room'), (_, _) {});
      await pumpEventQueue();

      expect(
        container.read(spaceHomeControllerProvider('!room')).space,
        isNull,
      );
      verifyNever(repository.getSpaceChildren('!room'));
    });

    test('whenRoomsChange_followsTheSpace', () async {
      await pumpEventQueue();
      const renamed = SpaceSummary(
        id: spaceId,
        name: 'Renamed',
        memberCount: 2,
        isPublic: false,
        canInvite: true,
        canAddChildren: true,
      );
      when(repository.getSpace(spaceId)).thenReturn(renamed);

      changes.add(1);
      await pumpEventQueue();

      expect(state().space, renamed);
    });

    test('open_always_readsTheSpaceAndWhatItHoldsAgain', () async {
      container.listen(spaceChildrenProvider(spaceId), (_, _) {});
      await pumpEventQueue();
      clearInteractions(repository);

      await container
          .read(spaceHomeControllerProvider(spaceId).notifier)
          .open();
      await pumpEventQueue();

      verify(repository.open(spaceId)).called(1);
      verify(repository.getSpaceChildren(spaceId)).called(1);
    });
  });
}
