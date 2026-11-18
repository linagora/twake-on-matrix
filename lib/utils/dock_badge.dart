import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/message_notification_decision.dart';

class DockBadgeRoom {
  const DockBadgeRoom({
    required this.notificationCount,
    required this.highlightCount,
    required this.isInvite,
    required this.isMuted,
  });

  final int notificationCount;
  final int highlightCount;
  final bool isInvite;
  final bool isMuted;
}

/// Unread messages plus one per invitation; a muted room only counts when it
/// mentions the user.
int dockBadgeCount(Iterable<DockBadgeRoom> rooms) {
  var total = 0;
  for (final r in rooms) {
    if (r.isInvite) {
      total++;
    } else if (countsDespiteMute(
      isMuted: r.isMuted,
      highlightCount: r.highlightCount,
    )) {
      total += r.notificationCount;
    }
  }
  return total;
}

abstract class DockBadgePort {
  Future<void> setCount(int count);
  Future<void> clear();
}

/// [DockBadgePort] on `flutter_app_badger`, which sets the macOS dock tile.
class FlutterAppBadgerDockPort implements DockBadgePort {
  @override
  Future<void> setCount(int count) => FlutterAppBadger.updateBadgeCount(count);

  @override
  Future<void> clear() => FlutterAppBadger.removeBadge();
}

class DockBadgeUpdater {
  DockBadgeUpdater(this._port);

  final DockBadgePort _port;
  int? _last;

  /// Never throws; a failed call is retried by the next update.
  Future<void> update(Iterable<DockBadgeRoom> rooms) async {
    final count = dockBadgeCount(rooms);
    if (count == _last) return;
    try {
      count == 0 ? await _port.clear() : await _port.setCount(count);
      _last = count;
    } catch (e, s) {
      Logs().w('[DockBadge] native call failed', e, s);
    }
  }
}
