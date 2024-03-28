import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

import '../date_time_extension.dart';

extension PresenceExtension on CachedPresence {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  String getLocalizedLastActiveAgo(BuildContext context) {
    final lastActiveTimestamp = this.lastActiveTimestamp;
    if (lastActiveTimestamp != null) {
      return L10n.of(context)!
          .lastActiveAgo(lastActiveTimestamp.localizedTimeShort(context));
    }
    return L10n.of(context)!.lastSeenLongTimeAgo;
  }

  String getLocalizedStatusMessage(BuildContext context) {
    final statusMsg = this.statusMsg;
    if (statusMsg != null && statusMsg.isNotEmpty) {
      return statusMsg;
    }
    if (currentlyActive ?? false) {
      return L10n.of(context)!.currentlyActive;
    }
    return getLocalizedLastActiveAgo(context);
  }

  Color get color {
    switch (presence) {
      case PresenceType.online:
        return Colors.green;
      case PresenceType.offline:
        return Colors.grey;
      case PresenceType.unavailable:
      default:
        return Colors.red;
    }
  }

  TextStyle? getPresenceTextStyle(BuildContext context) =>
      currentlyActive ?? false
          ? _onlineStatusTextStyle(context)
          : _offlineStatusTextStyle(context);

  TextStyle? _offlineStatusTextStyle(BuildContext context) =>
      responsive.isMobile(context)
          ? Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LinagoraRefColors.material().tertiary[30],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingStatusContent,
              )
          : Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LinagoraRefColors.material().neutral[50],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
              );

  TextStyle? _onlineStatusTextStyle(BuildContext context) =>
      responsive.isMobile(context)
          ? Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LinagoraRefColors.material().secondary,
                letterSpacing: ChatAppBarTitleStyle.letterSpacingStatusContent,
              )
          : Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LinagoraRefColors.material().secondary,
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
              );
}
