import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/thread/models/sync_thread_counts.dart';
import 'package:twake_chat/domain/model/thread/thread_unread.dart';

/// THR-M-06: per-thread counters from the sync, room badge and the
/// "New replies in a thread" banner. In P1 a thread is followed when the user
/// wrote the root or replied in it.
void main() {
  group('parseUnreadThreadNotifications', () {
    test('reads the counters of each thread from the joined room sync', () {
      final counts = parseUnreadThreadNotifications({
        r'$rootA': {'notification_count': 3, 'highlight_count': 1},
        r'$rootB': {'notification_count': 1, 'highlight_count': 0},
      });

      expect(counts, {
        r'$rootA': (notificationCount: 3, highlightCount: 1),
        r'$rootB': (notificationCount: 1, highlightCount: 0),
      });
    });

    test('a missing counter reads as zero', () {
      final counts = parseUnreadThreadNotifications({
        r'$root': {'notification_count': 2},
      });

      expect(counts, {r'$root': (notificationCount: 2, highlightCount: 0)});
    });

    test('nothing in the sync gives no thread counters', () {
      expect(parseUnreadThreadNotifications(null), isEmpty);
    });

    test('malformed entries are ignored, the valid ones kept', () {
      final counts = parseUnreadThreadNotifications({
        r'$broken': 'not a map',
        r'$wrongType': {'notification_count': 'two'},
        r'$ok': {'notification_count': 1, 'highlight_count': 1},
      });

      expect(counts, {r'$ok': (notificationCount: 1, highlightCount: 1)});
    });
  });

  group('room badge', () {
    ThreadUnread thread(
      String rootId, {
      int notifications = 0,
      int mentions = 0,
      bool followed = false,
    }) => ThreadUnread(
      rootEventId: rootId,
      notificationCount: notifications,
      highlightCount: mentions,
      followed: followed,
    );

    test('a room without threads shows its main timeline unread count', () {
      expect(roomUnreadBadge(mainNotificationCount: 4, threads: []), 4);
    });

    test('unread replies of a followed thread add to the badge', () {
      expect(
        roomUnreadBadge(
          mainNotificationCount: 1,
          threads: [thread(r'$a', notifications: 3, followed: true)],
        ),
        4,
      );
    });

    test('unread replies of a thread the user does not follow only count on '
        'its card', () {
      expect(
        roomUnreadBadge(
          mainNotificationCount: 1,
          threads: [thread(r'$a', notifications: 5)],
        ),
        1,
      );
    });

    test(
      'a mention in a thread the user does not follow adds to the badge',
      () {
        expect(
          roomUnreadBadge(
            mainNotificationCount: 0,
            threads: [thread(r'$a', notifications: 5, mentions: 2)],
          ),
          2,
        );
      },
    );

    test('a mention in a followed thread is counted once', () {
      // highlight_count is part of notification_count.
      expect(
        roomUnreadBadge(
          mainNotificationCount: 0,
          threads: [
            thread(r'$a', notifications: 3, mentions: 1, followed: true),
          ],
        ),
        3,
      );
    });

    test('main timeline, followed threads and mentions add up', () {
      expect(
        roomUnreadBadge(
          mainNotificationCount: 2,
          threads: [
            thread(r'$a', notifications: 3, followed: true),
            thread(r'$b', notifications: 4, mentions: 1),
            thread(r'$c', notifications: 6),
          ],
        ),
        2 + 3 + 1,
      );
    });

    test('a read room with read threads shows no badge', () {
      expect(
        roomUnreadBadge(
          mainNotificationCount: 0,
          threads: [thread(r'$a', followed: true)],
        ),
        0,
      );
    });
  });

  group('unread thread banner', () {
    ThreadUnread thread(
      String rootId, {
      int notifications = 0,
      int mentions = 0,
      bool followed = false,
    }) => ThreadUnread(
      rootEventId: rootId,
      notificationCount: notifications,
      highlightCount: mentions,
      followed: followed,
    );

    test('a read room whose followed thread is unread opens that thread', () {
      expect(
        unreadThreadBannerTarget(
          mainNotificationCount: 0,
          threads: [thread(r'$a', notifications: 2, followed: true)],
        ),
        r'$a',
      );
    });

    test('a read room with a mention in a thread not followed opens that '
        'thread', () {
      expect(
        unreadThreadBannerTarget(
          mainNotificationCount: 0,
          threads: [thread(r'$b', notifications: 2, mentions: 1)],
        ),
        r'$b',
      );
    });

    test('no banner when the unread thread is not followed and has no '
        'mention', () {
      expect(
        unreadThreadBannerTarget(
          mainNotificationCount: 0,
          threads: [thread(r'$c', notifications: 4)],
        ),
        isNull,
      );
    });

    test('no banner when the main timeline is unread', () {
      expect(
        unreadThreadBannerTarget(
          mainNotificationCount: 1,
          threads: [thread(r'$a', notifications: 2, followed: true)],
        ),
        isNull,
      );
    });

    test('no banner when nothing is unread', () {
      expect(
        unreadThreadBannerTarget(mainNotificationCount: 0, threads: []),
        isNull,
      );
    });
  });
}
