import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/models/timeline_chunk.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.dart';
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.provider.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';
import 'package:twake_chat/domain/thread/entities/thread_replies_page.dart';
import 'package:twake_chat/domain/thread/repositories/thread_repository.dart';
import 'package:twake_chat/domain/thread/usecases/get_thread_replies_use_case.dart';
import 'package:twake_chat/domain/thread/usecases/get_thread_replies_use_case.provider.dart';
import 'package:twake_chat/domain/usecase/room/ban_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:twake_chat/domain/usecase/room/delete_event_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_events_controller.dart';
import 'package:twake_chat/pages/chat/events/audio_message/audio_player_widget.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';
import 'package:twake_chat/pages/chat/events/message/swipeable_message.dart';
import 'package:twake_chat/widgets/swipeable.dart';
import 'package:twake_chat/pages/chat/events/reply_content.dart';
import 'package:twake_chat/pages/chat/reply_display.dart';
import 'package:twake_chat/utils/background_push.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/network_connection_service.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../../fake_client.dart';

const _roomId = '!room:example.org';
const _rootId = r'$root:example.org';
const _r1 = r'$r1:example.org';
const _me = '@alice:example.org';

/// A stream that counts who listens to it right now.
class _Watched<T> extends CachedStreamController<T> {
  int listeners = 0;

  @override
  Stream<T> get stream {
    final source = super.stream;
    StreamSubscription<T>? subscription;
    late final StreamController<T> watched;
    watched = StreamController<T>(
      onListen: () {
        listeners++;
        subscription = source.listen(watched.add, onError: watched.addError);
      },
      onCancel: () {
        listeners--;
        return subscription?.cancel();
      },
    );
    return watched.stream;
  }
}

class _Client extends Client {
  _Client()
    : super(
        'chat-thread-mode-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => _me;

  final _Watched<Event> _onTimelineEvent = _Watched();

  @override
  _Watched<Event> get onTimelineEvent => _onTimelineEvent;
}

/// A text sent, as the room received it; [quotedId]: the message it quotes.
typedef _Sent = ({
  String text,
  String? rootId,
  String? lastEventId,
  String? quotedId,
});

/// The room of the thread: its live timeline is [liveEvents], the root comes
/// from [rootLoad], and the texts sent land in [sent].
class _Room extends Room {
  _Room(Client client)
    : super(id: _roomId, client: client, membership: Membership.join);

  List<Event> Function(Room room) liveEvents = (_) => const [];

  /// Made on first use, in the zone of the test: one made in `setUp` would
  /// resume the screen outside the fake time of `testWidgets`.
  Completer<Event?> get rootLoad => _rootLoad ??= Completer();
  Completer<Event?>? _rootLoad;

  bool rootAsked = false;

  final List<_Sent> sent = [];

  final _Watched<String> _onSessionKeyReceived = _Watched();

  @override
  _Watched<String> get onSessionKeyReceived => _onSessionKeyReceived;

  /// The replies the server knows, for a quote that looks its message up.
  final Map<String, Event> known = {};

  @override
  Future<Event?> getEventById(String eventID) {
    if (eventID == _rootId) rootAsked = true;
    final reply = known[eventID];
    if (reply != null) return Future.value(reply);
    return rootLoad.future;
  }

  @override
  Future<Timeline> getTimeline({
    void Function(int index)? onChange,
    void Function(int index)? onRemove,
    void Function(int insertID)? onInsert,
    void Function()? onNewEvent,
    void Function()? onUpdate,
    String? eventContextId,
    int? limit = Room.defaultHistoryCount,
  }) async => Timeline(
    room: this,
    chunk: TimelineChunk(events: liveEvents(this)),
    onUpdate: onUpdate,
  );

  @override
  Future<void> setTyping(bool isTyping, {int? timeout}) async {}

  @override
  Future<String?> sendTextEvent(
    String message, {
    String? txid,
    Event? inReplyTo,
    String? editEventId,
    bool parseMarkdown = true,
    bool parseCommands = true,
    String msgtype = MessageTypes.Text,
    String? threadRootEventId,
    String? threadLastEventId,
    StringBuffer? commandStdout,
    bool addMentions = true,
    bool displayPendingEvent = true,
  }) async {
    sent.add((
      text: message,
      rootId: threadRootEventId,
      lastEventId: threadLastEventId,
      quotedId: inReplyTo?.eventId,
    ));
    return r'$sent:example.org';
  }
}

/// Answers the first page of the thread with [page], and counts the pages
/// asked.
class _ThreadRepository implements ThreadRepository<Event> {
  Future<List<Event>> Function() page = () async => const [];

  int requests = 0;

  @override
  Future<ThreadRepliesPage<Event>> getReplies(
    String roomId,
    ThreadRepliesRequest request,
  ) async {
    requests++;
    return ThreadRepliesPage(replies: await page(), nextBatch: null);
  }
}

class _NoRecentReactions implements ReactionsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<String>> getRecentReactions() async => const [];
}

/// Text replies only: nothing is uploaded.
class _NoUploads extends Fake implements UploadManager {
  @override
  Future<void> failInterruptedUploads(Iterable<Event> events) async {}
}

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String? get supportChatRoomId => null;

  @override
  File? get wallpaper => null;

  @override
  BackgroundPush? get backgroundPush => null;

  @override
  final ValueNotifier<Event?> voiceMessageEvent = ValueNotifier(null);

  @override
  final ValueNotifier<AudioPlayerStatus> currentAudioStatus = ValueNotifier(
    AudioPlayerStatus.notDownloaded,
  );

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

/// A text of the thread (or its root, [inThread] false), sent at 10:[minute].
/// [quotes]: the message of the thread it answers with a quote.
Event _event(
  Room room,
  String eventId,
  int minute, {
  bool inThread = true,
  String? quotes,
  EventStatus status = EventStatus.synced,
}) => Event(
  type: EventTypes.Message,
  content: {
    'msgtype': MessageTypes.Text,
    'body': 'text of $eventId',
    if (inThread)
      'm.relates_to': {
        'rel_type': RelationshipTypes.thread,
        'event_id': _rootId,
        'is_falling_back': quotes == null,
        'm.in_reply_to': {'event_id': quotes ?? _rootId},
      },
  },
  eventId: eventId,
  senderId: '@bob:example.org',
  originServerTs: DateTime.utc(2026, 11, 16, 10, minute),
  status: status,
  room: room,
);

/// The thread mode of the chat screen (review of PR #3607, nqhhdev): a reply
/// sent from the thread screen goes to the thread, after its last synced
/// reply; a thread screen closed while it loads leaves nothing behind.
void main() {
  late _Client client;
  late _Room room;
  late _ThreadRepository threads;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final threadsEnabled = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
    addTearDown(() => AppConfig.threadsEnabled = threadsEnabled);
    client = _Client();
    room = _Room(client);
    client.rooms.add(room);
    threads = _ThreadRepository();
    getIt
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton(NetworkConnectionService(Connectivity()))
      ..registerSingleton(ChatGetPinnedEventsInteractor())
      ..registerFactory(PinnedEventsController.new)
      ..registerSingleton(UnblockUserInteractor())
      ..registerSingleton(DeleteEventInteractor())
      ..registerSingleton(BanUserInteractor())
      ..registerSingleton(const SearchEngine())
      ..registerSingleton<UploadManager>(_NoUploads());
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// The room screen, with the thread of [_rootId] opened over it.
  Future<void> openThread(WidgetTester tester) async {
    router = GoRouter(
      initialLocation: '/rooms/$_roomId/threads/$_rootId',
      routes: [
        GoRoute(
          path: '/rooms/:roomId',
          builder: (context, state) => const Text('the room'),
          routes: [
            GoRoute(
              path: 'threads/:rootId',
              builder: (context, state) =>
                  const Chat(roomId: _roomId, threadRootId: _rootId),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getThreadRepliesUseCaseProvider(
            client,
          ).overrideWithValue(GetThreadRepliesUseCase<Event>(threads)),
          getRecentReactionsUseCaseProvider.overrideWithValue(
            GetRecentReactionsUseCase(_NoRecentReactions()),
          ),
        ],
        child: provider.Provider<MatrixState>.value(
          value: _FakeMatrixState(client),
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            routerConfig: router,
            builder: (context, child) => Theme(
              data: TwakeThemes.buildTheme(context, Brightness.light),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The user goes back to the room: the thread screen closes.
  Future<void> closeThread(WidgetTester tester) async {
    router.go('/rooms/$_roomId');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Chat), findsNothing, reason: 'the thread is closed');
  }

  /// Lets the timers of the screen run out once the test is over.
  Future<void> leaveTheApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // The typing timer of the composer lasts 30 s.
    await tester.pump(const Duration(seconds: 31));
  }

  Future<void> sendReply(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('a reply sent from the thread goes to the thread, after its '
      'last synced reply', (tester) async {
    room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
    threads.page = () async => [_event(room, _r1, 1)];
    // A reply still sending is newer, but the next one does not follow it.
    room.liveEvents = (room) => [
      _event(room, r'$sending', 2, status: EventStatus.sending),
    ];
    await openThread(tester);
    await tester.pump(const Duration(seconds: 1));

    await sendReply(tester, 'hello');

    expect(room.sent, [
      (text: 'hello', rootId: _rootId, lastEventId: _r1, quotedId: null),
    ]);
    await leaveTheApp(tester);
  });

  testWidgets('the first reply of a thread follows its root', (tester) async {
    room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
    await openThread(tester);
    await tester.pump(const Duration(seconds: 1));

    await sendReply(tester, 'first');

    expect(room.sent, [
      (text: 'first', rootId: _rootId, lastEventId: _rootId, quotedId: null),
    ]);
    await leaveTheApp(tester);
  });

  /// Clément, 2026-11-26: on the thread screen a message offers "Reply"
  /// (quote reply) as in a room. Matrix spec v1.19, "Replies within threads":
  /// "This flag defaults to `false` when not provided, which also allows a
  /// threaded message to contain a reply itself."
  group('quote reply in a thread', () {
    const r2 = r'$r2:example.org';

    /// The banner above the composer that shows the message being answered.
    Finder inReplyBanner(String eventId) => find.descendant(
      of: find.byType(ReplyDisplay),
      matching: find.text('text of $eventId'),
    );

    /// The bubble of a message, not a quote of it.
    Finder bubbleOf(String eventId) => find.byWidgetPredicate(
      (widget) => widget is Message && widget.event.eventId == eventId,
    );

    /// A thread of two replies, open.
    Future<void> openThreadOfTwoReplies(WidgetTester tester) async {
      room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
      threads.page = () async => [_event(room, _r1, 1), _event(room, r2, 2)];
      await openThread(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(bubbleOf(_r1), findsOneWidget, reason: 'the thread is loaded');
      expect(inReplyBanner(_r1), findsNothing);
    }

    /// A finger dragged to the left over a message.
    const swipe = Offset(-300, 0);

    /// Swipes [eventId] and waits until the reply banner has finished
    /// opening, as the user sees it.
    Future<void> swipeToReply(WidgetTester tester, String eventId) async {
      await tester.drag(bubbleOf(eventId), swipe);
      // The swipe ends and starts the reply.
      await tester.pump(const Duration(seconds: 1));
      // The banner starts to open, then is fully open.
      await tester.pump();
      await tester.pump(TwakeThemes.animationDuration);
    }

    testWidgets('reference: the gesture of these tests is the swipe a '
        'message answers to', (tester) async {
      final swiped = <SwipeDirection>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableMessage(
              event: _event(room, _r1, 1),
              onSwipe: swiped.add,
              child: const SizedBox(height: 60, child: Text('a message')),
            ),
          ),
        ),
      );

      await tester.drag(find.text('a message'), swipe);
      await tester.pump(const Duration(seconds: 1));

      expect(swiped, [SwipeDirection.endToStart]);
    });

    testWidgets('a swipe on a message starts a reply to it: the reply banner '
        'shows that message above the composer', (tester) async {
      await openThreadOfTwoReplies(tester);

      await swipeToReply(tester, _r1);

      expect(inReplyBanner(_r1), findsOneWidget);
      expect(
        tester.getTopLeft(inReplyBanner(_r1)).dy,
        lessThan(tester.getTopLeft(find.byType(TextField)).dy),
        reason: 'the banner sits above the composer',
      );
      await leaveTheApp(tester);
    });

    testWidgets('the "Reply" action on a message shows it in the reply '
        'banner', (tester) async {
      await openThreadOfTwoReplies(tester);
      final controller = tester.state<ChatController>(find.byType(Chat));

      controller.replyAction(
        replyTo: tester.widget<Message>(bubbleOf(_r1)).event,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(inReplyBanner(_r1), findsOneWidget);
      await leaveTheApp(tester);
    });

    testWidgets('a message sent while replying stays in the thread and '
        'quotes the chosen message, then the banner closes', (tester) async {
      await openThreadOfTwoReplies(tester);
      await swipeToReply(tester, _r1);

      await sendReply(tester, 'my answer');

      expect(room.sent, hasLength(1));
      expect(room.sent.single.text, 'my answer');
      expect(room.sent.single.rootId, _rootId);
      expect(room.sent.single.quotedId, _r1);
      expect(inReplyBanner(_r1), findsNothing);
      await leaveTheApp(tester);
    });

    /// Bug seen on the iOS simulator, 2026-11-26: on the thread screen of a
    /// phone, the reply banner reported "A RenderFlex overflowed by 16 px on
    /// the bottom" at each frame of its opening and of its closing after a
    /// quoted reply is sent. The user must see it open and close cleanly.
    testWidgets('on a phone, the reply banner opens and closes without '
        'overflowing at any frame', (tester) async {
      // An iPhone in portrait: the thread screen is narrow.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await openThreadOfTwoReplies(tester);

      /// Pumps the frames of one run of the banner animation, and checks
      /// that none of them reports a layout error.
      Future<void> everyFrameOfTheAnimation(String step) async {
        const frame = Duration(milliseconds: 16);
        final frames =
            TwakeThemes.animationDuration.inMilliseconds ~/
                frame.inMilliseconds +
            2;
        for (var i = 0; i < frames; i++) {
          await tester.pump(frame);
          expect(tester.takeException(), isNull, reason: '$step, frame $i');
        }
      }

      await tester.drag(bubbleOf(_r1), swipe);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'the swipe');
      await everyFrameOfTheAnimation('the banner opens');
      expect(inReplyBanner(_r1), findsOneWidget, reason: 'the banner is open');

      await tester.enterText(find.byType(TextField), 'my answer');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'the send');
      await everyFrameOfTheAnimation('the banner closes');

      expect(room.sent.single.quotedId, _r1);
      expect(inReplyBanner(_r1), findsNothing, reason: 'the banner is closed');
      await leaveTheApp(tester);
    });

    testWidgets('a reply cancelled from its banner quotes nothing: the '
        'message follows the last reply of the thread', (tester) async {
      await openThreadOfTwoReplies(tester);
      await swipeToReply(tester, _r1);
      expect(inReplyBanner(_r1), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(ReplyDisplay),
          matching: find.byTooltip('Close'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(inReplyBanner(_r1), findsNothing);
      await sendReply(tester, 'never mind');

      expect(room.sent, [
        (text: 'never mind', rootId: _rootId, lastEventId: r2, quotedId: null),
      ]);
      await leaveTheApp(tester);
    });

    group('a reply that quotes a message of the thread', () {
      const quoting = r'$quoting:example.org';

      /// The quote shown in the bubble of [quoting].
      Finder quoteOf(String eventId) => find.descendant(
        of: bubbleOf(quoting),
        matching: find.descendant(
          of: find.byType(ReplyContent),
          matching: find.text('text of $eventId'),
        ),
      );

      /// A thread long enough to scroll: [_r1] is its oldest reply, and its
      /// newest one, [quoting], quotes it.
      Future<void> openLongThread(WidgetTester tester) async {
        final replies = [
          _event(room, _r1, 1),
          for (var minute = 2; minute < 40; minute++)
            _event(room, '\$filler$minute:example.org', minute),
          _event(room, quoting, 40, quotes: _r1),
        ];
        room.known[_r1] = replies.first;
        room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
        threads.page = () async => replies;
        await openThread(tester);
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }

      testWidgets('shows its quote above its text', (tester) async {
        await openLongThread(tester);

        expect(quoteOf(_r1), findsOneWidget);
        expect(
          tester.getTopLeft(quoteOf(_r1)).dy,
          lessThan(
            tester
                .getTopLeft(
                  find.descendant(
                    of: bubbleOf(quoting),
                    matching: find.text('text of $quoting'),
                  ),
                )
                .dy,
          ),
        );
        await leaveTheApp(tester);
      });

      testWidgets('a tap on its quote scrolls the thread to the quoted '
          'message', (tester) async {
        await openLongThread(tester);
        expect(
          bubbleOf(_r1),
          findsNothing,
          reason: 'the quoted message is far above, out of the screen',
        );

        await tester.tap(quoteOf(_r1));
        // The scroll goes page by page, one frame each.
        for (var frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(bubbleOf(_r1).hitTestable(), findsOneWidget);
        await leaveTheApp(tester);
      });
    });
  });

  testWidgets('closing the thread while its root loads asks no page of '
      'replies, keeps no listener and shows no message', (tester) async {
    await openThread(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(room.rootAsked, isTrue, reason: 'the root is loading');
    expect(
      client.onTimelineEvent.listeners,
      greaterThan(0),
      reason: 'the screen listens to the room',
    );

    await closeThread(tester);
    room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(threads.requests, 0);
    expect(client.onTimelineEvent.listeners, 0);
    expect(room.onSessionKeyReceived.listeners, 0);
    expect(find.byType(SnackBar), findsNothing);
    await leaveTheApp(tester);
  });

  group('a first page of replies that fails', () {
    late Completer<List<Event>> firstPage;

    setUp(() {
      threads.page = () => (firstPage = Completer()).future;
    });

    testWidgets('says so on the thread screen', (tester) async {
      room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
      await openThread(tester);
      await tester.pump(const Duration(seconds: 1));

      firstPage.completeError(Exception('offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SnackBar), findsOneWidget);
      await leaveTheApp(tester);
    });

    testWidgets('after the thread was closed shows no message', (tester) async {
      room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
      await openThread(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(threads.requests, 1, reason: 'the first page is on its way');

      await closeThread(tester);
      firstPage.completeError(Exception('offline'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
      await leaveTheApp(tester);
    });
  });
}
