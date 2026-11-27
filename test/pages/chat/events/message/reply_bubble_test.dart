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
import 'package:twake_chat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:twake_chat/pages/chat/events/reply_content.dart';
import 'package:twake_chat/utils/custom_scroll_behaviour.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';

import '../../../../fake_client.dart';

const _me = '@alice:example.org';
const _bob = '@bob:example.org';
const _carol = '@carol:example.org';
const _quotedId = r'$quoted:example.org';
const _quotedBody = 'See you at noon';
const _replyBody = 'Works for me';
const _caption = 'Reply to Carol';

/// Overlap of the message bubble on the quoted bubble.
const _overlap = 12.0;

class _FakeUploadManager implements UploadManager {
  @override
  Future<MatrixFile?> getMatrixFile(
    String eventId, {
    required Room room,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeClient extends Client {
  _FakeClient()
    : super(
        'reply-bubble-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => _me;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Room room;

  setUp(() {
    room = Room(id: '!room:example.org', client: _FakeClient());
    for (final (id, name) in [(_bob, 'Bob'), (_carol, 'Carol')]) {
      room.setState(
        User(id, displayName: name, membership: 'join', room: room),
      );
    }
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<UploadManager>(_FakeUploadManager());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Event message(
    String id, {
    required String sender,
    required Map<String, Object?> content,
    Map<String, Object?>? unsigned,
  }) => Event(
    content: content,
    type: EventTypes.Message,
    eventId: id,
    senderId: sender,
    unsigned: unsigned,
    originServerTs: DateTime.fromMillisecondsSinceEpoch(1432735824653),
    status: EventStatus.synced,
    room: room,
  );

  Event quoted({String body = _quotedBody}) => message(
    _quotedId,
    sender: _carol,
    content: {'msgtype': MessageTypes.Text, 'body': body},
  );

  /// A reply to the quoted message, inside the thread of [thread] if given.
  Event reply({
    String sender = _bob,
    Map<String, Object?>? content,
    String? thread,
  }) => message(
    r'$reply:example.org',
    sender: sender,
    content: {
      ...content ?? {'msgtype': MessageTypes.Text, 'body': _replyBody},
      'm.relates_to': {
        if (thread != null) ...{'rel_type': 'm.thread', 'event_id': thread},
        'm.in_reply_to': {'event_id': _quotedId},
      },
    },
  );

  Future<void> pumpApp(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: ThemeBuilder(
          builder: (context, themeMode, primaryColor) => MaterialApp(
            locale: locale,
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
            home: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pumps the row of [event]; returns the ids it asked to scroll to.
  Future<List<String>> pumpRow(
    WidgetTester tester,
    Event event, {
    Event? quotedEvent,
    Locale locale = const Locale('en'),
  }) async {
    final isHoverNotifier = ValueNotifier<String?>(null);
    addTearDown(isHoverNotifier.dispose);
    final jumps = <String>[];

    await pumpApp(
      tester,
      MessageContentWithTimestampBuilder(
        event: event,
        timeline: Timeline(
          room: room,
          chunk: TimelineChunk(events: [event, ?quotedEvent]),
        ),
        isHoverNotifier: isHoverNotifier,
        listHorizontalActionMenu: const [],
        maxWidth: 400,
        listActions: const [],
        selectMode: false,
        scrollToEventId: jumps.add,
      ),
      locale: locale,
    );
    return jumps;
  }

  Finder text(String value) => find.textContaining(value, findRichText: true);

  /// The message bubble: the one holding the text of the message.
  Finder bubbleOf(String body) => find
      .ancestor(of: text(body).first, matching: find.byType(MessageBubble))
      .first;

  void expectOutsideAndAbove(
    WidgetTester tester,
    Finder part, {
    String body = _replyBody,
  }) {
    expect(part, findsWidgets);
    expect(
      find.descendant(of: bubbleOf(body), matching: part),
      findsNothing,
      reason: 'drawn inside the message bubble',
    );
    expect(
      tester.getRect(part.first).bottom,
      lessThanOrEqualTo(tester.getRect(bubbleOf(body)).top),
      reason: 'not above the message bubble',
    );
  }

  /// The painted box closest around the quoted text.
  Finder quotedBubble() => find
      .ancestor(
        of: text(_quotedBody).first,
        matching: find.byType(DecoratedBox),
      )
      .first;

  testWidgets('a reply says whom it replies to, above its bubble', (
    tester,
  ) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    expectOutsideAndAbove(tester, text(_caption));
  });

  testWidgets('the quoted text is above and outside the message bubble', (
    tester,
  ) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    expectOutsideAndAbove(tester, text(_quotedBody));
  });

  testWidgets('the caption sits above the quoted text', (tester) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    expect(text(_caption), findsOneWidget);
    expect(
      tester.getRect(text(_caption)).bottom,
      lessThanOrEqualTo(tester.getRect(text(_quotedBody)).top),
    );
  });

  testWidgets('the message bubble overlaps the quoted bubble by 12', (
    tester,
  ) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    expectOutsideAndAbove(tester, text(_quotedBody));
    expect(
      tester.getRect(quotedBubble()).bottom -
          tester.getRect(bubbleOf(_replyBody)).top,
      moreOrLessEquals(_overlap, epsilon: 0.5),
    );
  });

  testWidgets('the quoted bubble is opaque and pale, to hide the wallpaper', (
    tester,
  ) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    final box = tester.widget<DecoratedBox>(quotedBubble());
    final color = (box.decoration as BoxDecoration).color!;
    final primary = Theme.of(
      tester.element(text(_quotedBody).first),
    ).colorScheme.primary;
    expect(color.a, 1.0, reason: 'the wallpaper shows through');
    expect(color.computeLuminance(), greaterThan(0.7), reason: 'not pale');
    expect(color, isNot(primary));
  });

  testWidgets('the quoted name appears in the caption only, never in blue', (
    tester,
  ) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    expect(text('Carol'), findsOneWidget);
    expect(text(_caption), findsOneWidget);
    final primary = Theme.of(
      tester.element(text(_caption)),
    ).colorScheme.primary;
    final colors = <Color?>[];
    void collect(InlineSpan span, Color? inherited) {
      final color = span.style?.color ?? inherited;
      if (span is TextSpan) {
        if (span.text?.contains('Carol') ?? false) colors.add(color);
        for (final child in span.children ?? const <InlineSpan>[]) {
          collect(child, color);
        }
      }
    }

    collect(tester.widget<RichText>(text(_caption)).text, null);
    expect(colors, isNotEmpty);
    expect(colors, isNot(contains(primary)));
  });

  testWidgets('the sender name stays inside the message bubble', (
    tester,
  ) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    expectOutsideAndAbove(tester, text(_caption));
    expect(
      find.descendant(of: bubbleOf(_replyBody), matching: find.text('Bob')),
      findsOneWidget,
    );
  });

  testWidgets('a long quoted text is cut to one line', (tester) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());
    final oneLine = tester.getSize(text(_quotedBody).first).height;

    final long = '$_quotedBody ${'and then some more ' * 20}';
    await tester.pumpWidget(const SizedBox());
    await pumpRow(tester, reply(), quotedEvent: quoted(body: long));

    expect(tester.takeException(), isNull);
    expectOutsideAndAbove(tester, text(_quotedBody));
    expect(tester.getSize(text(_quotedBody).first).height, oneLine);
    expect(
      tester.getRect(text(_quotedBody).first).right,
      lessThanOrEqualTo(400),
    );
  });

  testWidgets('on an incoming reply, the quote starts with the bubble', (
    tester,
  ) async {
    await pumpRow(tester, reply(), quotedEvent: quoted());

    expectOutsideAndAbove(tester, text(_quotedBody));
    final bubble = tester.getRect(bubbleOf(_replyBody));
    expect(
      tester.getRect(quotedBubble()).left,
      moreOrLessEquals(bubble.left, epsilon: 12),
    );
    expect(
      tester.getRect(text(_caption)).left,
      moreOrLessEquals(bubble.left, epsilon: 16),
    );
  });

  testWidgets('on an own reply, caption and quote are aligned right', (
    tester,
  ) async {
    await pumpRow(tester, reply(sender: _me), quotedEvent: quoted());

    expectOutsideAndAbove(tester, text(_caption));
    expectOutsideAndAbove(tester, text(_quotedBody));
    final bubble = tester.getRect(bubbleOf(_replyBody));
    expect(
      tester.getRect(quotedBubble()).right,
      moreOrLessEquals(bubble.right, epsilon: 12),
    );
    expect(
      tester.getRect(text(_caption)).right,
      moreOrLessEquals(bubble.right, epsilon: 16),
    );
  });

  for (final (what, label) in [
    ('the caption', _caption),
    ('the quoted bubble', _quotedBody),
  ]) {
    testWidgets('a tap on $what jumps to the quoted message', (tester) async {
      final jumps = await pumpRow(tester, reply(), quotedEvent: quoted());
      expectOutsideAndAbove(tester, text(label));

      await tester.tap(text(label));
      await tester.pumpAndSettle();

      expect(jumps, [_quotedId]);
    });
  }

  testWidgets('a quote that cannot be loaded leaves the message readable', (
    tester,
  ) async {
    await pumpRow(tester, reply());

    expect(tester.takeException(), isNull);
    expect(bubbleOf(_replyBody), findsOneWidget);
    expect(text(_quotedBody), findsNothing);
  });

  for (final (language, generic) in [
    ('en', RegExp('^￼?Reply\$')),
    ('fr', RegExp('^￼?Répon(dre|se)\$')),
  ]) {
    testWidgets('a quote not loaded is captioned "Reply" with no name '
        '($language)', (tester) async {
      // Only a reply carrying `m.relates_to.event_id`, as in a thread, gets
      // the "..." placeholder.
      await pumpRow(
        tester,
        reply(thread: r'$root:example.org'),
        locale: Locale(language),
      );

      expect(text('...'), findsOneWidget);
      // Bob wrote the reply: his name is the sender one, in his bubble only.
      expect(text('Bob'), findsOneWidget);
      expectOutsideAndAbove(
        tester,
        find.textContaining(generic, findRichText: true),
      );
    });
  }

  testWidgets('a deleted quote still shows above and jumps', (tester) async {
    final deleted = message(
      _quotedId,
      sender: _carol,
      content: {},
      unsigned: {
        'redacted_because': {
          'type': EventTypes.Redaction,
          'event_id': r'$redaction:example.org',
          'sender': _carol,
          'origin_server_ts': 1432735824653,
          'content': <String, Object?>{},
        },
      },
    );
    final jumps = await pumpRow(tester, reply(), quotedEvent: deleted);

    expectOutsideAndAbove(tester, text(_caption));
    await tester.tap(text(_caption));
    await tester.pumpAndSettle();

    expect(jumps, [_quotedId]);
  });

  testWidgets('an image reply draws its quote outside the bubble', (
    tester,
  ) async {
    await pumpRow(
      tester,
      reply(
        content: {
          'msgtype': MessageTypes.Image,
          'body': _replyBody,
          'filename': 'photo.png',
          'info': {'h': 100, 'w': 100, 'mimetype': 'image/png', 'size': 68},
          'url': 'mxc://example.org/photo',
        },
      ),
      quotedEvent: quoted(),
    );

    expectOutsideAndAbove(tester, text(_caption));
    expectOutsideAndAbove(tester, text(_quotedBody));
  });

  testWidgets('in a right-to-left language the quote stays above the bubble', (
    tester,
  ) async {
    await pumpRow(
      tester,
      reply(),
      quotedEvent: quoted(),
      locale: const Locale('ar'),
    );

    expect(tester.takeException(), isNull);
    expectOutsideAndAbove(tester, text(_quotedBody));
  });

  testWidgets('a message that is not a reply is one bubble, with no quote', (
    tester,
  ) async {
    final plain = message(
      r'$plain:example.org',
      sender: _bob,
      content: {'msgtype': MessageTypes.Text, 'body': _replyBody},
    );
    await pumpRow(tester, plain, quotedEvent: quoted());

    expect(find.byType(MessageBubble), findsOneWidget);
    expect(text('Reply to'), findsNothing);
    expect(text(_quotedBody), findsNothing);
  });

  testWidgets('the composer preview keeps the name and text, no caption', (
    tester,
  ) async {
    final event = quoted();
    await pumpApp(
      tester,
      SizedBox(
        height: 60,
        child: ReplyContent(
          event,
          timeline: Timeline(
            room: room,
            chunk: TimelineChunk(events: [event]),
          ),
        ),
      ),
    );

    expect(find.text('Carol'), findsOneWidget);
    expect(find.text(_quotedBody), findsOneWidget);
    expect(text('Reply to'), findsNothing);
  });
}
