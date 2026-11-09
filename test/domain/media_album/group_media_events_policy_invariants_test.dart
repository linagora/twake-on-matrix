import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/media_album/entities/media_album.dart';
import 'package:twake_chat/domain/media_album/entities/media_event_snapshot.dart';
import 'package:twake_chat/domain/media_album/policy/group_media_events_policy.dart';

/// Builds random timelines and checks what every album must satisfy.
class _AlbumInvariants {
  final Random random;
  final DateTime start = DateTime(2026, 11, 6, 18, 28);

  _AlbumInvariants(this.random);

  List<MediaEventSnapshot> timeline() => [
    for (var i = 0; i < random.nextInt(40); i++) _snapshot('e$i'),
  ];

  MediaEventSnapshot _snapshot(String id) => MediaEventSnapshot(
    eventId: id,
    senderId: random.nextBool() ? '@a:x' : '@b:x',
    originServerTs: start.add(Duration(hours: random.nextInt(60))),
    isImage: random.nextInt(8) != 0,
    isFailed: random.nextInt(10) == 0,
    inThread: random.nextInt(12) == 0,
    isReply: random.nextInt(6) == 0,
    hasCaption: random.nextInt(6) == 0,
    batchId: random.nextInt(4) == 0 ? null : 'b${random.nextInt(3)}',
  );

  void expectSound(
    List<MediaEventSnapshot> snapshots,
    List<MediaAlbum> albums,
  ) {
    final byId = {for (final s in snapshots) s.eventId: s};
    final seen = <String>{};
    for (final album in albums) {
      expect(seen.intersection(album.eventIds.toSet()), isEmpty);
      seen.addAll(album.eventIds);
      _expectRules(snapshots, [for (final id in album.eventIds) byId[id]!]);
    }
  }

  void _expectRules(
    List<MediaEventSnapshot> snapshots,
    List<MediaEventSnapshot> members,
  ) {
    expect(members.length, inInclusiveRange(2, 10));
    expect(members.map((m) => m.senderId).toSet(), hasLength(1));
    expect(members.map((m) => m.batchId).toSet(), hasLength(1));
    expect(members.every((m) => m.isImage && !m.isFailed), isTrue);
    expect(members.skip(1).any((m) => m.isReply), isFalse);
    expect(members.take(members.length - 1).any((m) => m.hasCaption), isFalse);
    final first = snapshots.indexOf(members.first);
    expect(snapshots.sublist(first, first + members.length), members);
  }
}

void main() {
  test('invariants hold over many generated timelines', () {
    final invariants = _AlbumInvariants(Random(42));
    for (var run = 0; run < 300; run++) {
      final snapshots = invariants.timeline();
      invariants.expectSound(
        snapshots,
        const GroupMediaEventsPolicy().execute(snapshots),
      );
    }
  });
}
