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

/// A text sent, as the room received it.
typedef _Sent = ({String text, String? rootId, String? lastEventId});

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

  @override
  Future<Event?> getEventById(String eventID) {
    if (eventID == _rootId) rootAsked = true;
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
class _NoUploads extends Fake implements UploadManager {}

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
Event _event(
  Room room,
  String eventId,
  int minute, {
  bool inThread = true,
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
        'is_falling_back': true,
        'm.in_reply_to': {'event_id': _rootId},
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

    expect(room.sent, [(text: 'hello', rootId: _rootId, lastEventId: _r1)]);
    await leaveTheApp(tester);
  });

  testWidgets('the first reply of a thread follows its root', (tester) async {
    room.rootLoad.complete(_event(room, _rootId, 0, inThread: false));
    await openThread(tester);
    await tester.pump(const Duration(seconds: 1));

    await sendReply(tester, 'first');

    expect(room.sent, [(text: 'first', rootId: _rootId, lastEventId: _rootId)]);
    await leaveTheApp(tester);
  });

  testWidgets('closing the thread while its root loads asks no page of '
      'replies, keeps no listener and shows no message', (tester) async {
    await openThread(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(room.rootAsked, isTrue, reason: 'the root is loading');

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
