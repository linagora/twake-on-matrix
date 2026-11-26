import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/album_timeline_index.dart';

import '../../lenient_database.dart';

void main() {
  late Room room;

  setUpAll(() async => room = await getLenientRoom('!idx:example.com'));

  Event image(String id, int second, {String? batch = 'b1'}) => Event(
    senderId: '@a:example.com',
    type: 'm.room.message',
    room: room,
    eventId: id,
    content: {
      'msgtype': 'm.image',
      'body': id,
      if (batch != null) 'app.twake.chat.batch': batch,
    },
    originServerTs: DateTime.utc(2026, 11, 9, 10, 0, second),
    status: EventStatus.synced,
  );

  Event text(String id, int second) => Event(
    senderId: '@b:example.com',
    type: 'm.room.message',
    room: room,
    eventId: id,
    content: {'msgtype': 'm.text', 'body': id},
    originServerTs: DateTime.utc(2026, 11, 9, 10, 0, second),
    status: EventStatus.synced,
  );

  /// What Matrix keeps of a deleted image of '@a': no content, no batch key.
  Event deleted(String id, int second) => Event(
    senderId: '@a:example.com',
    type: 'm.room.message',
    room: room,
    eventId: id,
    content: const {},
    unsigned: {
      'redacted_because': {
        'type': 'm.room.redaction',
        'event_id': 'redaction-$id',
        'sender': '@a:example.com',
        'origin_server_ts': 0,
        'content': const <String, Object?>{},
      },
    },
    originServerTs: DateTime.utc(2026, 11, 9, 10, 0, second),
    status: EventStatus.synced,
  );

  /// [image] as the server sends it once someone replied in its thread
  /// (from the web client, say): the thread aggregate in `unsigned`.
  Event threadRoot(String id, int second) {
    final plain = image(id, second);
    return Event(
      senderId: plain.senderId,
      type: plain.type,
      room: room,
      eventId: id,
      content: plain.content,
      unsigned: {
        'm.relations': {
          'm.thread': {
            'count': 1,
            'current_user_participated': false,
            'latest_event': {
              'type': 'm.room.message',
              'event_id': 'reply-$id',
              'sender': '@b:example.com',
              'origin_server_ts': DateTime.utc(
                2026,
                11,
                9,
                10,
                5,
              ).millisecondsSinceEpoch,
              'content': {
                'msgtype': 'm.text',
                'body': 'a reply',
                'm.relates_to': {'rel_type': 'm.thread', 'event_id': id},
              },
            },
          },
        },
      },
      originServerTs: plain.originServerTs,
      status: EventStatus.synced,
    );
  }

  late Event newer, a, b, c, older;
  late AlbumTimelineIndex index;

  setUp(() {
    // Newest first, as the chat list holds them.
    newer = text('newer', 30);
    a = image('A', 12);
    b = image('B', 11);
    c = image('C', 10);
    older = text('older', 5);
    index = AlbumTimelineIndex([newer, a, b, c, older]);
  });

  test('the oldest image leads and the others are hidden', () {
    expect(index.albumLedBy('C')!.map((e) => e.eventId), ['C', 'B', 'A']);
    expect(index.albumLedBy('B'), isNull);
    expect(index.isHiddenMember('A'), isTrue);
    expect(index.isHiddenMember('B'), isTrue);
    expect(index.isHiddenMember('C'), isFalse);
  });

  test('a hidden image leads to the row that draws its album', () {
    expect(index.albumLeaderOf('A'), 'C');
    expect(index.albumLeaderOf('B'), 'C');
    expect(index.albumLeaderOf('C'), isNull);
    expect(index.albumLeaderOf('newer'), isNull);
  });

  test('the first unread image starts a new album', () {
    final split = AlbumTimelineIndex([newer, a, b, c, older], breakBefore: 'B');
    expect(split.albumLedBy('C'), isNull);
    expect(split.albumLedBy('B')!.map((e) => e.eventId), ['B', 'A']);
    expect(split.isHiddenMember('B'), isFalse);
  });

  test('the leader sees the events around the whole album', () {
    expect(index.newerNeighbour(c)?.eventId, 'newer');
    expect(index.olderNeighbour(c)?.eventId, 'older');
  });

  test('an event outside an album keeps its plain neighbours', () {
    expect(index.newerNeighbour(older)?.eventId, 'C');
    expect(index.olderNeighbour(older), isNull);
    expect(index.newerNeighbour(newer), isNull);
    expect(index.olderNeighbour(newer)?.eventId, 'A');
  });

  test('images without a batch key make no album', () {
    final plain = AlbumTimelineIndex([
      image('A', 12, batch: null),
      image('B', 11, batch: null),
    ]);

    expect(plain.albumLedBy('B'), isNull);
    expect(plain.isHiddenMember('A'), isFalse);
  });

  test('an event that is not in the list has no neighbours', () {
    expect(index.newerNeighbour(text('x', 1)), isNull);
    expect(index.olderNeighbour(text('x', 1)), isNull);
  });

  test('a deleted image inside an album is hidden and does not split it', () {
    final gone = deleted('B', 11);
    final reflowed = AlbumTimelineIndex([newer, a, gone, c, older]);

    expect(reflowed.albumLedBy('C')!.map((e) => e.eventId), ['C', 'A']);
    expect(reflowed.isHiddenMember('B'), isTrue);
    expect(reflowed.newerNeighbour(c), same(newer));
  });

  test('deleting every image leaves one deleted message per image', () {
    final all = [deleted('A', 12), deleted('B', 11), deleted('C', 10)];
    final gone = AlbumTimelineIndex([newer, ...all, older]);

    for (final id in ['A', 'B', 'C']) {
      expect(gone.isHiddenMember(id), isFalse, reason: id);
      expect(gone.albumLeaderOf(id), isNull, reason: id);
    }
    expect(gone.albumLedBy('C'), isNull);
    expect(gone.newerNeighbour(all.last), same(all[1]));
  });

  test('a deleted image hidden in an album leads to the album', () {
    final inAlbum = AlbumTimelineIndex([newer, a, deleted('B', 11), c, older]);

    expect(inAlbum.albumLeaderOf('B'), 'C');
  });

  test('two deleted images inside an album lead to the album', () {
    final reflowed = AlbumTimelineIndex([
      newer,
      a,
      deleted('B', 11),
      deleted('X', 10),
      image('D', 9),
      older,
    ]);

    expect(reflowed.albumLedBy('D')!.map((e) => e.eventId), ['D', 'A']);
    expect(reflowed.albumLeaderOf('B'), 'D');
    expect(reflowed.albumLeaderOf('X'), 'D');
  });

  // Need (iOS report 2026-11-26, web reference: isAlbumImage requires no
  // thread): an image with a thread leaves the album and shows alone, so its
  // thread card is seen and opens the thread.
  group('an image that has a thread', () {
    tearDown(() => AppConfig.threadsEnabled = true);

    test('as the last image, leaves the album; the others stay one', () {
      final root = threadRoot('A', 12);
      final split = AlbumTimelineIndex([newer, root, b, c, older]);

      expect(split.albumLedBy('C')!.map((e) => e.eventId), ['C', 'B']);
      expect(split.isHiddenMember('A'), isFalse);
      expect(split.albumLeaderOf('A'), isNull);
    });

    test('as the first image, leaves the album; the next one leads', () {
      final root = threadRoot('C', 10);
      final split = AlbumTimelineIndex([newer, a, b, root, older]);

      expect(split.albumLedBy('C'), isNull);
      expect(split.albumLedBy('B')!.map((e) => e.eventId), ['B', 'A']);
      expect(split.isHiddenMember('C'), isFalse);
    });

    test('in the middle, splits the album: each side alone makes none', () {
      final root = threadRoot('B', 11);
      final split = AlbumTimelineIndex([newer, a, root, c, older]);

      for (final id in ['A', 'B', 'C']) {
        expect(split.albumLedBy(id), isNull, reason: id);
        expect(split.isHiddenMember(id), isFalse, reason: id);
      }
    });

    test('stays in the album when threads are off', () {
      AppConfig.threadsEnabled = false;
      final root = threadRoot('A', 12);
      final kept = AlbumTimelineIndex([newer, root, b, c, older]);

      expect(kept.albumLedBy('C')!.map((e) => e.eventId), ['C', 'B', 'A']);
    });
  });

  // Need (iOS report 2026-11-26): a thread just started from mobile has no
  // server summary in `unsigned` yet, only live replies. The image is a
  // thread root all the same: it leaves the album so its card is seen.
  group('an image whose thread is known only from live replies', () {
    tearDown(() => AppConfig.threadsEnabled = true);

    test('as the last image, leaves the album; the others stay one', () {
      final split = AlbumTimelineIndex(
        [newer, a, b, c, older],
        threadRootIds: {'A'},
      );

      expect(split.albumLedBy('C')!.map((e) => e.eventId), ['C', 'B']);
      expect(split.isHiddenMember('A'), isFalse);
      expect(split.albumLeaderOf('A'), isNull);
    });

    test('as the first image, leaves the album; the next one leads', () {
      final split = AlbumTimelineIndex(
        [newer, a, b, c, older],
        threadRootIds: {'C'},
      );

      expect(split.albumLedBy('C'), isNull);
      expect(split.albumLedBy('B')!.map((e) => e.eventId), ['B', 'A']);
      expect(split.isHiddenMember('C'), isFalse);
    });

    test('in the middle, splits the album: each side alone makes none', () {
      final split = AlbumTimelineIndex(
        [newer, a, b, c, older],
        threadRootIds: {'B'},
      );

      for (final id in ['A', 'B', 'C']) {
        expect(split.albumLedBy(id), isNull, reason: id);
        expect(split.isHiddenMember(id), isFalse, reason: id);
      }
    });

    test('stays in the album when threads are off', () {
      AppConfig.threadsEnabled = false;
      final kept = AlbumTimelineIndex(
        [newer, a, b, c, older],
        threadRootIds: {'A'},
      );

      expect(kept.albumLedBy('C')!.map((e) => e.eventId), ['C', 'B', 'A']);
    });
  });
}
