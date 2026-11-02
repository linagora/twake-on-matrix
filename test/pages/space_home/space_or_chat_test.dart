import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/spaces/space_repository.provider.dart';
import 'package:twake_chat/domain/repository/spaces/space_repository.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/pages/space_home/space_or_chat.dart';

import 'space_or_chat_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SpaceRepository>()])
void main() {
  const roomId = '!r';
  const space = SpaceSummary(
    id: roomId,
    name: 'Team',
    memberCount: 2,
    isPublic: false,
    canInvite: true,
    canAddChildren: true,
  );
  late MockSpaceRepository repository;
  late StreamController<int> changes;

  Future<void> pump(WidgetTester tester, SpaceSummary? first) async {
    repository = MockSpaceRepository();
    changes = StreamController<int>.broadcast();
    addTearDown(changes.close);
    when(repository.watchRoomChanges()).thenAnswer((_) => changes.stream);
    when(repository.getSpace(roomId)).thenReturn(first);
    final router = GoRouter(
      initialLocation: '/room',
      routes: [
        GoRoute(
          path: '/room',
          builder: (context, state) => SpaceOrChat(
            roomId: roomId,
            spaceBuilder: (_) => const Text('home'),
            chatBuilder: (_) => const Text('chat'),
          ),
        ),
        GoRoute(path: '/rooms', builder: (_, _) => const Text('list')),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [spaceRepositoryProvider.overrideWithValue(repository)],
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  Future<void> whenRoomBecomes(WidgetTester tester, SpaceSummary? next) async {
    when(repository.getSpace(roomId)).thenReturn(next);
    changes.add(1);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  group('SpaceOrChat', () {
    testWidgets('whenJoinedSpace_showsItsHome', (tester) async {
      await pump(tester, space);

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('whenOtherRoom_showsTheConversation', (tester) async {
      await pump(tester, null);

      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('whenRoomStaysNoSpace_doesNotLeave', (tester) async {
      await pump(tester, null);

      await whenRoomBecomes(tester, null);

      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('whenInvitationIsAccepted_turnsIntoItsHome', (tester) async {
      await pump(tester, null);

      await whenRoomBecomes(tester, space);

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('whenSpaceIsGone_goesBackToTheList', (tester) async {
      await pump(tester, space);

      await whenRoomBecomes(tester, null);

      expect(find.text('list'), findsOneWidget);
    });
  });
}
