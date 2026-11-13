import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_events_controller.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_events_view.dart';

/// The room screen or the thread screen as the pinned bar sees it: the
/// room, its pins controller and the two ways a screen scrolls to a message
/// (`scrollToEventId` in the room, `scrollToThreadEvent` in a thread, as
/// chat_event_list_item.dart wires them).
class FakePinsChatController extends Fake implements ChatController {
  FakePinsChatController(this.room, {this.threadRootId});

  @override
  final Room? room;

  @override
  final String? threadRootId;

  @override
  bool get isThread => threadRootId != null;

  @override
  final PinnedEventsController pinnedEventsController =
      PinnedEventsController();

  @override
  final AutoScrollController pinnedMessageScrollController =
      AutoScrollController();

  @override
  Timeline? get timeline => null;

  /// How many times the room conversation was asked to scroll: see
  /// [tapPinnedBar]. Must stay 0 for a thread reply.
  int roomScrolls = 0;

  /// The thread conversation scrolled to.
  final List<String> threadScrolls = [];

  @override
  Future<void> scrollToThreadEvent(String eventId) async =>
      threadScrolls.add(eventId);

  @override
  void handlePopBackFromPinnedScreen(Object? popResult) {}

  void disposeFakes() {
    pinnedEventsController.dispose();
    pinnedMessageScrollController.dispose();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakePinsChatController';
}

/// A router that writes down each navigation asked of it.
class RecordingRouter extends GoRouter {
  RecordingRouter(List<RouteBase> routes, {required String initialLocation})
    : super.routingConfig(
        routingConfig: ValueNotifier(RoutingConfig(routes: routes)),
        initialLocation: initialLocation,
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

/// The room screen at `/rooms/:roomid`, the thread screen above it at
/// `threads/:rootid`; [roomBar] or [threadBar] shows the pinned bar of that
/// screen. The thread page reads « thread screen » so a test sees it open.
List<RouteBase> pinnedBarRoutes({
  FakePinsChatController? roomBar,
  FakePinsChatController? threadBar,
}) => [
  GoRoute(
    path: '/rooms/:roomid',
    builder: (_, _) => Scaffold(
      body: Column(
        children: [
          if (roomBar != null) PinnedEventsView(roomBar),
          const Text('room screen'),
        ],
      ),
    ),
    routes: [
      GoRoute(
        path: 'threads/:rootid',
        builder: (_, _) => Scaffold(
          body: Column(
            children: [
              if (threadBar != null) PinnedEventsView(threadBar),
              const Text('thread screen'),
            ],
          ),
        ),
      ),
    ],
  ),
];

Future<RecordingRouter> pumpPinnedBar(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String initialLocation,
}) async {
  final router = RecordingRouter(routes, initialLocation: initialLocation);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
      builder: (context, child) => Theme(
        data: TwakeThemes.buildTheme(context, Brightness.light),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// The text of a pinned message, as the bar shows it.
Finder pinnedText(String body) => find.textContaining(body, findRichText: true);

/// A read of a private member of the room screen, which a fake cannot have.
final _privateRead = RegExp(r"FakePinsChatController' has no instance \w+ '_");

/// Taps the pinned bar on [body] and counts in [screen] the scrolls of the
/// room conversation it asked for.
///
/// Test-double limit: the scroll of the room, `scrollToEventId`, is an
/// extension on ChatController (chat_scroll_to_event_mixin.dart), so no fake
/// can replace it. Its first step reads the jump state of the room screen,
/// private to the Chat library (`_scrollGeneration` today), which a fake
/// cannot answer: that failed read is the room being asked to move, and is
/// counted here instead of failing the test.
Future<void> tapPinnedBar(
  WidgetTester tester,
  FakePinsChatController screen,
  String body,
) async {
  await runZonedGuarded(() => tester.tap(pinnedText(body)), (error, stack) {
    if (error is NoSuchMethodError && _privateRead.hasMatch(error.toString())) {
      screen.roomScrolls++;
      return;
    }
    Error.throwWithStackTrace(error, stack);
  });
  await tester.pumpAndSettle();
}
