import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matrix/matrix.dart';

import 'package:twake_chat/presentation/extensions/client_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';

extension IosBadgeClientExtension on Client {
  void updateIosBadge() {
    if (PlatformInfos.isIOS) {
      // Workaround for iOS not clearing notifications with fcm_shared_isolate
      if (!joinedOrInvitedRooms.any(
        (r) => r.membership == Membership.invite || (r.notificationCount > 0),
      )) {
        // ignore: unawaited_futures
        FlutterLocalNotificationsPlugin().cancelAll();
        FlutterAppBadger.removeBadge();
      }
    }
  }
}
