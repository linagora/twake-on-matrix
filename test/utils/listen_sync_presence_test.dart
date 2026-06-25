import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

/// Replicates the fixed _listenSyncPresence logic from MatrixState so it can be
/// tested in isolation without Flutter widget infrastructure.
///
/// Emits one [CachedPresence] per user per sync, keeping the most recent
/// [lastActiveTimestamp] when a user appears multiple times in the same sync.
StreamSubscription<SyncUpdate> listenSyncPresence(
  Stream<SyncUpdate> onSync,
  StreamController<CachedPresence> out,
) {
  return onSync.listen((sync) {
    final latestPerUser = <String, CachedPresence>{};

    for (final newPresence in sync.presence ?? []) {
      final cachedPresence = CachedPresence.fromMatrixEvent(newPresence);
      final userId = cachedPresence.userid;
      final existing = latestPerUser[userId];
      final newTs = cachedPresence.lastActiveTimestamp;
      final oldTs = existing?.lastActiveTimestamp;
      if (existing == null ||
          (newTs != null && (oldTs == null || newTs.isAfter(oldTs)))) {
        latestPerUser[userId] = cachedPresence;
      }
    }

    for (final presence in latestPerUser.values) {
      out.add(presence);
    }
  });
}

/// Builds a [SyncUpdate] whose presence list contains the given raw events.
SyncUpdate _syncWith(List<Map<String, Object?>> rawPresenceEvents) {
  return SyncUpdate(
    nextBatch: 'batch',
    presence: rawPresenceEvents.map((e) => Presence.fromJson(e)).toList(),
  );
}

/// Helper to build a raw presence event map.
Map<String, Object?> _presenceEvent({
  required String userId,
  required String presenceType,
  int? lastActiveAgoMs,
}) {
  final content = <String, Object?>{
    'presence': presenceType,
    if (lastActiveAgoMs != null) 'last_active_ago': lastActiveAgoMs,
  };
  return {
    'type': 'm.presence',
    'sender': userId,
    'content': content,
  };
}

void main() {
  group('listenSyncPresence', () {
    late StreamController<SyncUpdate> syncController;
    late StreamController<CachedPresence> output;
    late StreamSubscription<SyncUpdate> sub;
    late List<CachedPresence> emitted;

    setUp(() {
      syncController = StreamController<SyncUpdate>.broadcast();
      output = StreamController<CachedPresence>.broadcast();
      emitted = [];
      output.stream.listen(emitted.add);
      sub = listenSyncPresence(syncController.stream, output);
    });

    tearDown(() async {
      await sub.cancel();
      await syncController.close();
      await output.close();
    });

    test(
      'GIVEN sync contains presence for one user '
      'THEN emits that user presence',
      () async {
        syncController.add(
          _syncWith([
            _presenceEvent(
              userId: '@bob:example.com',
              presenceType: 'online',
            ),
          ]),
        );

        await Future.delayed(Duration.zero);

        expect(emitted, hasLength(1));
        expect(emitted.first.userid, '@bob:example.com');
        expect(emitted.first.presence, PresenceType.online);
      },
    );

    test(
      'GIVEN sync contains presence for two different users '
      'THEN emits both — the bug: previously only one was emitted',
      () async {
        syncController.add(
          _syncWith([
            _presenceEvent(
              userId: '@bob:example.com',
              presenceType: 'online',
            ),
            _presenceEvent(
              userId: '@carol:example.com',
              presenceType: 'offline',
              lastActiveAgoMs: 5 * 60 * 1000, // 5 min ago
            ),
          ]),
        );

        await Future.delayed(Duration.zero);

        expect(emitted, hasLength(2));
        final userIds = emitted.map((e) => e.userid).toSet();
        expect(
          userIds,
          containsAll(['@bob:example.com', '@carol:example.com']),
        );
      },
    );

    test(
      'GIVEN sync has Bob (offline, 6 min ago) and Carol (online, just now) '
      'THEN Bob presence is still emitted — the original bug scenario',
      () async {
        syncController.add(
          _syncWith([
            _presenceEvent(
              userId: '@bob:example.com',
              presenceType: 'offline',
              lastActiveAgoMs: 6 * 60 * 1000,
            ),
            _presenceEvent(
              userId: '@carol:example.com',
              presenceType: 'online',
              lastActiveAgoMs: 0,
            ),
          ]),
        );

        await Future.delayed(Duration.zero);

        expect(emitted, hasLength(2));
        final bobPresence =
            emitted.firstWhere((e) => e.userid == '@bob:example.com');
        final carolPresence =
            emitted.firstWhere((e) => e.userid == '@carol:example.com');

        expect(bobPresence.presence, PresenceType.offline);
        expect(carolPresence.presence, PresenceType.online);
      },
    );

    test(
      'GIVEN sync has duplicate events for the same user '
      'THEN emits only one with the most recent timestamp (anti-flicker)',
      () async {
        syncController.add(
          _syncWith([
            _presenceEvent(
              userId: '@bob:example.com',
              presenceType: 'offline',
              lastActiveAgoMs: 10 * 60 * 1000, // older
            ),
            _presenceEvent(
              userId: '@bob:example.com',
              presenceType: 'online',
              lastActiveAgoMs: 2 * 60 * 1000, // more recent
            ),
          ]),
        );

        await Future.delayed(Duration.zero);

        expect(emitted, hasLength(1));
        expect(emitted.first.userid, '@bob:example.com');
        expect(emitted.first.presence, PresenceType.online);
      },
    );

    test(
      'GIVEN sync has no presence events '
      'THEN emits nothing',
      () async {
        syncController.add(SyncUpdate(nextBatch: 'batch', presence: []));

        await Future.delayed(Duration.zero);

        expect(emitted, isEmpty);
      },
    );

    test(
      'GIVEN multiple syncs arrive '
      'THEN each sync emits its own presence updates independently',
      () async {
        syncController.add(
          _syncWith([
            _presenceEvent(
              userId: '@bob:example.com',
              presenceType: 'online',
            ),
          ]),
        );
        await Future.delayed(Duration.zero);
        expect(emitted, hasLength(1));

        syncController.add(
          _syncWith([
            _presenceEvent(
              userId: '@carol:example.com',
              presenceType: 'offline',
              lastActiveAgoMs: 3 * 60 * 1000,
            ),
          ]),
        );
        await Future.delayed(Duration.zero);
        expect(emitted, hasLength(2));
        expect(emitted[1].userid, '@carol:example.com');
      },
    );
  });
}
