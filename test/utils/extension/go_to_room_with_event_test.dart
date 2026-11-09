import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';

/// A router that writes down each navigation asked of it.
class _RecordingRouter extends GoRouter {
  _RecordingRouter(List<RouteBase> routes)
    : super.routingConfig(
        routingConfig: ValueNotifier(RoutingConfig(routes: routes)),
        initialLocation: '/',
      );

  final List<String> navigations = [];

  @override
  void go(String location, {Object? extra}) {
    navigations.add('go $location');
    super.go(location, extra: extra);
  }

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    navigations.add('push $location');
    return super.push<T>(location, extra: extra);
  }
}

/// THR-M-11: a thread reply opened from the search or a link
/// opens its thread screen, scrolled to the reply, over its room. One
/// navigation to the nested route `/rooms/:roomId/threads/:rootId?event=`
/// builds both pages; a `go` to the room then a `push` of the thread was
/// two navigations, the second racing the first.
void main() {
  const roomId = '!room:example.org';
  const rootId = r'$root:example.org';
  const replyId = r'$reply:example.org';

  /// The `event` the room screen read from its location, last time built.
  String? roomEvent;

  Future<_RecordingRouter> pumpRouter(
    WidgetTester tester,
    void Function(BuildContext context) open,
  ) async {
    Widget page(String name) => Scaffold(body: Text(name));
    roomEvent = null;
    final router = _RecordingRouter([
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/rooms/:roomid',
        builder: (_, state) {
          roomEvent = state.uri.queryParameters['event'];
          return page('room');
        },
        routes: [
          GoRoute(path: 'threads/:rootid', builder: (_, _) => page('thread')),
        ],
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a thread reply opens with one navigation to its thread, '
      'scrolled to it', (tester) async {
    final router = await pumpRouter(
      tester,
      (context) =>
          context.goToRoomWithEvent(roomId, replyId, threadRootId: rootId),
    );

    expect(router.navigations, [
      'go ${const ThreadRoute(roomid: roomId, rootid: rootId, event: replyId).location}',
    ]);
  });

  testWidgets('the thread screen of the reply is shown over its room', (
    tester,
  ) async {
    await pumpRouter(
      tester,
      (context) =>
          context.goToRoomWithEvent(roomId, replyId, threadRootId: rootId),
    );

    expect(find.text('thread'), findsOneWidget);
    expect(find.text('room', skipOffstage: false), findsOneWidget);
  });

  testWidgets('a message of the room opens the room, scrolled to it', (
    tester,
  ) async {
    final router = await pumpRouter(
      tester,
      (context) => context.goToRoomWithEvent(roomId, replyId),
    );

    expect(router.navigations, hasLength(1));
    expect(router.navigations.single, startsWith('go /rooms/'));
    expect(find.text('room'), findsOneWidget);
  });

  /// CodeRabbit 4515288085: event ids of rooms v3+ are standard base64,
  /// with `+` and `/`; a raw `+` in a query is read back as a space.
  testWidgets('a message whose id has a "+" opens scrolled to that very '
      'message', (tester) async {
    const plusId = r'$abc+def/ghi=';

    await pumpRouter(
      tester,
      (context) => context.goToRoomWithEvent(roomId, plusId),
    );

    expect(roomEvent, plusId);
  });
}
