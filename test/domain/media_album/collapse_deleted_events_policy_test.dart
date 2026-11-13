import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/media_album/entities/media_event_snapshot.dart';
import 'package:twake_chat/domain/media_album/policy/collapse_deleted_events_policy.dart';

void main() {
  const policy = CollapseDeletedEventsPolicy();
  final t0 = DateTime(2026, 11, 12, 14, 23);

  MediaEventSnapshot event(
    String id, {
    bool deleted = true,
    String sender = '@a:x',
    int second = 0,
  }) => MediaEventSnapshot(
    eventId: id,
    senderId: sender,
    originServerTs: t0.add(Duration(seconds: second)),
    isRedacted: deleted,
  );

  test('deleted events of one sender within a minute collapse', () {
    expect(policy.execute([event('1'), event('2'), event('3')]), [
      ['1', '2', '3'],
    ]);
  });

  test('a single deleted event is left alone', () {
    expect(policy.execute([event('1'), event('2', deleted: false)]), isEmpty);
  });

  test('another event, another sender or a minute gap ends a run', () {
    expect(
      policy.execute([event('1'), event('2', deleted: false), event('3')]),
      isEmpty,
    );
    expect(policy.execute([event('1'), event('2', sender: '@b:x')]), isEmpty);
    expect(policy.execute([event('1'), event('2', second: 61)]), isEmpty);
  });

  test('the first unread event starts a new run', () {
    expect(
      policy.execute([event('1'), event('2'), event('3')], breakBefore: '2'),
      [
        ['2', '3'],
      ],
    );
  });
}
