import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/activity/usecases/watch_activity_use_case.dart';
import 'package:twake_chat/domain/model/activity/activity_item.dart';

import '../../../pages/activity/activity_test_support.dart';

/// ADR 0037 §5 (review of PR #3624, jbrnzl): the Activity tab reads its
/// items through a use case over the activity repository: the unread rooms
/// and the followed threads, now then at each change.
void main() {
  late FakeActivityRepository repository;

  final design = UnreadRoomItem(
    roomId: '!design:example.org',
    roomName: 'Design',
    time: 11.today,
    unreadCount: 3,
    author: 'Bob Martin',
    lastMessage: 'see you there',
  ).item;
  final release = FollowedThreadItem(
    roomId: '!design:example.org',
    roomName: 'Design',
    rootId: r'$release',
    time: 10.today,
    lastReply: 'Ship it',
  ).item;

  setUp(() => repository = FakeActivityRepository(items: [design]));
  tearDown(() => repository.close());

  test('gives the items of the activity, then each change', () async {
    final shown = WatchActivityUseCase(repository).execute();
    final seen = expectLater(
      shown,
      emitsInOrder(<List<ActivityItem>>[
        [design],
        [design, release],
        [],
      ]),
    );
    await pumpEventQueue();

    repository.emit([design, release]);
    repository.emit([]);

    await seen;
  });
}
