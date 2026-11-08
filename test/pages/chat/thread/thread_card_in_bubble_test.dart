// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/pages/chat/thread/thread_summary_card.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../fake_client.dart';

class _FakeClient extends Client {
  _FakeClient()
    : super(
        'thread-card-in-bubble-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => '@alice:example.org';
}

/// THR-M-02, design correction by Clément (08/11): the card of a thread sits
/// INSIDE the bubble of its root, between the message and the time of the
/// bubble, as the web ThreadCard rendered inside MessageBubble
/// (twake-space-chat src/ui/MessageItem.tsx).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final client = _FakeClient();

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    getIt.registerSingleton(ResponsiveUtils());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpRootWithCard(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    final room = Room(id: '!room:example.org', client: client);
    final root = Event(
      content: {'msgtype': 'm.text', 'body': 'the root'},
      type: EventTypes.Message,
      eventId: r'$root:example.org',
      senderId: '@alice:example.org',
      originServerTs: DateTime.now().subtract(const Duration(hours: 1)),
      room: room,
    );
    final timeline = Timeline(
      room: room,
      chunk: TimelineChunk(events: [root]),
    );
    final isHoverNotifier = ValueNotifier<String?>(null);
    addTearDown(isHoverNotifier.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: ThemeBuilder(
          builder: (context, themeMode, primaryColor) => MaterialApp(
            locale: const Locale('en'),
            scrollBehavior: CustomScrollBehavior(),
            localizationsDelegates: const [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(
              context,
              Brightness.light,
              primaryColor,
            ),
            home: Scaffold(
              body: Message(
                root,
                timeline: timeline,
                isHoverNotifier: isHoverNotifier,
                listHorizontalActionMenu: const [],
                listAction: const [],
                maxWidth: 400,
                selectMode: false,
                threadCard: ThreadSummaryCard(
                  replyCount: 3,
                  lastReplyAuthor: 'Bob',
                  lastReplyText: 'See you tomorrow',
                  lastReplyTime: DateTime.now().subtract(
                    const Duration(minutes: 5, seconds: 10),
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder card() => find.textContaining('3 messages', findRichText: true);

  /// The time of the bubble, as the user reads it (HH:mm).
  Finder bubbleTime() =>
      find.textContaining(RegExp(r'^\d{2}:\d{2}$'), findRichText: true);

  testWidgets('the card is inside the bubble of the root', (tester) async {
    await pumpRootWithCard(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.ancestor(of: card(), matching: find.byType(MessageBubble)),
      findsOneWidget,
    );
  });

  testWidgets('the card comes after the text of the root, and the time of '
      'the bubble after the card', (tester) async {
    await pumpRootWithCard(tester);

    final text = tester.getRect(
      find.textContaining('the root', findRichText: true).first,
    );
    final cardRect = tester.getRect(find.byType(ThreadSummaryCard));
    final time = tester.getRect(bubbleTime().first);
    expect(cardRect.top, greaterThanOrEqualTo(text.bottom));
    expect(time.top, greaterThanOrEqualTo(cardRect.bottom));
  });

  testWidgets('the card stands out on the bubble of an own message', (
    tester,
  ) async {
    await pumpRootWithCard(tester);

    final bubble = tester.widget<MessageBubble>(find.byType(MessageBubble));
    final bubbleColor =
        bubble.color ?? LinagoraRefColors.material().primary[95]!;
    final cardColor = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(ThreadSummaryCard),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .singleWhere((decoration) => decoration.border != null)
        .color;
    expect(cardColor, isNotNull);
    expect(cardColor, isNot(bubbleColor));
  });
}
