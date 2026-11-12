import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
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

  test('deleting every image leaves one deleted message', () {
    final all = [deleted('A', 12), deleted('B', 11), deleted('C', 10)];
    final collapsed = AlbumTimelineIndex([newer, ...all, older]);

    expect(collapsed.isHiddenMember('C'), isFalse);
    expect(collapsed.isHiddenMember('B'), isTrue);
    expect(collapsed.isHiddenMember('A'), isTrue);
    expect(collapsed.albumLedBy('C'), isNull);
    expect(collapsed.newerNeighbour(all.last), same(newer));
  });
}
