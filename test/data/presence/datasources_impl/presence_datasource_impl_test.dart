import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:twake_chat/data/presence/datasources_impl/presence_datasource_impl.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient(this.current);

  CachedPresence current;
  final fetched = <String>[];
  Completer<void>? readGate;

  @override
  final onPresenceChanged = CachedStreamController<CachedPresence>();

  @override
  Future<CachedPresence> fetchCurrentPresence(
    String userId, {
    bool fetchOnlyFromCached = false,
  }) async {
    fetched.add(userId);
    await readGate?.future;
    return current;
  }
}

const _alice = '@alice:server';

CachedPresence _presence(
  PresenceType type, {
  String userId = _alice,
  int? lastActiveAgo,
  String? statusMsg,
  bool? currentlyActive,
}) => CachedPresence(type, lastActiveAgo, statusMsg, currentlyActive, userId);

void main() {
  late _FakeClient client;
  late List<PersonPresence?> values;

  setUp(() {
    client = _FakeClient(_presence(PresenceType.offline));
    values = [];
  });

  Future<void> watch() async {
    final subscription = PresenceDatasourceImpl(
      client,
    ).watchPresence(_alice).listen(values.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
  }

  test('emits the known presence first', () async {
    client.current = _presence(PresenceType.online, statusMsg: 'In a meeting');

    await watch();

    expect(client.fetched, [_alice]);
    expect(values, [
      const PersonPresence(
        status: PresenceStatus.online,
        statusMessage: 'In a meeting',
      ),
    ]);
  });

  test('then emits each change of that person only', () async {
    await watch();

    client.onPresenceChanged
      ..add(_presence(PresenceType.unavailable))
      ..add(_presence(PresenceType.online, userId: '@bob:server'));
    await pumpEventQueue();

    expect(values.map((presence) => presence?.status), [
      PresenceStatus.offline,
      PresenceStatus.away,
    ]);
  });

  test('keeps a change that lands while the presence is read', () async {
    client.readGate = Completer<void>();
    final subscription = PresenceDatasourceImpl(
      client,
    ).watchPresence(_alice).listen(values.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    client.onPresenceChanged.add(_presence(PresenceType.online));
    client.readGate!.complete();
    await pumpEventQueue();

    expect(values.map((presence) => presence?.status), [PresenceStatus.online]);
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
