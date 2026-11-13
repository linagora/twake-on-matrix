// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_ref.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/twake_client.dart';

import '../../../fake_client.dart';

const threadOwner = '@me:example.org';
const teamRoomId = '!team:example.org';
const lunchThread = ThreadRef(teamRoomId, r'$lunch');
const releaseThread = ThreadRef(teamRoomId, r'$release');

/// The request that asks the server whether the user took part in the lunch
/// thread (its root, with the aggregate of the thread).
const lunchRootLookup = ServerRoute.get(
  r'rooms/!team:example.org/event/$lunch',
);

/// The account writes its thread choices.
const threadPrefsWrite = ServerRoute.put(
  'user/$threadOwner/account_data/app.twake.chat.thread_prefs',
);

/// The account silences (or not) a thread, whatever the thread: the first
/// step of a save.
const threadRuleWrite = ServerRoute.put('pushrules/global/override/');

/// The account reads its thread choices from the server.
const threadPrefsRead = ServerRoute.get(
  'user/$threadOwner/account_data/app.twake.chat.thread_prefs',
);

/// One request the homeserver received: its method, its path from
/// `_matrix/client/v3/` on (decoded), and its JSON body.
class ServerCall {
  ServerCall(http.BaseRequest request)
    : method = request.method,
      path = _pathOf(request.url),
      body = request is http.Request && request.body.isNotEmpty
          ? jsonDecode(request.body)
          : null;

  final String method;
  final String path;
  final Object? body;

  static String _pathOf(Uri url) {
    final segments = url.pathSegments;
    return segments.skip(segments.indexOf('v3') + 1).join('/');
  }

  bool hits(ServerRoute route) =>
      method == route.method && path.startsWith(route.path);

  @override
  String toString() => '$method $path $body';
}

/// A method and the start of a path.
class ServerRoute {
  const ServerRoute.get(this.path) : method = 'GET';

  const ServerRoute.post(this.path) : method = 'POST';

  const ServerRoute.put(this.path) : method = 'PUT';

  const ServerRoute.delete(this.path) : method = 'DELETE';

  final String method;
  final String path;

  /// Same method and path, same route: a later [RecordingHomeserver.answer]
  /// (or `fail`, `hold`) for it replaces the earlier one.
  @override
  bool operator ==(Object other) =>
      other is ServerRoute && other.method == method && other.path == path;

  @override
  int get hashCode => Object.hash(method, path);
}

/// What the homeserver answers when a route fails.
enum ServerError {
  notFound(404, 'M_NOT_FOUND'),
  down(500, 'M_UNKNOWN');

  const ServerError(this.status, this.errcode);

  final int status;
  final String errcode;

  Map<String, Object?> get body => {'errcode': errcode, 'error': 'test'};
}

/// The path of the thread choices of [user] on the server.
String _threadPrefsPath(String user) =>
    'user/$user/account_data/app.twake.chat.thread_prefs';

/// The path of the push rule that silences [thread] on the server.
String _threadRulePath(ThreadRef thread) =>
    'pushrules/global/override/app.twake.chat.thread.${thread.rootEventId}';

/// A homeserver that records every request and answers it (an event id, for
/// the routes that send one), unless a route was told to fail. The sync
/// filter is accepted; `/sync` answers what [answer] gave it. The account
/// data and the push rules are kept as a homeserver keeps them: a PUT
/// stores its body once answered, a GET gives it back, a DELETE removes it;
/// a GET or a DELETE of nothing is « not found ».
class RecordingHomeserver extends http.BaseClient {
  RecordingHomeserver() {
    answer(const ServerRoute.post('user/'), {'filter_id': 'f1'});
  }

  final List<ServerCall> calls = [];
  final Map<ServerRoute, ServerError> _failures = {};
  final Map<ServerRoute, Map<String, Object?>> _answers = {};
  final Map<ServerRoute, Completer<void>> _holds = {};
  final Set<ServerRoute> _lost = {};
  final Map<String, Object?> _kept = {};

  /// The web (or another device) wrote these thread choices for [user];
  /// no sync brought them yet.
  void storeThreadPrefs(
    List<Map<String, Object?>> entries, {
    String user = threadOwner,
  }) => _kept[_threadPrefsPath(user)] = {'threads': entries};

  /// The thread choices the account of [user] holds on the server, null
  /// when it holds none.
  List<Object?>? threadPrefsOf([String user = threadOwner]) =>
      (_kept[_threadPrefsPath(user)] as Map?)?['threads'] as List?;

  /// The push rule that silences [thread] is on the server.
  bool hasPushRule(ThreadRef thread) =>
      _kept.containsKey(_threadRulePath(thread));

  void fail(ServerRoute route, [ServerError error = ServerError.down]) =>
      _failures[route] = error;

  /// [route] fails no more: it answers as before [fail].
  void recover(ServerRoute route) => _failures.remove(route);

  /// From now on, [route] answers [body].
  void answer(ServerRoute route, Map<String, Object?> body) =>
      _answers[route] = body;

  /// A slow network: the requests to [route] get no answer until
  /// [release]. They are recorded when sent.
  void hold(ServerRoute route) => _holds[route] = Completer<void>();

  /// The held requests to [route] are answered.
  void release(ServerRoute route) => _holds.remove(route)?.complete();

  /// A flaky network: the server handles the requests to [route] (a PUT is
  /// stored), but the answer never reaches the app, which times out.
  void loseResponses(ServerRoute route) => _lost.add(route);

  Iterable<ServerCall> callsTo(ServerRoute route) =>
      calls.where((call) => call.hits(route));

  static V? _matching<V>(ServerCall call, Map<ServerRoute, V> routes) => routes
      .entries
      .where((route) => call.hits(route.key))
      .map((route) => route.value)
      .firstOrNull;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final call = ServerCall(request);
    calls.add(call);
    await _matching(call, _holds)?.future;
    final error = _matching(call, _failures);
    final (status, answer) = error != null
        ? (error.status, error.body)
        : _answerOf(call);
    if (_lost.any(call.hits)) {
      throw TimeoutException('The answer to $call was lost');
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(answer))),
      status,
      headers: {'content-type': 'application/json'},
    );
  }

  (int, Object?) _answerOf(ServerCall call) {
    final given = _matching(call, _answers);
    if (given != null) return (200, given);
    if (_isKept(call.path)) return _keep(call);
    return (200, {'event_id': '\$sent${calls.length}'});
  }

  static bool _isKept(String path) =>
      path.contains('/account_data/') || path.startsWith('pushrules/global/');

  (int, Object?) _keep(ServerCall call) {
    final found = _kept.containsKey(call.path);
    switch (call.method) {
      case 'PUT':
        _kept[call.path] = call.body;
      case 'GET' when found:
        return (200, _kept[call.path]);
      case 'DELETE' when found:
        _kept.remove(call.path);
      default:
        return (ServerError.notFound.status, ServerError.notFound.body);
    }
    return (200, <String, Object?>{});
  }
}

/// Takes what a sync brings and keeps none of it; holds no event, and gives
/// [accountData] as the account data stored on the device (null: the
/// device fails to read it), with the session of [threadOwner] synced up to
/// `s1` the last time the app ran. With [storedTimeline], it holds these
/// events of [teamRoomId] and keeps the timeline events of each sync, as
/// the database of the app does (thread replies with the others).
class _SyncDatabase extends MockDatabase {
  _SyncDatabase(
    this.accountData,
    this.teamRoomStates, [
    List<Map<String, Object?>>? storedTimeline,
  ]) : _timelines = storedTimeline == null
           ? null
           : {
               teamRoomId: [...storedTimeline],
             };

  final Map<String, BasicEvent>? accountData;

  /// The timeline events by room, oldest first; null: none kept.
  final Map<String, List<Map<String, Object?>>>? _timelines;

  Map<String, Object?>? _keptEvent(String eventId, Room room) {
    for (final json in _timelines?[room.id] ?? const []) {
      if (json['event_id'] == eventId) return json;
    }
    return null;
  }

  /// Newest first, as the database of the app gives them.
  @override
  Future<List<Event>> getEventList(
    Room room, {
    int start = 0,
    bool onlySending = false,
    int? limit,
  }) async {
    final timelines = _timelines;
    if (timelines == null) {
      throw UnimplementedError('This database keeps no event');
    }
    if (onlySending) return [];
    final newest = (timelines[room.id] ?? const []).reversed.skip(start);
    return [
      for (final json in limit == null ? newest : newest.take(limit))
        Event.fromJson(json, room),
    ];
  }

  /// The states of [teamRoomId] stored on the device; none: no room stored.
  final List<StrippedStateEvent> teamRoomStates;

  /// As the database of the app: a stored room opens partial, with its
  /// important states only; the others wait for `Room.postLoad`.
  @override
  Future<List<Room>> getRoomList(Client client) async {
    if (teamRoomStates.isEmpty) return [];
    final room = Room(
      id: teamRoomId,
      client: client,
      membership: Membership.join,
    );
    for (final state in teamRoomStates) {
      if (client.importantStateEvents.contains(state.type)) {
        room.setState(_storedEvent(state, room));
      }
    }
    return [room];
  }

  @override
  Future<List<Event>> getUnimportantRoomEventStatesForRoom(
    List<String> events,
    Room room,
  ) async => [
    for (final state in teamRoomStates)
      if (!events.contains(state.type)) _storedEvent(state, room),
  ];

  static Event _storedEvent(StrippedStateEvent state, Room room) => Event(
    content: state.content,
    type: state.type,
    eventId: '\$stored${state.type}${state.stateKey}',
    senderId: state.senderId,
    originServerTs: DateTime.utc(2026, 11, 9),
    stateKey: state.stateKey,
    room: room,
  );

  @override
  Future<Map<String, dynamic>?> getClient(String name) async => {
    'client_id': 1,
    'homeserver_url': 'https://example.org',
    'user_id': threadOwner,
    'token': 'token',
    'device_id': 'DEVICE',
    'prev_batch': 's1',
  };

  /// The session row the SDK writes back is dropped, as everything else
  /// (the arguments are those of `DatabaseApi`).
  @override
  Future<void> updateClient(
    String homeserverUrl,
    String token,
    DateTime? tokenExpiresAt,
    String? refreshToken,
    String userId,
    String? deviceId,
    String? deviceName,
    String? prevBatch,
    String? olmAccount,
    String? oidcClientId,
  ) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<Map<String, BasicEvent>> getAccountData() async => {
    ...accountData ?? (throw StateError('The device storage is unreadable')),
  };

  /// The ids of the events asked of the device, in order.
  final List<String> eventReads = [];

  @override
  Future<Event?> getEventById(String eventId, Room room) async {
    eventReads.add(eventId);
    final json = _keptEvent(eventId, room);
    return json == null ? null : Event.fromJson(json, room);
  }

  /// A member event of the sync (a display name) changes nothing stored.
  @override
  Future<void> markUserProfileAsOutdated(String userId) async {}

  @override
  Future<void> storeSyncFilterId(String syncFilterId) async {}

  /// A history page read (`Room.requestHistory`) moves the token; not kept.
  @override
  Future<void> setRoomPrevBatch(
    String? prevBatch,
    String roomId,
    Client client,
  ) async {}

  @override
  Future<void> storePrevBatch(String prevBatch) async {}

  @override
  Future<bool> deleteOldFiles(int savedAt) async => true;

  @override
  Future<void> storeEventUpdate(
    String roomId,
    StrippedStateEvent event,
    EventUpdateType type,
    Client client,
  ) async {
    final timelines = _timelines;
    if (timelines == null || type != EventUpdateType.timeline) return;
    if (event is! MatrixEvent) return;
    final timeline = timelines.putIfAbsent(roomId, () => [])
      ..removeWhere((json) => json['event_id'] == event.eventId);
    timeline.add(event.toJson());
  }

  @override
  Future<void> storeRoomUpdate(
    String roomId,
    SyncRoomUpdate roomUpdate,
    Event? lastEvent,
    Client client,
  ) async {}
}

/// The logged-in account of [threadOwner], talking to [server]. The account
/// data stored on the device is [storedAccountData], loaded by [start];
/// with [accountDataUnreadable], reading it fails. [storedTeamRoomStates]:
/// the device holds [teamRoomId] with these states. [storedTimeline]: the
/// device holds these events of [teamRoomId] (JSON of the spec, oldest
/// first) and keeps the timeline of each sync; null: it keeps no event.
class ThreadAccount extends TwakeClient {
  ThreadAccount(
    this.server, {
    Map<String, BasicEvent> storedAccountData = const {},
    bool accountDataUnreadable = false,
    List<StrippedStateEvent> storedTeamRoomStates = const [],
    List<Map<String, Object?>>? storedTimeline,
  }) : super(
         'thread-account-test',
         database: _SyncDatabase(
           accountDataUnreadable ? null : storedAccountData,
           storedTeamRoomStates,
           storedTimeline,
         ),
         httpClient: server,
       ) {
    homeserver = _homeserver;
    accessToken = 'token';
    // One sync per [receiveSync], none looping behind the test.
    backgroundSync = false;
  }

  static final _homeserver = Uri.parse('https://example.org');

  final RecordingHomeserver server;

  /// The ids of the events the app asked of the device, in order.
  List<String> get deviceEventReads => (database as _SyncDatabase).eventReads;

  bool _loggedOut = false;

  /// [threadOwner] until another account logs in ([logOutThenLogIn]); none
  /// once logged out ([clear]) until then.
  @override
  String? get userID => super.userID ?? (_loggedOut ? null : threadOwner);

  /// The user logs out: the session is cleared, no account is logged in.
  @override
  Future<void> clear({
    SessionClearReason reason = SessionClearReason.unspecified,
  }) async {
    await super.clear(reason: reason);
    _loggedOut = true;
    // `clear` turns the sync loop back on.
    backgroundSync = false;
  }

  /// The app opens the session stored on the device (synced up to `s1` the
  /// last time it ran): the account data stored with it is loaded. Its
  /// catch-up sync brings nothing new; nothing waits for it.
  Future<void> start() async {
    server.answer(const ServerRoute.get('sync'), {'next_batch': 's1'});
    await _open();
  }

  /// As [start], but the server has not answered the catch-up sync yet:
  /// what the other clients wrote meanwhile is only on the server. No
  /// [receiveSync] after it.
  Future<void> startBeforeCatchUp() async {
    server.hold(const ServerRoute.get('sync'));
    await _open();
  }

  Future<void> _open() async {
    await init(
      newToken: 'token',
      newHomeserver: _homeserver,
      newUserID: threadOwner,
      newDeviceID: 'DEVICE',
      waitForFirstSync: false,
    );
    await accountDataLoading;
  }

  /// The app opens the session as `ClientManager` does: nothing waits for
  /// the data stored on the device nor for the first sync, which the server
  /// answers empty.
  Future<void> openAsTheApp() => _openAsTheApp(this, server);

  /// The server answers the next `/sync` with [response] (the JSON of the
  /// spec), and the sync loop of the SDK handles it as in the app. Throws
  /// when the SDK could not handle it. Only in `test()`: `TwakeClient.sync`
  /// parses in an isolate, which the fake clock of `testWidgets` never
  /// waits for.
  Future<void> receiveSync(Map<String, Object?> response) async {
    // Never joins the catch-up sync of [start], answered before.
    await firstSyncReceived;
    server.answer(const ServerRoute.get('sync'), {
      'next_batch': 's2',
      ...response,
    });
    final errors = <Object?>[];
    final watching = onSyncStatus.stream.listen((update) {
      if (update.status == SyncStatus.error) errors.add(update.error);
    });
    await oneShotSync();
    await watching.cancel();
    if (errors.isNotEmpty) throw StateError('The sync failed: $errors');
  }

  /// A sync brings the thread choices another client wrote.
  Future<void> receiveThreadPrefs(List<Map<String, Object?>> entries) =>
      _receiveThreadPrefsContent({'threads': entries});

  Future<void> _receiveThreadPrefsContent(Object? content) => receiveSync({
    'account_data': {
      'events': [
        {'type': 'app.twake.chat.thread_prefs', 'content': content},
      ],
    },
  });

  /// The web writes these thread choices on the server, and the sync brings
  /// them.
  Future<void> webWrites(List<Map<String, Object?>> entries) async {
    server.storeThreadPrefs(entries);
    await receiveThreadPrefs(entries);
  }

  /// The sync echoes the list of thread choices this account wrote at its
  /// [index]-th write (from 0).
  Future<void> echoOfWrite(int index) => _receiveThreadPrefsContent(
    server.callsTo(threadPrefsWrite).elementAt(index).body,
  );

  /// The user logs out, then [userId] logs in on this same client object,
  /// as the app does on a device with one account.
  Future<void> logOutThenLogIn(String userId) async {
    await clear();
    await init(
      newToken: 'token-of-$userId',
      newHomeserver: _homeserver,
      newUserID: userId,
      newDeviceID: 'DEVICE2',
      waitForFirstSync: false,
    );
    _loggedOut = false;
    await accountDataLoading;
  }

  /// A sync brings state events of [teamRoomId], in its [section]: the
  /// account joined and the room open on screen (all its states loaded).
  Future<void> receiveRoomState(
    List<StrippedStateEvent> states, {
    RoomSection section = RoomSection.state,
  }) async {
    if (getRoomById(teamRoomId) == null) {
      await receiveSync(_roomSync(RoomSection.state, const []));
      getRoomById(teamRoomId)!.partial = false;
    }
    await receiveSync(_roomSync(section, states));
  }

  Map<String, Object?> _roomSync(
    RoomSection section,
    List<StrippedStateEvent> states,
  ) => {
    'rooms': {
      'join': {
        teamRoomId: {
          section.name: {
            'events': [
              for (final state in states)
                {
                  'type': state.type,
                  'content': state.content,
                  'state_key': state.stateKey,
                  'sender': threadOwner,
                  'event_id': '\$${state.type}${state.stateKey}',
                  'origin_server_ts': DateTime.utc(
                    2026,
                    11,
                    10,
                  ).millisecondsSinceEpoch,
                },
            ],
          },
        },
      },
    },
  };
}

/// The SDK's own client, without the threads of the app, opened as
/// [ThreadAccount.openAsTheApp] opens one on a device that fails to read
/// the stored account data: what the SDK does alone.
Future<void> openSdkClientOnUnreadableDevice() {
  final server = RecordingHomeserver();
  final client = Client(
    'sdk-client-test',
    database: _SyncDatabase(null, const []),
    httpClient: server,
  )..backgroundSync = false;
  return _openAsTheApp(client, server);
}

/// `ClientManager.initClient`: the session of [threadOwner] opens without
/// waiting for the stored data nor the first sync, which [server] answers
/// empty.
Future<void> _openAsTheApp(Client client, RecordingHomeserver server) {
  server.answer(const ServerRoute.get('sync'), {'next_batch': 's2'});
  return client.init(
    newToken: 'token',
    newHomeserver: Uri.parse('https://example.org'),
    newUserID: threadOwner,
    newDeviceID: 'DEVICE',
    waitForFirstSync: false,
    waitUntilLoadCompletedLoaded: false,
  );
}

/// Where a sync carries a state event: `state` (before the timeline, as
/// after a gap) or `timeline` (sent live, as another client does).
enum RoomSection { state, timeline }

/// The power levels of the room.
StrippedStateEvent powerLevels(Map<String, Object?> levels) =>
    StrippedStateEvent(
      type: EventTypes.RoomPowerLevels,
      content: levels,
      senderId: threadOwner,
      stateKey: '',
    );

StrippedStateEvent _resolvedState(ThreadRef thread, Object resolved) =>
    StrippedStateEvent(
      type: 'app.twake.chat.thread_resolved',
      content: {'resolved': resolved},
      senderId: threadOwner,
      stateKey: thread.rootEventId,
    );

StrippedStateEvent resolvedState(ThreadRef thread) =>
    _resolvedState(thread, true);

StrippedStateEvent reopenedState(ThreadRef thread) =>
    _resolvedState(thread, false);

/// The `pref` values of the web, spelled as on the wire.
enum WirePref { follow, unfollow, mute }

/// One entry of `app.twake.chat.thread_prefs`, as the web writes it.
Map<String, Object?> prefEntry(ThreadRef thread, WirePref pref) => {
  'roomId': thread.roomId,
  'threadId': thread.rootEventId,
  'pref': pref.name,
};
