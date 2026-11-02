import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/pages/space_home/space_home.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';

import '../../utils/pump_localized.dart';
import 'space_home_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SpaceRepository>()])
void main() {
  const spaceId = '!s';
  late bool isInfoShown;
  late MockSpaceRepository repository;
  late ProviderContainer container;

  SpaceSummary summary({
    bool isPublic = false,
    bool canInvite = true,
    bool canAddChildren = true,
    String topic = '',
    int memberCount = 2,
  }) => SpaceSummary(
    id: spaceId,
    name: 'Team',
    memberCount: memberCount,
    isPublic: isPublic,
    canInvite: canInvite,
    canAddChildren: canAddChildren,
    topic: topic,
  );

  Future<void> pump(
    WidgetTester tester,
    SpaceSummary? space, {
    List<SpaceChannel> children = const [],
    bool childrenError = false,
  }) async {
    repository = MockSpaceRepository();
    isInfoShown = false;
    when(repository.getSpace(spaceId)).thenReturn(space);
    when(repository.watchRoomChanges()).thenAnswer((_) => const Stream.empty());
    when(repository.getRoomListEntries()).thenReturn(const []);
    when(repository.getSpaceChildren(spaceId)).thenAnswer((_) async {
      if (childrenError) throw const SpaceChildrenUnavailableException();
      return children;
    });
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [spaceRepositoryProvider.overrideWithValue(repository)],
    );
    await pumpLocalized(
      tester,
      container,
      SpaceHome(roomId: spaceId, onShowInfo: () => isInfoShown = true),
    );
    await tester.pump();
    await tester.pump();
  }

  group('SpaceHome', () {
    testWidgets('whenPrivate_tellsWhoMayComeInAndWhatItIsFor', (tester) async {
      await pump(tester, summary(topic: 'For the team'));

      expect(find.text('Private space'), findsOneWidget);
      expect(find.text('2 members'), findsNWidgets(2));
      expect(find.text('For the team'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('whenNarrowAndTextIsLarge_doesNotOverflow', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pump(tester, summary(isPublic: true, memberCount: 1234));

      final error = tester.takeException();
      expect(error, isNull, reason: error?.toString());
    });

    testWidgets('whenPublic_saysSo', (tester) async {
      await pump(tester, summary(isPublic: true));

      expect(find.text('Public space'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

    testWidgets('whenUserMayDoNothing_offersOnlyTheInfo', (tester) async {
      await pump(tester, summary(canInvite: false, canAddChildren: false));

      expect(find.byKey(const ValueKey('space_invite')), findsNothing);
      expect(find.byKey(const ValueKey('space_new_group')), findsNothing);
      expect(find.byKey(const ValueKey('space_open_info')), findsOneWidget);
    });

    testWidgets('whenGearIsTapped_opensTheInfo', (tester) async {
      await pump(tester, summary());

      await tester.tap(find.byKey(const ValueKey('space_open_info')));

      expect(isInfoShown, isTrue);
    });

    testWidgets('whenItHasChannels_listsThem', (tester) async {
      await pump(
        tester,
        summary(),
        children: const [SpaceChannel(roomId: '!c', name: 'Dev')],
      );

      expect(find.text('Channels of the space'), findsOneWidget);
      expect(find.text('Dev'), findsOneWidget);
    });

    testWidgets('whenItHasNoChannel_showsNoList', (tester) async {
      await pump(tester, summary());

      expect(find.text('Channels of the space'), findsNothing);
    });

    testWidgets('whenChannelsCannotBeRead_offersToTryAgain', (tester) async {
      await pump(tester, summary(), childrenError: true);
      expect(find.text('Could not read the channels.'), findsOneWidget);

      when(repository.getSpaceChildren(spaceId)).thenAnswer(
        (_) async => const [SpaceChannel(roomId: '!c', name: 'Dev')],
      );
      await tester.tap(find.byKey(const ValueKey('space_channels_retry')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Dev'), findsOneWidget);
    });

    testWidgets('whenARefreshFailsOnAnEmptySpace_offersToTryAgain', (
      tester,
    ) async {
      await pump(tester, summary());
      expect(find.text('Channels of the space'), findsNothing);

      when(
        repository.getSpaceChildren(spaceId),
      ).thenThrow(const SpaceChildrenUnavailableException());
      container.invalidate(spaceChildrenProvider(spaceId));
      await tester.pump();
      await tester.pump();

      expect(find.text('Channels of the space'), findsNothing);
      expect(
        find.byKey(const ValueKey('space_channels_retry')),
        findsOneWidget,
      );
    });

    testWidgets('whenRoomIsNoSpace_showsNothing', (tester) async {
      await pump(tester, null);

      expect(find.byType(Scaffold), findsNothing);
    });
  });
}
