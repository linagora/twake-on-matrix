// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_view_body_style.dart';
import 'package:twake_chat/pages/chat/events/message/message_container.dart';
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

/// A local store that answers for the quoted message when the test says so.
class _SlowDatabase extends MockDatabase {
  final stored = Completer<Event?>();

  @override
  Future<Event?> getEventById(String eventId, Room room) => stored.future;
}

class _FakeClient extends Client {
  _FakeClient({http.Client? httpClient, DatabaseApi? database})
    : super(
        'reply-bubble-test',
        httpClient: httpClient ?? FakeMatrixApi(),
        database: database ?? MockDatabase(),
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
  /// With [fallingBack], a plain thread message: its reply id is a fallback.
  Event reply({
    String sender = _bob,
    Map<String, Object?>? content,
    String? thread,
    bool fallingBack = false,
  }) => message(
    r'$reply:example.org',
    sender: sender,
    content: {
      ...content ?? {'msgtype': MessageTypes.Text, 'body': _replyBody},
      'm.relates_to': {
        if (thread != null) ...{'rel_type': 'm.thread', 'event_id': thread},
        if (fallingBack) 'is_falling_back': true,
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

  /// Pumps the row of [event]; returns the ids it asked to scroll to. [wrap]
  /// puts the row in what the chat draws around it.
  Future<List<String>> pumpRow(
    WidgetTester tester,
    Event event, {
    Event? quotedEvent,
    Locale locale = const Locale('en'),
    Widget Function(Widget row)? wrap,
    Timeline? timeline,
  }) async {
    final isHoverNotifier = ValueNotifier<String?>(null);
    addTearDown(isHoverNotifier.dispose);
    final jumps = <String>[];

    final row = MessageContentWithTimestampBuilder(
      event: event,
      timeline:
          timeline ??
          Timeline(
            room: room,
            chunk: TimelineChunk(events: [event, ?quotedEvent]),
          ),
      isHoverNotifier: isHoverNotifier,
      listHorizontalActionMenu: const [],
      maxWidth: 400,
      listActions: const [],
      selectMode: false,
      scrollToEventId: jumps.add,
    );

    await pumpApp(tester, wrap?.call(row) ?? row, locale: locale);
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

  for (final (kind, thread) in [
    ('an ordinary reply', null),
    ('a thread reply', r'$root:example.org'),
  ]) {
    for (final (language, generic) in [
      ('en', RegExp('^\uFFFC?Reply\$')),
      ('fr', RegExp('^\uFFFC?Répon(dre|se)\$')),
    ]) {
      testWidgets('on $kind, a quote not loaded shows "..." captioned "Reply" '
          'with no name ($language)', (tester) async {
        await pumpRow(tester, reply(thread: thread), locale: Locale(language));

        expect(text('...'), findsOneWidget);
        expectOutsideAndAbove(tester, text('...'));
        // Bob wrote the reply: his name is the sender one, in his bubble only.
        expect(text('Bob'), findsOneWidget);
        expectOutsideAndAbove(
          tester,
          find.textContaining(generic, findRichText: true),
        );
      });
    }

    testWidgets('on $kind, a tap on a quote not loaded jumps to the quoted '
        'message', (tester) async {
      final jumps = await pumpRow(tester, reply(thread: thread));
      expect(text('...'), findsOneWidget);

      await tester.tap(text('...'));
      await tester.pumpAndSettle();

      expect(jumps, [_quotedId]);
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

  /// Pumps the reply in its chat row, over the chat page colour, and returns a
  /// reader of the colour painted at a point of the screen.
  Future<Color Function(Offset)> paintRow(
    WidgetTester tester, {
    bool selected = false,
    bool highlighted = false,
  }) async {
    const screen = Key('screen');
    final event = reply();
    final highlightedId = ValueNotifier<String?>(
      highlighted ? event.eventId : null,
    );
    addTearDown(highlightedId.dispose);

    await pumpRow(
      tester,
      event,
      quotedEvent: quoted(),
      wrap: (row) => RepaintBoundary(
        key: screen,
        child: ColoredBox(
          color: ChatViewBodyStyle.backgroundColor,
          child: MessageContainer(
            event: event,
            row: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: row,
            ),
            selected: selected,
            selectMode: false,
            highlightedEventIdNotifier: highlightedId,
          ),
        ),
      ),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(screen),
    );
    final origin = tester.getTopLeft(find.byKey(screen));
    late final int width;
    late final ByteData pixels;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      width = image.width;
      pixels = (await image.toByteData())!;
      image.dispose();
    });
    return (point) {
      final local = point - origin;
      final i = (local.dy.floor() * width + local.dx.floor()) * 4;
      return Color.fromARGB(
        255,
        pixels.getUint8(i),
        pixels.getUint8(i + 1),
        pixels.getUint8(i + 2),
      );
    };
  }

  /// The same colour, give or take rounding and the faint bubble shadow.
  Matcher looksLike(Color expected) => predicate<Color>(
    (actual) => [
      actual.r - expected.r,
      actual.g - expected.g,
      actual.b - expected.b,
    ].every((delta) => delta.abs() * 255 <= 3),
    'looks like $expected',
  );

  for (final (state, selected, highlighted) in [
    ('a plain', false, false),
    ('a selected', true, false),
    ('a highlighted', false, true),
  ]) {
    testWidgets('on $state row, the bubble of a reply has no outline of '
        'another colour beside it', (tester) async {
      final colorAt = await paintRow(
        tester,
        selected: selected,
        highlighted: highlighted,
      );
      final bubble = tester.getRect(bubbleOf(_replyBody));
      final y = bubble.center.dy;
      // The row itself, clear of the bubble and of its quote.
      final row = colorAt(Offset(398, y));
      if (selected || highlighted) {
        expect(row, isNot(looksLike(ChatViewBodyStyle.backgroundColor)));
      }

      // Second pixel out, where only the 2px ring could paint.
      for (final x in [bubble.left - 1.5, bubble.right + 1.5]) {
        expect(colorAt(Offset(x, y)), looksLike(row), reason: 'at x = $x');
      }
    });

    testWidgets('on $state row, a gap still parts the bubble from its quote', (
      tester,
    ) async {
      final colorAt = await paintRow(
        tester,
        selected: selected,
        highlighted: highlighted,
      );
      final bubble = tester.getRect(bubbleOf(_replyBody));
      final quote = tester.getRect(quotedBubble());
      final overlap = bubble.intersect(quote);
      final x = overlap.center.dx;

      final ring = colorAt(Offset(x, bubble.top - 1.5));
      // Same column, higher in the padding of the quote: its own colour.
      final quoteColor = colorAt(Offset(x, bubble.top - 5));
      expect(ring, isNot(looksLike(quoteColor)));
      if (!selected && !highlighted) {
        expect(ring, looksLike(ChatViewBodyStyle.backgroundColor));
      }
    });
  }

  /// The generic caption: "Reply", with no name (the icon is a placeholder
  /// character of the same text).
  Finder genericCaption() =>
      find.textContaining(RegExp('^￼?Reply\$'), findRichText: true);

  /// A room whose quoted message is neither in the timeline nor in the local
  /// store [database]; [server] answers when it is asked for it.
  void useRoom({
    required Future<http.Response> Function() server,
    DatabaseApi? database,
    List<Uri>? asked,
  }) {
    final client = _FakeClient(
      // By default the local store answers at once that it has nothing.
      database: database ?? (_SlowDatabase()..stored.complete(null)),
      httpClient: MockClient((request) {
        if (request.url.pathSegments.last != _quotedId) {
          return Future.value(http.Response('{}', 200));
        }
        asked?.add(request.url);
        return server();
      }),
    );
    client.homeserver = Uri.parse('https://example.org');
    client.accessToken = 'token';
    room = Room(id: '!room:example.org', client: client);
    for (final (id, name) in [(_bob, 'Bob'), (_carol, 'Carol')]) {
      room.setState(
        User(id, displayName: name, membership: 'join', room: room),
      );
    }
  }

  Future<http.Response> notFound() async =>
      http.Response('{"errcode":"M_NOT_FOUND","error":"Not found"}', 404);

  /// Lets the server answer: an HTTP response only completes on the real event
  /// loop, which pumping alone never runs.
  Future<void> serverAnswers(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }

  Timeline timelineOf(List<Event> events) => Timeline(
    room: room,
    chunk: TimelineChunk(events: events),
  );

  testWidgets('while the quote is loading, no placeholder and no generic '
      '"Reply" caption show, then the quote does', (tester) async {
    final database = _SlowDatabase();
    useRoom(server: notFound, database: database);

    await pumpRow(tester, reply());

    expect(bubbleOf(_replyBody), findsOneWidget);
    expect(text('...'), findsNothing);
    expect(genericCaption(), findsNothing);

    database.stored.complete(quoted());
    await tester.pumpAndSettle();

    expectOutsideAndAbove(tester, text(_caption));
    expectOutsideAndAbove(tester, text(_quotedBody));
  });

  testWidgets('once loading is over with no quote found, the placeholder '
      'shows', (tester) async {
    final database = _SlowDatabase();
    useRoom(server: notFound, database: database);
    await pumpRow(tester, reply());

    database.stored.complete(null);
    await tester.pumpAndSettle();
    await serverAnswers(tester);

    expect(text('...'), findsOneWidget);
    expect(genericCaption(), findsOneWidget);
  });

  testWidgets('a quote already in the timeline never flashes the placeholder '
      'when its row appears', (tester) async {
    final shown = ValueNotifier(false);
    addTearDown(shown.dispose);
    await pumpRow(
      tester,
      reply(),
      quotedEvent: quoted(),
      wrap: (row) => ValueListenableBuilder(
        valueListenable: shown,
        builder: (context, value, _) => value ? row : const SizedBox(),
      ),
    );

    // The first frame of the row, as when it scrolls into view.
    shown.value = true;
    await tester.pump();

    expect(bubbleOf(_replyBody), findsOneWidget);
    expect(text('...'), findsNothing);
    expect(genericCaption(), findsNothing);
  });

  testWidgets('a quote that cannot be fetched offline ends on the '
      'placeholder, which still jumps', (tester) async {
    useRoom(server: () async => throw http.ClientException('offline'));
    final jumps = await pumpRow(tester, reply());

    expect(tester.takeException(), isNull);
    await tester.tap(text('...'));
    await tester.pumpAndSettle();

    expect(jumps, [_quotedId]);
  });

  testWidgets('a quote whose original is gone is asked to the server once, '
      'however often its row is rebuilt', (tester) async {
    final asked = <Uri>[];
    useRoom(server: notFound, asked: asked);
    final event = reply();
    final timeline = timelineOf([event]);

    for (var build = 0; build < 4; build++) {
      await pumpRow(tester, event, timeline: timeline);
      await serverAnswers(tester);
    }

    expect(text('...'), findsOneWidget);
    expect(asked, hasLength(1));
  });

  testWidgets('a rebuild does not blink the placeholder of a quote not found', (
    tester,
  ) async {
    useRoom(server: notFound);
    final event = reply();
    final timeline = timelineOf([event]);
    final redraw = ValueNotifier(0);
    addTearDown(redraw.dispose);
    await pumpRow(
      tester,
      event,
      timeline: timeline,
      wrap: (row) => ValueListenableBuilder(
        valueListenable: redraw,
        builder: (context, _, _) => MessageContentWithTimestampBuilder(
          event: event,
          timeline: timeline,
          isHoverNotifier:
              (row as MessageContentWithTimestampBuilder).isHoverNotifier,
          listHorizontalActionMenu: const [],
          maxWidth: 400,
          listActions: const [],
          selectMode: false,
          scrollToEventId: row.scrollToEventId,
        ),
      ),
    );
    await serverAnswers(tester);
    expect(text('...'), findsOneWidget);

    redraw.value++;
    await tester.pump();

    expect(text('...'), findsOneWidget);
  });

  testWidgets('a quote not found shows once its message reaches the timeline', (
    tester,
  ) async {
    useRoom(server: notFound);
    final event = reply();
    final timeline = timelineOf([event]);
    await pumpRow(tester, event, timeline: timeline);
    await serverAnswers(tester);
    expect(text('...'), findsOneWidget);

    // Older history is loaded: the quoted message is now in the timeline.
    timeline.events.add(quoted());
    await pumpRow(tester, event, timeline: timeline);

    expect(text('...'), findsNothing);
    expectOutsideAndAbove(tester, text(_caption));
    expectOutsideAndAbove(tester, text(_quotedBody));
  });

  for (final (side, sender) in [('an incoming', _bob), ('an own', _me)]) {
    testWidgets('on $side reply, a tap on the strip of the quote showing '
        'beside the bubble jumps to the quoted message', (tester) async {
      final event = reply(
        sender: sender,
        content: {'msgtype': MessageTypes.Text, 'body': 'ok'},
      );
      final jumps = await pumpRow(
        tester,
        event,
        quotedEvent: quoted(body: '$_quotedBody, by the main entrance'),
      );
      final bubble = tester.getRect(bubbleOf('ok'));
      final quote = tester.getRect(quotedBubble());
      // The side where the quote is wider than the bubble below it.
      final x = sender == _me
          ? (quote.left + bubble.left) / 2
          : (bubble.right + quote.right) / 2;
      expect((x - bubble.center.dx).abs(), greaterThan(bubble.width / 2 + 4));
      expect(quote.bottom, moreOrLessEquals(bubble.top + _overlap));

      for (final y in [bubble.top + 1, quote.bottom - 2]) {
        jumps.clear();
        await tester.tapAt(Offset(x, y));
        await tester.pumpAndSettle();

        expect(jumps, [_quotedId], reason: 'tap at ($x, $y), quote $quote');
      }
    });

    testWidgets('on $side reply, a tap on the bubble where it covers the '
        'quote does not jump', (tester) async {
      final jumps = await pumpRow(
        tester,
        reply(sender: sender),
        quotedEvent: quoted(),
      );
      final bubble = tester.getRect(bubbleOf(_replyBody));
      final overlap = bubble.intersect(tester.getRect(quotedBubble()));
      expect(overlap.height, greaterThan(0));

      await tester.tapAt(overlap.center);
      await tester.pumpAndSettle();

      expect(jumps, isEmpty);
    });
  }

  testWidgets('an emoji-only reply keeps its bubble, overlapping the quote by '
      '12', (tester) async {
    const emoji = '\u{1F600}';
    await pumpRow(
      tester,
      reply(content: {'msgtype': MessageTypes.Text, 'body': emoji}),
      quotedEvent: quoted(),
    );

    expectOutsideAndAbove(tester, text(_caption), body: emoji);
    expect(
      tester.getRect(quotedBubble()).bottom -
          tester.getRect(bubbleOf(emoji)).top,
      moreOrLessEquals(_overlap, epsilon: 0.5),
    );
  });

  for (final threads in [true, false]) {
    testWidgets('with threads ${threads ? 'on' : 'off'}, a thread fallback '
        '${threads ? 'shows no quote' : 'keeps its quote'}', (tester) async {
      final previous = AppConfig.threadsEnabled;
      AppConfig.threadsEnabled = threads;
      addTearDown(() => AppConfig.threadsEnabled = previous);

      await pumpRow(
        tester,
        reply(thread: r'$root:example.org', fallingBack: true),
        quotedEvent: quoted(),
      );

      expect(find.byType(MessageBubble), findsOneWidget);
      expect(text(_caption), threads ? findsNothing : findsOneWidget);
      expect(text(_quotedBody), threads ? findsNothing : findsOneWidget);
    });
  }

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
