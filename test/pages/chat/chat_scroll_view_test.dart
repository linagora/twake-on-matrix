import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_event_list_item.dart';
import 'package:twake_chat/pages/chat/chat_scroll_view.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../fake_client.dart';

const _initialSize = Size(400, 600);

class _FakeTimeline extends Fake implements Timeline {
  @override
  bool isRequestingHistory = false;

  @override
  bool isRequestingFuture = false;

  @override
  bool get canRequestHistory => false;

  @override
  bool get canRequestFuture => false;
}

class _FakeChatController extends Fake implements ChatController {
  _FakeChatController(this.timeline);

  @override
  final Timeline timeline;

  @override
  final AutoScrollController scrollController = AutoScrollController();

  @override
  double? jumpListCacheExtent;

  @override
  String? unreadReceivedMessageLocation;

  @override
  bool isInViewPortCondition(
    double deltaTopReversed,
    double deltaBottomReversed,
    double viewPortDimension,
  ) => false;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeChatController';
}

/// A reaction is hidden from the timeline: its list item has no Message.
Future<Event> _hiddenReaction() async {
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<ResponsiveUtils>()) {
    getIt.registerSingleton(ResponsiveUtils());
  }
  final client = await getClient();
  return Event(
    content: {
      'm.relates_to': {
        'rel_type': 'm.annotation',
        'event_id': '\$target:example.org',
        'key': '👍',
      },
    },
    type: EventTypes.Reaction,
    eventId: '\$reaction:example.org',
    senderId: '@example:example.org',
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    room: Room(id: '!room:example.abc', client: client),
  );
}

Future<void> _pumpScrollView(
  WidgetTester tester,
  _FakeChatController controller,
  List<Event> events,
  Size size,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(
          size: size,
          child: ChatScrollView(
            events: events,
            controller: controller,
            constraints: BoxConstraints(
              maxWidth: size.width,
              maxHeight: size.height,
            ),
          ),
        ),
      ),
    ),
  ),
);

ChatEventListItem _builtItem(WidgetTester tester) =>
    tester.widget<ChatEventListItem>(
      find.byType(ChatEventListItem, skipOffstage: false),
    );

/// Pumps the same events at [_initialSize], then at [next], like a relayout
/// that does not come from a Chat setState. Returns the item built first.
Future<ChatEventListItem> _pumpThenResize(
  WidgetTester tester,
  Event event,
  Size next,
) async {
  final controller = _FakeChatController(_FakeTimeline());
  final events = [event];
  await _pumpScrollView(tester, controller, events, _initialSize);
  final before = _builtItem(tester);
  await _pumpScrollView(tester, controller, events, next);
  return before;
}

void main() {
  late Event hiddenEvent;
  setUpAll(() async => hiddenEvent = await _hiddenReaction());

  testWidgets('A height-only relayout (keyboard) keeps the built items', (
    tester,
  ) async {
    expect(hiddenEvent.isVisibleInGui, isFalse);
    final before = await _pumpThenResize(
      tester,
      hiddenEvent,
      const Size(400, 300),
    );

    expect(identical(_builtItem(tester), before), isTrue);
  });

  testWidgets('A width change rebuilds the items', (tester) async {
    final before = await _pumpThenResize(
      tester,
      hiddenEvent,
      const Size(300, 600),
    );

    expect(identical(_builtItem(tester), before), isFalse);
    expect(_builtItem(tester).constraints.maxWidth, 300);
  });

  testWidgets('A moved unread marker rebuilds the items', (tester) async {
    final controller = _FakeChatController(_FakeTimeline());
    final events = [hiddenEvent];
    await _pumpScrollView(tester, controller, events, _initialSize);
    final before = _builtItem(tester);

    controller.unreadReceivedMessageLocation = hiddenEvent.eventId;
    await _pumpScrollView(tester, controller, events, _initialSize);

    expect(identical(_builtItem(tester), before), isFalse);
  });

  testWidgets('A controller rebuild shows the history loader', (tester) async {
    final timeline = _FakeTimeline();
    final controller = _FakeChatController(timeline);
    await _pumpScrollView(tester, controller, [hiddenEvent], _initialSize);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);

    // Chat.updateView calls setState: ChatEventList passes a new events list.
    timeline.isRequestingHistory = true;
    await _pumpScrollView(tester, controller, [hiddenEvent], _initialSize);

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
  });
}
