import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/dock_badge.dart';

class _FakePort implements DockBadgePort {
  final events = <String>[];
  Object? failure;

  @override
  Future<void> setCount(int count) async {
    final f = failure;
    if (f != null) throw f;
    events.add('set $count');
  }

  @override
  Future<void> clear() async {
    final f = failure;
    if (f != null) throw f;
    events.add('clear');
  }
}

DockBadgeRoom room({
  int notificationCount = 0,
  int highlightCount = 0,
  bool isInvite = false,
  bool isMuted = false,
}) => DockBadgeRoom(
  notificationCount: notificationCount,
  highlightCount: highlightCount,
  isInvite: isInvite,
  isMuted: isMuted,
);

void main() {
  group('dockBadgeCount', () {
    test('no room, no badge', () {
      expect(dockBadgeCount([]), 0);
    });

    test('sums the unread messages of all rooms', () {
      expect(
        dockBadgeCount([
          room(notificationCount: 3),
          room(notificationCount: 2),
          room(),
        ]),
        5,
      );
    });

    test('a pending invitation counts as one', () {
      expect(
        dockBadgeCount([room(isInvite: true), room(notificationCount: 2)]),
        3,
      );
    });

    test('a muted room does not count', () {
      expect(dockBadgeCount([room(notificationCount: 4, isMuted: true)]), 0);
    });

    test('a muted room counts when it mentions the user', () {
      expect(
        dockBadgeCount([
          room(notificationCount: 4, highlightCount: 1, isMuted: true),
        ]),
        4,
      );
    });
  });

  group('DockBadgeUpdater', () {
    test('shows the total on the Dock icon', () async {
      final port = _FakePort();
      final updater = DockBadgeUpdater(port);

      await updater.update([room(notificationCount: 2), room(isInvite: true)]);

      expect(port.events, ['set 3']);
    });

    test('removes the badge when everything is read', () async {
      final port = _FakePort();
      final updater = DockBadgeUpdater(port);
      await updater.update([room(notificationCount: 2)]);

      await updater.update([room()]);

      expect(port.events, ['set 2', 'clear']);
    });

    test('does not touch the Dock when the total is unchanged', () async {
      final port = _FakePort();
      final updater = DockBadgeUpdater(port);

      await updater.update([room(notificationCount: 2)]);
      await updater.update([
        room(notificationCount: 1),
        room(notificationCount: 1),
      ]);

      expect(port.events, ['set 2']);
    });

    test(
      'a native failure never throws, and the next update retries',
      () async {
        final port = _FakePort()..failure = Exception('no dock');
        final updater = DockBadgeUpdater(port);

        await expectLater(
          updater.update([room(notificationCount: 2)]),
          completes,
        );

        port.failure = null;
        await updater.update([room(notificationCount: 2)]);
        expect(port.events, ['set 2']);
      },
    );
  });
}
