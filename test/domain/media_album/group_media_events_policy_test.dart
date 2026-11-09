import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/media_album/entities/media_event_snapshot.dart';
import 'package:twake_chat/domain/media_album/policy/group_media_events_policy.dart';

void main() {
  const policy = GroupMediaEventsPolicy();
  final t0 = DateTime(2026, 11, 6, 18, 28);

  MediaEventSnapshot img(
    String id, {
    String sender = '@a:x',
    String? batch = 'b1',
    bool isReply = false,
    bool hasCaption = false,
    bool isFailed = false,
    bool isRedacted = false,
    bool inThread = false,
    bool isImage = true,
    DateTime? ts,
  }) => MediaEventSnapshot(
    eventId: id,
    senderId: sender,
    originServerTs: ts ?? t0,
    isImage: isImage,
    isFailed: isFailed,
    isRedacted: isRedacted,
    inThread: inThread,
    isReply: isReply,
    hasCaption: hasCaption,
    batchId: batch,
  );

  List<List<String>> ids(List<MediaEventSnapshot> s) => [
    for (final a in policy.execute(s)) a.eventIds,
  ];

  test(
    'groups adjacent images of one batch and picks the oldest as leader',
    () {
      final albums = policy.execute([img('1'), img('2'), img('3')]);
      expect(albums.single.eventIds, ['1', '2', '3']);
      expect(albums.single.leaderEventId, '1');
    },
  );

  test('no batch key or a single image never groups', () {
    expect(ids([img('1', batch: null), img('2', batch: null)]), isEmpty);
    expect(ids([img('1')]), isEmpty);
  });

  test('two sends by the same sender stay two albums', () {
    expect(
      ids([img('1'), img('2'), img('3', batch: 'b2'), img('4', batch: 'b2')]),
      [
        ['1', '2'],
        ['3', '4'],
      ],
    );
  });

  test('another sender cannot join with a copied key', () {
    expect(ids([img('1'), img('2', sender: '@b:x')]), isEmpty);
  });

  test('a message in between ends the run', () {
    expect(ids([img('1'), img('t', isImage: false), img('2')]), isEmpty);
  });

  test('run is capped at 10', () {
    final s = [for (var i = 0; i < 11; i++) img('$i')];
    expect(ids(s).single.length, 10);
  });

  test('reply only on the first member', () {
    expect(ids([img('1', isReply: true), img('2')]), [
      ['1', '2'],
    ]);
    expect(ids([img('1'), img('2', isReply: true)]), isEmpty);
  });

  test('caption only on the last member', () {
    expect(ids([img('1'), img('2', hasCaption: true)]), [
      ['1', '2'],
    ]);
    expect(ids([img('1', hasCaption: true), img('2')]), isEmpty);
  });

  test('a failed, redacted or thread image splits the run', () {
    expect(ids([img('1'), img('2', isFailed: true), img('3')]), isEmpty);
    expect(ids([img('1'), img('2', isRedacted: true), img('3')]), isEmpty);
    expect(ids([img('1'), img('2', inThread: true), img('3')]), isEmpty);
  });

  test('images on different days do not join', () {
    expect(
      ids([img('1'), img('2', ts: t0.add(const Duration(days: 1)))]),
      isEmpty,
    );
  });
}
