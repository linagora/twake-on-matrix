import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/chat/events/message/message_container.dart';
import 'package:twake_chat/pages/chat/events/message/message_style.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../../../fake_client.dart';

class _FakeClient extends Client {
  _FakeClient()
    : super(
        'message-container-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => '@alice:example.org';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final client = _FakeClient();
  final highlightTint = MessageStyle.jumpHighlightTint;
  const rowWidth = 400.0;

  late Event event;
  late ValueNotifier<String?> highlightedEventId;
  late AutoScrollController scrollController;

  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    event = Event(
      content: {'body': 'Hello', 'msgtype': MessageTypes.Text},
      type: EventTypes.Message,
      eventId: r'$target:example.org',
      senderId: '@bob:example.org',
      originServerTs: DateTime(2026, 11, 6),
      room: Room(id: '!room:example.org', client: client),
    );
    highlightedEventId = ValueNotifier(null);
    scrollController = AutoScrollController();
  });

  tearDown(() async {
    highlightedEventId.dispose();
    scrollController.dispose();
    await getIt.reset();
  });

  Future<void> pumpContainer(WidgetTester tester, {bool selected = false}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: rowWidth,
              child: ListView(
                controller: scrollController,
                children: [
                  MessageContainer(
                    event: event,
                    row: const SizedBox(width: 120, height: 40),
                    selected: selected,
                    selectMode: false,
                    highlightedEventIdNotifier: highlightedEventId,
                    autoScrollController: scrollController,
                    scrollIndex: 0,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder tintFinder(Color color) => find.byWidgetPredicate(
    (widget) => widget is ColoredBox && widget.color == color,
  );

  testWidgets('tints the whole row of the highlighted message softly', (
    tester,
  ) async {
    highlightedEventId.value = event.eventId;
    await pumpContainer(tester);

    final tint = tintFinder(highlightTint);
    expect(tint, findsOneWidget);
    expect(tester.getSize(tint).width, rowWidth);
  });

  testWidgets('keeps the tint after the flash is over', (tester) async {
    await pumpContainer(tester);
    highlightedEventId.value = event.eventId;
    unawaited(scrollController.highlight(0, highlightDuration: Duration.zero));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(tintFinder(highlightTint), findsOneWidget);
  });

  testWidgets('drops the tint once the highlight is cleared', (tester) async {
    highlightedEventId.value = event.eventId;
    await pumpContainer(tester);

    highlightedEventId.value = null;
    await tester.pump();

    expect(tintFinder(highlightTint), findsNothing);
  });

  testWidgets('leaves another message untinted', (tester) async {
    highlightedEventId.value = r'$other:example.org';
    await pumpContainer(tester);

    expect(tintFinder(highlightTint), findsNothing);
  });

  testWidgets('shows the selection colour over the highlight', (tester) async {
    highlightedEventId.value = event.eventId;
    await pumpContainer(tester, selected: true);

    expect(
      tintFinder(LinagoraSysColors.material().secondaryContainer),
      findsOneWidget,
    );
    expect(tintFinder(highlightTint), findsNothing);
  });

  testWidgets('flashes with the same soft tint', (tester) async {
    await pumpContainer(tester);

    final tag = tester.widget<AutoScrollTag>(find.byType(AutoScrollTag));
    expect(tag.highlightColor, highlightTint);
  });
}
