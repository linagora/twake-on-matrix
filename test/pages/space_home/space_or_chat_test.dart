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
  _spaceOrChatTests();
}

const _roomId = '!r';
const _space = SpaceSummary(
  id: _roomId,
  name: 'Team',
  memberCount: 2,
  isPublic: false,
  canInvite: true,
  canAddChildren: true,
);
late MockSpaceRepository _repository;
late StreamController<int> _changes;

Future<void> _pump(WidgetTester tester, SpaceSummary? first) async {
  _repository = MockSpaceRepository();
  _changes = StreamController<int>.broadcast();
  addTearDown(_changes.close);
  when(_repository.watchRoomChanges()).thenAnswer((_) => _changes.stream);
  when(_repository.getSpace(_roomId)).thenReturn(first);
  final router = GoRouter(
    initialLocation: '/room',
    routes: [
      GoRoute(
        path: '/room',
        builder: (context, state) => SpaceOrChat(
          roomId: _roomId,
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
        overrides: [spaceRepositoryProvider.overrideWithValue(_repository)],
      ),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
}

Future<void> _whenRoomBecomes(WidgetTester tester, SpaceSummary? next) async {
  when(_repository.getSpace(_roomId)).thenReturn(next);
  _changes.add(1);
  await tester.pump();
  await tester.pumpAndSettle();
}

void _spaceOrChatTests() {
  group('SpaceOrChat', () {
    testWidgets('whenJoinedSpace_showsItsHome', (tester) async {
      await _pump(tester, _space);

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('whenOtherRoom_showsTheConversation', (tester) async {
      await _pump(tester, null);

      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('whenRoomStaysNoSpace_doesNotLeave', (tester) async {
      await _pump(tester, null);

      await _whenRoomBecomes(tester, null);

      expect(find.text('chat'), findsOneWidget);
    });

    testWidgets('whenInvitationIsAccepted_turnsIntoItsHome', (tester) async {
      await _pump(tester, null);

      await _whenRoomBecomes(tester, _space);

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('whenSpaceIsGone_goesBackToTheList', (tester) async {
      await _pump(tester, _space);

      await _whenRoomBecomes(tester, null);

      expect(find.text('list'), findsOneWidget);
    });
  });
}
