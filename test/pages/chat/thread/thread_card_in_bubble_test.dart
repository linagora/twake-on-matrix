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
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_summary.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
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

/// Need (Clément, 2026-11-25, as the web D800 of twake-space-chat): the
/// thread of a root is ONE row at the very foot of its bubble, under the
/// time, edge to edge of the bubble, a 1 px line above it; the faces of who
/// replied are ringed with the colour of the bubble.
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

  Future<void> pumpRootWithRow(
    WidgetTester tester, {
    String rootBody = 'the root',
    String sender = '@alice:example.org',
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
      senderId: sender,
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
                  repliers: const [
                    ThreadReplier(
                      userId: '@bob:example.org',
                      displayName: 'Bob',
                    ),
                    ThreadReplier(
                      userId: '@cid:example.org',
                      displayName: 'Cid',
                    ),
                  ],
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

  Rect rowRect(WidgetTester tester) =>
      tester.getRect(find.byType(ThreadSummaryCard));

  Rect bubbleRect(WidgetTester tester) =>
      tester.getRect(find.byType(MessageBubble));

  /// The time of the bubble, as the user reads it (HH:mm).
  Finder bubbleTime() =>
      find.textContaining(RegExp(r'^\d{2}:\d{2}$'), findRichText: true);

  /// The colour the bubble is painted with.
  Color bubbleColor(WidgetTester tester) {
    final bubble = tester.widget<MessageBubble>(find.byType(MessageBubble));
    return bubble.color ??
        (bubble.isOwnMessage
            ? LinagoraRefColors.material().primary[95]!
            : LinagoraSysColors.material().onPrimary);
  }

  /// A circle of [ring] around the first face of the row.
  Finder ringOfFirstFace(Color ring) => find.ancestor(
    of: find
        .descendant(
          of: find.byType(ThreadSummaryCard),
          matching: find.byType(Avatar),
        )
        .first,
    matching: find.byWidgetPredicate((widget) {
      final decoration = widget is DecoratedBox ? widget.decoration : null;
      if (decoration is! BoxDecoration) return false;
      final border = decoration.border;
      return (decoration.shape == BoxShape.circle ||
              decoration.borderRadius != null) &&
          (decoration.color == ring ||
              (border is Border && border.top.color == ring));
    }),
  );

  testWidgets('the row is inside the bubble of the root', (tester) async {
    await pumpRootWithRow(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.ancestor(
        of: find.byType(ThreadSummaryCard),
        matching: find.byType(MessageBubble),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the row comes after the text of the root and under the time '
      'of the bubble', (tester) async {
    await pumpRootWithRow(tester);

    final text = tester.getRect(
      find.textContaining('the root', findRichText: true).first,
    );
    final time = tester.getRect(bubbleTime().first);
    final row = rowRect(tester);
    expect(row.top, greaterThanOrEqualTo(text.bottom));
    expect(row.top, greaterThanOrEqualTo(time.bottom));
  });

  testWidgets('the row is the very foot of the bubble', (tester) async {
    await pumpRootWithRow(tester);

    expect(
      rowRect(tester).bottom,
      moreOrLessEquals(bubbleRect(tester).bottom, epsilon: 0.5),
    );
  });

  testWidgets('the row runs edge to edge of the bubble', (tester) async {
    await pumpRootWithRow(tester);

    final row = rowRect(tester);
    final bubble = bubbleRect(tester);
    expect(row.left, moreOrLessEquals(bubble.left, epsilon: 0.5));
    expect(row.right, moreOrLessEquals(bubble.right, epsilon: 0.5));
  });

  testWidgets('the row runs edge to edge under a root that wraps', (
    tester,
  ) async {
    await pumpRootWithRow(
      tester,
      rootBody:
          'the root of this thread, long enough to fill the bubble and wrap '
          'onto a second line',
    );

    final row = rowRect(tester);
    final bubble = bubbleRect(tester);
    expect(row.left, moreOrLessEquals(bubble.left, epsilon: 0.5));
    expect(row.right, moreOrLessEquals(bubble.right, epsilon: 0.5));
  });

  testWidgets('on an own bubble, the faces are ringed with its colour', (
    tester,
  ) async {
    await pumpRootWithRow(tester);

    expect(ringOfFirstFace(bubbleColor(tester)), findsWidgets);
  });

  testWidgets('on a received bubble, the faces are ringed with its colour', (
    tester,
  ) async {
    await pumpRootWithRow(tester, sender: '@dan:example.org');

    expect(ringOfFirstFace(bubbleColor(tester)), findsWidgets);
  });

  /// THR-M-02: the web bubble is `inline-block` (fit-content): the row does
  /// not stretch a short root to the widest bubble.
  testWidgets('under a short root the bubble stays narrower than under a '
      'long one', (tester) async {
    await pumpRootWithRow(tester, rootBody: 'hi', screenWidth: 800);
    final short = bubbleRect(tester).width;

    await pumpRootWithRow(
      tester,
      rootBody:
          'the root of this thread, long enough to fill the bubble and wrap '
          'onto a second line, and then some more words to be sure it wraps',
      screenWidth: 800,
    );
    final long = bubbleRect(tester).width;

    expect(short, lessThan(long));
  });

  /// The size a painted text is drawn at, its parents' styles merged in.
  double? paintedSize(WidgetTester tester, String text) {
    for (final element in find.byType(RichText).evaluate()) {
      double? found;
      void visit(InlineSpan span, TextStyle inherited) {
        final style = inherited.merge(span.style);
        if (span is! TextSpan) return;
        if ((span.text ?? '').contains(text)) found ??= style.fontSize;
        for (final child in span.children ?? const <InlineSpan>[]) {
          visit(child, style);
        }
      }

      visit((element.widget as RichText).text, const TextStyle());
      if (found != null) return found;
    }
    return null;
  }

  /// Need (Clément, 2026-11-25): « N comments » is 2 px smaller than the
  /// text of the message (web: body 15 → label 13).
  testWidgets('the count is 2 px smaller than the text of the root', (
    tester,
  ) async {
    await pumpRootWithRow(tester);

    final body = paintedSize(tester, 'the root');
    expect(body, isNotNull);
    expect(paintedSize(tester, '3 comments'), body! - 2);
  });

  testWidgets('a short root still shows the whole row', (tester) async {
    await pumpRootWithRow(tester, rootBody: 'ok', screenWidth: 800);

    expect(tester.takeException(), isNull);
    final label = tester.getRect(
      find.textContaining('3 comments', findRichText: true),
    );
    final bubble = bubbleRect(tester);
    expect(label.left, greaterThanOrEqualTo(bubble.left));
    expect(label.right, lessThanOrEqualTo(bubble.right));
  });
}
