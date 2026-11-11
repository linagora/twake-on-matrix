import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import '../../fake_client.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_to_media_snapshot_extension.dart';

Event _event(
  Map<String, Object?> content, {
  String type = 'm.room.message',
  EventStatus status = EventStatus.synced,
}) {
  final client = Client('album-test', database: MockDatabase());
  final room = Room(id: '!r:x', client: client);
  return Event(
    content: content,
    type: type,
    eventId: r'$e',
    senderId: '@a:x',
    originServerTs: DateTime(2026, 11, 6),
    room: room,
    status: status,
  );
}

void main() {
  test('reads the batch key and image flags', () {
    final s = _event({
      'msgtype': 'm.image',
      'body': 'a.png',
      'app.twake.chat.batch': 'b1',
    }).toMediaSnapshot();
    expect(s.batchId, 'b1');
    expect(s.isImage, isTrue);
    expect(s.isFailed, isFalse);
    expect(s.hasCaption, isFalse);
  });

  test('ignores a batch key that is not a non-empty string', () {
    expect(
      _event({'msgtype': 'm.image', 'app.twake.chat.batch': 7}).mediaBatchId,
      isNull,
    );
    expect(
      _event({'msgtype': 'm.image', 'app.twake.chat.batch': ''}).mediaBatchId,
      isNull,
    );
  });

  test('a caption is a body that differs from the filename', () {
    final s = _event({
      'msgtype': 'm.image',
      'body': 'hello',
      'filename': 'a.png',
      'app.twake.chat.batch': 'b1',
    }).toMediaSnapshot();
    expect(s.hasCaption, isTrue);
  });

  test('only a failed send is flagged, a pending one stays in the group', () {
    final content = {'msgtype': 'm.image', 'app.twake.chat.batch': 'b1'};
    expect(
      _event(content, status: EventStatus.sending).toMediaSnapshot().isFailed,
      isFalse,
    );
    expect(
      _event(content, status: EventStatus.error).toMediaSnapshot().isFailed,
      isTrue,
    );
  });

  test(
    'a pending placeholder with a caption keeps the key and the caption',
    () {
      // Same content shape as sendFakeFileInfoEvent builds.
      final s = _event({
        'msgtype': 'm.image',
        'body': 'hello',
        'filename': 'a.png',
        'info': <String, dynamic>{},
        'app.twake.chat.batch': 'b1',
      }, status: EventStatus.sending).toMediaSnapshot();
      expect(s.batchId, 'b1');
      expect(s.hasCaption, isTrue);
      expect(s.isFailed, isFalse);
    },
  );
}
