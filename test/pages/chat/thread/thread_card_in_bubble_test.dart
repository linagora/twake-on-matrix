// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../fake_client.dart';

class _FakeUploadManager implements UploadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

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
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpRootWithCard(
    WidgetTester tester, {
    String rootBody = 'the root',
    bool withLastReply = true,
    String lastReplyText = 'See you tomorrow',
    double screenWidth = 400,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(screenWidth, 900);
    addTearDown(tester.view.reset);

    final room = Room(id: '!room:example.org', client: client);
    final root = Event(
      content: {'msgtype': 'm.text', 'body': rootBody},
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
                maxWidth: screenWidth,
                selectMode: false,
                threadCard: ThreadSummaryCard(
                  replyCount: 3,
                  lastReplyAuthor: withLastReply ? 'Bob' : null,
                  lastReplyText: withLastReply ? lastReplyText : null,
                  lastReplyTime: withLastReply
                      ? DateTime.now().subtract(
                          const Duration(minutes: 5, seconds: 10),
                        )
                      : null,
                  // As chat_event_list_item wires it.
                  onOwnBubble: root.isOwnMessage,
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

  /// CodeRabbit review 5829198697 (nitpick): the card was built as on a
  /// received bubble. The root is sent by the user of the client.
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

  /// THR-M-02: the web card is `width: 100%` of its bubble; here it was
  /// as narrow as its own text under a wider root.
  testWidgets('the card is as wide as the bubble, under a root longer than '
      'the card', (tester) async {
    await pumpRootWithCard(
      tester,
      rootBody:
          'the root of this thread, long enough to fill the bubble and wrap '
          'onto a second line',
      // The count alone: narrower than the root.
      withLastReply: false,
    );

    final text = tester.getRect(
      find.textContaining('the root of this thread', findRichText: true).first,
    );
    final cardRect = tester.getRect(find.byType(ThreadSummaryCard));
    expect(cardRect.width, greaterThanOrEqualTo(text.width));
  });

  /// THR-M-02: the web bubble is `inline-block` (fit-content): short
  /// content, a short root with a short last reply, makes a narrower bubble
  /// than a root that wraps at the widest bubble.
  testWidgets('under a short root the bubble stays narrower than under a '
      'long one', (tester) async {
    await pumpRootWithCard(
      tester,
      rootBody: 'hi',
      lastReplyText: 'See you',
      screenWidth: 800,
    );
    final short = tester.getRect(find.byType(MessageBubble)).width;

    await pumpRootWithCard(
      tester,
      rootBody:
          'the root of this thread, long enough to fill the bubble and wrap '
          'onto a second line, and then some more words to be sure it wraps',
      lastReplyText: 'See you',
      screenWidth: 800,
    );
    final long = tester.getRect(find.byType(MessageBubble)).width;

    expect(short, lessThan(long));
  });

  /// THR-M-02, reference design of the maintainer (09/11, web ThreadCard):
  /// a short root « echo 5 » whose card shows the whole line « cguyon: test ·
  /// il y a 2 secondes ». The bubble is fit-content: min(widest bubble,
  /// max(root, natural width of the card)). The last reply is cut with an
  /// ellipsis only once the bubble reaches its widest.
  group('the card under a short root', () {
    /// The painted line of the last reply.
    RenderParagraph lastReplyLine(WidgetTester tester) {
      final text = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byType(ThreadSummaryCard),
              matching: find.byType(RichText),
            ),
          )
          .singleWhere((t) => t.text.toPlainText().startsWith('Bob'));
      return tester.renderObject<RenderParagraph>(find.byWidget(text));
    }

    double bubbleWidth(WidgetTester tester) =>
        tester.getRect(find.byType(MessageBubble)).width;

    /// Every painted paragraph of the card.
    List<RenderParagraph> cardParagraphs(WidgetTester tester) => tester
        .widgetList<RichText>(
          find.descendant(
            of: find.byType(ThreadSummaryCard),
            matching: find.byType(RichText),
          ),
        )
        .map(
          (text) => tester.renderObject<RenderParagraph>(find.byWidget(text)),
        )
        .toList();

    /// The paragraph of the card that shows [text], whatever else it shows.
    RenderParagraph paragraphShowing(WidgetTester tester, String text) =>
        cardParagraphs(tester).firstWhere(
          (p) => p.text.toPlainText().contains(text),
          orElse: () => fail('no paragraph of the card shows « $text »'),
        );

    Rect rectOf(RenderParagraph paragraph) =>
        paragraph.localToGlobal(Offset.zero) & paragraph.size;

    /// Laid out whole: not cut, not wrapped, inside the bubble.
    void expectWhole(WidgetTester tester, RenderParagraph paragraph) {
      final plain = paragraph.text.toPlainText();
      expect(paragraph.didExceedMaxLines, isFalse, reason: '« $plain » is cut');
      expect(
        paragraph.size.width,
        moreOrLessEquals(
          paragraph.getMaxIntrinsicWidth(double.infinity),
          epsilon: 0.5,
        ),
        reason: '« $plain » is not on one line',
      );
      final bubble = tester.getRect(find.byType(MessageBubble));
      final rect = rectOf(paragraph);
      expect(rect.left, greaterThanOrEqualTo(bubble.left));
      expect(rect.right, lessThanOrEqualTo(bubble.right));
    }

    testWidgets('a short last reply is shown whole: the card widens the '
        'bubble to it', (tester) async {
      await pumpRootWithCard(
        tester,
        rootBody: 'ok',
        withLastReply: false,
        screenWidth: 800,
      );
      final countOnly = bubbleWidth(tester);

      await pumpRootWithCard(
        tester,
        rootBody: 'ok',
        lastReplyText: 'See you',
        screenWidth: 800,
      );

      final line = lastReplyLine(tester);
      expect(tester.takeException(), isNull);
      expect(line.didExceedMaxLines, isFalse, reason: 'no ellipsis');
      expect(
        line.size.width,
        moreOrLessEquals(line.getMaxIntrinsicWidth(double.infinity)),
      );
      expect(bubbleWidth(tester), greaterThan(countOnly));
    });

    /// THR-M-02, decision of the maintainer (09/11): the relative age stays
    /// whole; only the text of the reply is cut once the bubble is at its
    /// widest.
    testWidgets('a long last reply at the widest bubble keeps its age whole; '
        'only its text is cut', (tester) async {
      await pumpRootWithCard(
        tester,
        rootBody: List.filled(60, 'word').join(' '),
        withLastReply: false,
        screenWidth: 800,
      );
      final widest = bubbleWidth(tester);

      const long =
          'Let us meet on Thursday at the usual place near the station, '
          'and bring the slides of the review with you please';
      await pumpRootWithCard(
        tester,
        rootBody: 'ok',
        lastReplyText: long,
        screenWidth: 800,
      );

      expect(tester.takeException(), isNull);
      expect(bubbleWidth(tester), lessThanOrEqualTo(widest));
      final age = paragraphShowing(tester, '5 minutes ago');
      expect(
        age.didExceedMaxLines,
        isFalse,
        reason: 'the age is cut with the reply',
      );
      expectWhole(tester, age);
      final reply = paragraphShowing(tester, 'Bob');
      final plain = reply.text.toPlainText();
      expect(
        reply.didExceedMaxLines ||
            (plain.contains('…') && !plain.contains(long)),
        isTrue,
        reason: 'the text of the reply is cut with an ellipsis',
      );
    });

    testWidgets('a short last reply: nothing is cut, and the bubble holds the '
        'whole line, age included', (tester) async {
      await pumpRootWithCard(
        tester,
        rootBody: 'ok',
        lastReplyText: 'See you',
        screenWidth: 800,
      );

      expect(tester.takeException(), isNull);
      for (final paragraph in cardParagraphs(tester)) {
        expectWhole(tester, paragraph);
      }
      expect(
        tester.getRect(find.byType(MessageBubble)).right,
        greaterThanOrEqualTo(
          rectOf(paragraphShowing(tester, '5 minutes ago')).right,
        ),
      );
    });

    testWidgets('a last reply made of one long link stops at the widest '
        'bubble, cut with an ellipsis', (tester) async {
      await pumpRootWithCard(
        tester,
        rootBody: List.filled(60, 'word').join(' '),
        withLastReply: false,
        screenWidth: 800,
      );
      final widest = bubbleWidth(tester);

      await pumpRootWithCard(
        tester,
        rootBody: 'ok',
        // No slash nor dash after the host: nowhere to break the line.
        lastReplyText:
            'https://meet.example.org/'
            'Xk9fQ2mLp7RtZs4WvBn8YcJd3HaGe6UoTi1KqPxMwNrEySb5FlVg0CjDhAzOu',
        screenWidth: 800,
      );

      expect(tester.takeException(), isNull);
      expect(bubbleWidth(tester), lessThanOrEqualTo(widest));
      expect(lastReplyLine(tester).didExceedMaxLines, isTrue);
    });
  });
}
