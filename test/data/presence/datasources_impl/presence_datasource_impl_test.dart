import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/data/presence/datasources_impl/presence_datasource_impl.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';

/// Counts who listens to the presence changes.
class _CountedChanges extends CachedStreamController<CachedPresence> {
  int listeners = 0;
  late final _controller = StreamController<CachedPresence>.broadcast(
    onListen: () => listeners++,
    onCancel: () => listeners--,
  );

  @override
  Stream<CachedPresence> get stream => _controller.stream;

  @override
  void add(CachedPresence value) => _controller.add(value);
}

class _FakeClient extends Fake implements Client {
  CachedPresence? cached;
  GetPresenceResponse? server;
  final serverReads = <String>[];
  Completer<void>? serverGate;
  Error? serverError;

  @override
  final _CountedChanges onPresenceChanged = _CountedChanges();

  @override
  Future<CachedPresence> fetchCurrentPresence(
    String userId, {
    bool fetchOnlyFromCached = false,
  }) async {
    expect(fetchOnlyFromCached, isTrue);
    return cached ?? CachedPresence.neverSeen(userId);
  }

  @override
  Future<GetPresenceResponse> getPresence(String userId) async {
    serverReads.add(userId);
    await serverGate?.future;
    final serverError = this.serverError;
    if (serverError != null) throw serverError;
    final server = this.server;
    if (server == null) throw Exception('presence unavailable');
    return server;
  }
}

const _alice = '@alice:server';

CachedPresence _presence(
  PresenceType type, {
  int? lastActiveAgo,
  String? statusMsg,
  bool? currentlyActive,
}) => CachedPresence(type, lastActiveAgo, statusMsg, currentlyActive, _alice);

void main() {
  late _FakeClient client;
  late List<PersonPresence?> values;

  setUp(() {
    client = _FakeClient();
    values = [];
  });

  Future<StreamSubscription<PersonPresence?>> watch() async {
    final subscription = PresenceDatasourceImpl(
      client,
    ).watchPresence(_alice).listen(values.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    return subscription;
  }

  test('asks the server on every listen, after the cached value', () async {
    client.cached = _presence(PresenceType.unavailable);
    client.server = GetPresenceResponse(
      presence: PresenceType.online,
      statusMsg: 'In a meeting',
    );

    await watch();

    expect(client.serverReads, [_alice]);
    expect(values, [
      const PersonPresence(status: PresenceStatus.away),
      const PersonPresence(
        status: PresenceStatus.online,
        statusMessage: 'In a meeting',
      ),
    ]);
  });

  test('waits for the server when nothing is cached', () async {
    client.server = GetPresenceResponse(presence: PresenceType.online);

    await watch();

    expect(values, [const PersonPresence(status: PresenceStatus.online)]);
  });

  test('keeps the cached value when the server fails', () async {
    client.cached = _presence(PresenceType.unavailable);

    await watch();

    expect(values, [const PersonPresence(status: PresenceStatus.away)]);
  });

  test('says offline when the server fails and nothing is cached', () async {
    await watch();

    expect(values, [const PersonPresence(status: PresenceStatus.offline)]);
  });

  test('lets a programming error through', () async {
    client.serverError = StateError('bug');
    final errors = <Object>[];
    final subscription = PresenceDatasourceImpl(
      client,
    ).watchPresence(_alice).listen(values.add, onError: errors.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    expect(errors, [isA<StateError>()]);
    expect(values, isEmpty);
  });

  test('then emits each change of that person only', () async {
    client.server = GetPresenceResponse(presence: PresenceType.offline);
    await watch();

    client.onPresenceChanged
      ..add(_presence(PresenceType.unavailable))
      ..add(
        CachedPresence(PresenceType.online, null, null, null, '@bob:server'),
      );
    await pumpEventQueue();

    expect(values.map((presence) => presence?.status), [
      PresenceStatus.offline,
      PresenceStatus.away,
    ]);
  });

  test('keeps a change that lands while the server is read', () async {
    client.serverGate = Completer<void>();
    client.server = GetPresenceResponse(presence: PresenceType.offline);
    await watch();

    client.onPresenceChanged.add(_presence(PresenceType.online));
    client.serverGate!.complete();
    await pumpEventQueue();

    expect(values.map((presence) => presence?.status), [PresenceStatus.online]);
  });

  test('stops listening to the changes when cancelled', () async {
    final subscription = await watch();
    expect(client.onPresenceChanged.listeners, 1);

    await subscription.cancel();

    expect(client.onPresenceChanged.listeners, 0);
  });

  test('emits null without an active client', () async {
    final values = await const PresenceDatasourceImpl(
      null,
    ).watchPresence(_alice).toList();

    expect(values, [null]);
  });

  group('toPersonPresence', () {
    test('is online when the server says currently active', () {
      final presence = PresenceDatasourceImpl.toPersonPresence(
        _presence(PresenceType.unavailable, currentlyActive: true),
      );

      expect(presence.status, PresenceStatus.online);
    });

    test('is away when unavailable', () {
      final presence = PresenceDatasourceImpl.toPersonPresence(
        _presence(PresenceType.unavailable),
      );

      expect(presence.status, PresenceStatus.away);
    });

    test('keeps the last activity', () {
      final presence = PresenceDatasourceImpl.toPersonPresence(
        _presence(PresenceType.offline, lastActiveAgo: 60000),
      );

      expect(DateTime.now().difference(presence.lastActiveAt!).inMinutes, 1);
    });

    test('drops a blank status', () {
      final presence = PresenceDatasourceImpl.toPersonPresence(
        _presence(PresenceType.online, statusMsg: '  '),
      );

      expect(presence.statusMessage, isNull);
    });
  });
}
