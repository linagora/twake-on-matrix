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

void main() {
  late Event hiddenEvent;
  setUpAll(() async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
    final client = await getClient();
    // Hidden from the timeline: its list item is built without a Message.
    hiddenEvent = Event(
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
  });

  Future<void> pumpScrollView(
    WidgetTester tester, {
    required _FakeChatController controller,
    required List<Event> events,
    required double width,
    required double height,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: height,
            child: ChatScrollView(
              events: events,
              controller: controller,
              constraints: BoxConstraints(maxWidth: width, maxHeight: height),
            ),
          ),
        ),
      ),
    ),
  );

  ChatEventListItem builtItem(WidgetTester tester) =>
      tester.widget<ChatEventListItem>(
        find.byType(ChatEventListItem, skipOffstage: false),
      );

  testWidgets('A height-only relayout (keyboard) keeps the built items', (
    tester,
  ) async {
    expect(hiddenEvent.isVisibleInGui, isFalse);
    final controller = _FakeChatController(_FakeTimeline());
    final events = [hiddenEvent];
    await pumpScrollView(
      tester,
      controller: controller,
      events: events,
      width: 400,
      height: 600,
    );
    final before = builtItem(tester);

    await pumpScrollView(
      tester,
      controller: controller,
      events: events,
      width: 400,
      height: 300,
    );

    expect(identical(builtItem(tester), before), isTrue);
  });

  testWidgets('A width change rebuilds the items', (tester) async {
    final controller = _FakeChatController(_FakeTimeline());
    final events = [hiddenEvent];
    await pumpScrollView(
      tester,
      controller: controller,
      events: events,
      width: 400,
      height: 600,
    );
    final before = builtItem(tester);

    await pumpScrollView(
      tester,
      controller: controller,
      events: events,
      width: 300,
      height: 600,
    );

    expect(identical(builtItem(tester), before), isFalse);
    expect(builtItem(tester).constraints.maxWidth, 300);
  });

  testWidgets('A controller rebuild shows the history loader', (tester) async {
    final timeline = _FakeTimeline();
    final controller = _FakeChatController(timeline);
    await pumpScrollView(
      tester,
      controller: controller,
      events: [hiddenEvent],
      width: 400,
      height: 600,
    );
    expect(find.byType(CupertinoActivityIndicator), findsNothing);

    // Chat.updateView calls setState: ChatEventList passes a new events list.
    timeline.isRequestingHistory = true;
    await pumpScrollView(
      tester,
      controller: controller,
      events: [hiddenEvent],
      width: 400,
      height: 600,
    );

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
  });
}
