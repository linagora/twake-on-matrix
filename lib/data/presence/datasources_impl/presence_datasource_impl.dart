import 'dart:async';

import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/presence/datasources/presence_datasource.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';

class PresenceDatasourceImpl implements PresenceDatasource {
  const PresenceDatasourceImpl(this._client);

  final Client? _client;

  @override
  Stream<PersonPresence?> watchPresence(String userId) {
    final client = _client;
    if (client == null) return Stream.value(null);
    StreamSubscription<CachedPresence>? changes;
    late final StreamController<PersonPresence?> controller;
    controller = StreamController<PersonPresence?>(
      onListen: () {
        var hasChanged = false;
        // Listen before reading: a change that lands during the read wins
        changes = client.onPresenceChanged.stream
            .where((presence) => presence.userid == userId)
            .listen((presence) {
              hasChanged = true;
              controller.add(toPersonPresence(presence));
            });
        client.fetchCurrentPresence(userId).then((presence) {
          if (hasChanged || controller.isClosed) return;
          controller.add(toPersonPresence(presence));
        }, onError: controller.addError);
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

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
