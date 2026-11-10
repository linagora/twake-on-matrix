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

  /// Whether the current timeline mixes in breaking events; a quiet one is
  /// one long send, so that runs reach the cap.
  bool _noisy = true;

  /// Up to 40 events, oldest first, each 0 to 61 s after the one before.
  List<MediaEventSnapshot> timeline() {
    final length = random.nextInt(40);
    _noisy = random.nextBool();
    var at = start;
    var batch = 'b0';
    return [
      for (var i = 0; i < length; i++)
        _snapshot(
          'e$i',
          at = at.add(Duration(seconds: _chance(10) ? 61 : random.nextInt(30))),
          _chance(8) ? batch = 'b$i' : batch,
        ),
    ];
  }

  /// A random event id of [snapshots] to break before, or null.
  String? breakBefore(List<MediaEventSnapshot> snapshots) =>
      snapshots.isEmpty || random.nextBool()
      ? null
      : snapshots[random.nextInt(snapshots.length)].eventId;

  bool _chance(int oneIn) => _noisy && random.nextInt(oneIn) == 0;

  MediaEventSnapshot _snapshot(String id, DateTime at, String batch) =>
      MediaEventSnapshot(
        eventId: id,
        senderId: _chance(10) ? '@b:x' : '@a:x',
        originServerTs: at,
        isImage: !_chance(15),
        isFailed: _chance(20),
        inThread: _chance(25),
        isReply: _chance(15),
        hasCaption: _chance(15),
        batchId: _chance(12) ? null : batch,
      );

  /// Every adjacent pair that may join is in one album, unless the album of
  /// the older one is full.
  void expectComplete(
    List<MediaEventSnapshot> snapshots,
    List<MediaAlbum> albums,
    String? breakBefore,
  ) {
    final albumOf = {
      for (final a in albums)
        for (final id in a.eventIds) id: a,
    };
    for (var i = 1; i < snapshots.length; i++) {
      final older = snapshots[i - 1];
      final newer = snapshots[i];
      if (!_mayJoin(older, newer) || newer.eventId == breakBefore) continue;
      final album = albumOf[older.eventId];
      final full =
          album != null &&
          album.eventIds.length == GroupMediaEventsPolicy.maxAlbumSize &&
          album.eventIds.last == older.eventId;
      if (!full) expect(albumOf[newer.eventId], same(album));
    }
  }

  bool _mayJoin(MediaEventSnapshot a, MediaEventSnapshot b) =>
      _albumImage(a) &&
      _albumImage(b) &&
      a.senderId == b.senderId &&
      a.batchId == b.batchId &&
      !a.hasCaption &&
      !b.isReply &&
      b.originServerTs.difference(a.originServerTs).inSeconds <= 60 &&
      a.originServerTs.day == b.originServerTs.day;

  bool _albumImage(MediaEventSnapshot s) =>
      s.isImage && !s.isFailed && !s.inThread && s.batchId != null;

  void expectSound(
    List<MediaEventSnapshot> snapshots,
    List<MediaAlbum> albums,
    String? breakBefore,
  ) {
    final byId = {for (final s in snapshots) s.eventId: s};
    final seen = <String>{};
    for (final album in albums) {
      expect(seen.intersection(album.eventIds.toSet()), isEmpty);
      seen.addAll(album.eventIds);
      _expectRules(snapshots, [for (final id in album.eventIds) byId[id]!]);
      expect(album.eventIds.skip(1), isNot(contains(breakBefore)));
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
    for (var i = 1; i < members.length; i++) {
      final gap = members[i].originServerTs.difference(
        members[i - 1].originServerTs,
      );
      expect(gap.inSeconds, lessThanOrEqualTo(60));
    }
  }
}

void main() {
  test('albums are sound and complete over many generated timelines', () {
    final invariants = _AlbumInvariants(Random(42));
    var fullAlbums = 0;
    for (var run = 0; run < 300; run++) {
      final snapshots = invariants.timeline();
      final breakBefore = invariants.breakBefore(snapshots);
      final albums = const GroupMediaEventsPolicy().execute(
        snapshots,
        breakBefore: breakBefore,
      );
      invariants.expectSound(snapshots, albums, breakBefore);
      invariants.expectComplete(snapshots, albums, breakBefore);
      fullAlbums += albums.where((a) => a.eventIds.length == 10).length;
    }
    expect(fullAlbums, greaterThan(0), reason: 'the cap is never reached');
  });
}
