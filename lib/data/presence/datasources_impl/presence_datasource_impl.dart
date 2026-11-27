import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/presence/datasources/presence_datasource.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';

class PresenceDatasourceImpl implements PresenceDatasource {
  const PresenceDatasourceImpl(this._client);

  final Client? _client;

  @override
  Stream<PersonPresence?> watchPresence(
    String userId, {
    required bool readFromServer,
  }) {
    final client = _client;
    if (client == null) return Stream.value(null);
    StreamSubscription<CachedPresence>? changes;
    late final StreamController<PersonPresence?> controller;
    controller = StreamController<PersonPresence?>(
      onListen: () {
        var hasChanged = false;
        void addRead(CachedPresence presence) {
          if (!hasChanged) controller.add(toPersonPresence(presence));
        }

        // Listen before reading: a change that lands during the reads wins
        changes = client.onPresenceChanged.stream
            .where((presence) => presence.userid == userId)
            .listen((presence) {
              hasChanged = true;
              controller.add(toPersonPresence(presence));
            });
        _read(
          client,
          userId,
          addRead,
          readFromServer: readFromServer,
        ).catchError(controller.addError);
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  /// The cached presence at once when known, then the server's.
  static Future<void> _read(
    Client client,
    String userId,
    void Function(CachedPresence) add, {
    required bool readFromServer,
  }) async {
    final cached = await client.fetchCurrentPresence(
      userId,
      fetchOnlyFromCached: true,
    );
    if (!readFromServer) {
      add(cached);
      return;
    }
    final isKnown = !_isNeverSeen(cached);
    if (isKnown) add(cached);
    try {
      final response = await client.getPresence(userId);
      add(CachedPresence.fromPresenceResponse(response, userId));
    } on Exception catch (e) {
      Logs().w('Failed to read the presence of $userId', e);
      if (!isKnown) add(cached);
    }
  }

  static bool _isNeverSeen(CachedPresence presence) =>
      presence.presence == PresenceType.offline &&
      presence.lastActiveTimestamp == null &&
      presence.statusMsg == null &&
      presence.currentlyActive == null;

  static PersonPresence toPersonPresence(CachedPresence presence) {
    final isOnline =
        presence.presence == PresenceType.online ||
        presence.currentlyActive == true;
    final statusMessage = presence.statusMsg?.trim();
    return PersonPresence(
      status: isOnline
          ? PresenceStatus.online
          : presence.presence == PresenceType.unavailable
          ? PresenceStatus.away
          : PresenceStatus.offline,
      lastActiveAt: presence.lastActiveTimestamp,
      statusMessage: statusMessage == null || statusMessage.isEmpty
          ? null
          : statusMessage,
    );
  }
}
