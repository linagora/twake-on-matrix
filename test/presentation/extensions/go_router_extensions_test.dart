import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/presentation/extensions/go_router_extensions.dart';

/// Review 3609 (nqhhdev, go_router_extensions.dart:20): what the router says
/// is on screen decides which pushes stay silent. A room on screen is read
/// live; behind a thread screen the room timeline is hidden, so only that
/// thread is read live and the room's own messages still notify
/// (`isCurrentRoomActive` of background_push.dart relies on it).
const _roomId = '!room:example.org';
const _rootId = r'$root:example.org';
const _replyId = r'$reply:example.org';

Widget _page(String name) => Scaffold(body: Text(name));

Future<GoRouter> _pumpAt(WidgetTester tester, String location) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (_, _) => _page('empty')),
      GoRoute(path: '/rooms', builder: (_, _) => _page('rooms')),
      GoRoute(
        path: '/rooms/:roomid',
        builder: (_, _) => _page('room'),
        routes: [
          GoRoute(path: 'threads/:rootid', builder: (_, _) => _page('thread')),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('the room on screen', () {
    testWidgets('a room screen is the active room', (tester) async {
      final router = await _pumpAt(tester, '/rooms/$_roomId');

      expect(router.activeRoomId, _roomId);
      expect(router.activeThread, isNull);
    });

    testWidgets('a room screen opened on an event is the active room', (
      tester,
    ) async {
      final router = await _pumpAt(tester, '/rooms/$_roomId?event=$_replyId');

      expect(router.activeRoomId, _roomId);
      expect(router.activeThread, isNull);
    });

    testWidgets('a thread screen hides its room: no active room, but the '
        'active thread', (tester) async {
      final router = await _pumpAt(tester, '/rooms/$_roomId/threads/$_rootId');

      expect(router.activeRoomId, isNull);
      expect(router.activeThread, (roomId: _roomId, threadRootId: _rootId));
    });

    testWidgets('a thread screen opened on a reply (?event=) is the active '
        'thread of that root', (tester) async {
      final router = await _pumpAt(
        tester,
        '/rooms/$_roomId/threads/$_rootId?event=$_replyId',
      );

      expect(router.activeRoomId, isNull);
      expect(router.activeThread, (roomId: _roomId, threadRootId: _rootId));
    });

    testWidgets('the room list has no active room nor thread', (tester) async {
      final router = await _pumpAt(tester, '/rooms');

      expect(router.activeRoomId, isNull);
      expect(router.activeThread, isNull);
    });

    testWidgets('an empty location has no active room nor thread', (
      tester,
    ) async {
      final router = await _pumpAt(tester, '/');

      expect(router.activeRoomId, isNull);
      expect(router.activeThread, isNull);
    });
  });
}
