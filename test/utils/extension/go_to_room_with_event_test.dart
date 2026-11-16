import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/utils/extension/build_context_extension.dart';

const _roomId = '!room:example.org';
const _rootId = r'$root:example.org';
const _replyId = r'$reply:example.org';

/// The `event` the room screen read from its location, last time built.
String? _roomEvent;

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

Widget _page(String name) => Scaffold(body: Text(name));

List<RouteBase> _routes(void Function(BuildContext context) open) => [
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
      _roomEvent = state.uri.queryParameters['event'];
      return _page('room');
    },
    routes: [
      GoRoute(path: 'threads/:rootid', builder: (_, _) => _page('thread')),
    ],
  ),
];

/// Pumps the app, taps "open" which runs [open], and lets it settle.
Future<_RecordingRouter> _pumpRouter(
  WidgetTester tester,
  void Function(BuildContext context) open,
) async {
  _roomEvent = null;
  final router = _RecordingRouter(_routes(open));
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return router;
}

void _openThreadReply(BuildContext context) =>
    context.goToRoomWithEvent(_roomId, _replyId, threadRootId: _rootId);

/// THR-M-11: a thread reply opened from the search or a link
/// opens its thread screen, scrolled to the reply, over its room. One
/// navigation to the nested route `/rooms/:roomId/threads/:rootId?event=`
/// builds both pages; a `go` to the room then a `push` of the thread was
/// two navigations, the second racing the first.
void main() {
  _threadReplyTests();
  _roomMessageTests();
  _encodingTests();
}

void _threadReplyTests() {
  testWidgets('a thread reply opens with one navigation to its thread, '
      'scrolled to it', (tester) async {
    final router = await _pumpRouter(tester, _openThreadReply);

    expect(router.navigations, [
      'go ${const ThreadRoute(roomid: _roomId, rootid: _rootId, event: _replyId).location}',
    ]);
  });

  testWidgets('the thread screen of the reply is shown over its room', (
    tester,
  ) async {
    await _pumpRouter(tester, _openThreadReply);

    expect(find.text('thread'), findsOneWidget);
    expect(find.text('room', skipOffstage: false), findsOneWidget);
  });
}

void _roomMessageTests() {
  testWidgets('a message of the room opens the room, scrolled to it', (
    tester,
  ) async {
    final router = await _pumpRouter(
      tester,
      (context) => context.goToRoomWithEvent(_roomId, _replyId),
    );

    expect(router.navigations, hasLength(1));
    expect(router.navigations.single, startsWith('go /rooms/'));
    expect(find.text('room'), findsOneWidget);
  });
}

/// CodeRabbit 4515288085: event ids of rooms v3+ are standard base64,
/// with `+` and `/`; a raw `+` in a query is read back as a space.
void _encodingTests() {
  testWidgets('a message whose id has a "+" opens scrolled to that very '
      'message', (tester) async {
    const plusId = r'$abc+def/ghi=';

    await _pumpRouter(
      tester,
      (context) => context.goToRoomWithEvent(_roomId, plusId),
    );

    expect(_roomEvent, plusId);
  });
}
