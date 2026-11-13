import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/domain/model/thread/thread_unread_state.dart';
import 'package:twake_chat/utils/thread_unread/thread_unread_store.dart';

/// The badge on the app icon.
abstract interface class IconBadge {
  void show(int count);

  void remove();
}

/// The icon badge of the device, through the platform plugin.
class DeviceIconBadge implements IconBadge {
  const DeviceIconBadge();

  @override
  void show(int count) => FlutterAppBadger.updateBadgeCount(count);

  @override
  void remove() => FlutterAppBadger.removeBadge();
}

/// Keeps the iOS icon badge on the number of rooms unread (threads counted
/// as the room list does) or invited. The notification extension writes the
/// icon from the push counts; with threads on, the app rewrites it with this
/// count after a sync or a thread counter change, and when it goes to the
/// background. Coming back writes nothing: the counts are stale until the
/// catch-up sync. 0 removes the badge.
class IconBadgeUpdater {
  IconBadgeUpdater({
    required this.client,
    required this.badge,
    required this.onIos,
  }) {
    if (onIos && AppConfig.threadsEnabled) _follow();
  }

  final Client client;
  final IconBadge badge;
  final bool onIos;

  int? _written;
  StreamSubscription<SyncUpdate>? _syncs;
  AppLifecycleListener? _lifecycle;

  void _follow() {
    _syncs = client.onSync.stream.listen((_) => _writeIfChanged());
    client.threadUnread?.addListener(_writeIfChanged);
    _lifecycle = AppLifecycleListener(onPause: _onBackground);
  }

  /// The count without [room], which the user is opening.
  void roomOpened(RoomId room) {
    if (onIos) _write(_count(except: room));
  }

  void dispose() {
    unawaited(_syncs?.cancel());
    client.threadUnread?.removeListener(_writeIfChanged);
    _lifecycle?.dispose();
  }

  int _count({RoomId? except}) => client.joinedOrInvitedRooms
      .where(
        (room) => room.isUnreadOrInvitedWithThreads && room.id != except?.value,
      )
      .length;

  void _writeIfChanged() {
    final count = _count();
    if (count != _written) _write(count);
  }

  /// The extension writes the icon while the app is in the background, so
  /// what the app wrote is forgotten: the first sync after is never skipped.
  void _onBackground() {
    _writeIfChanged();
    _written = null;
  }

  void _write(int count) {
    _written = count;
    if (count == 0) {
      badge.remove();
    } else {
      badge.show(count);
    }
  }
}
