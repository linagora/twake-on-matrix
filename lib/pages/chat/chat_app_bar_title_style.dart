import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatAppBarTitleStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const Color currentlyActiveColor = Color(0xFF5AD439);
  static const Color currentlyInactiveColor = Color(0xFF818C99);
  static const Color encryptedIconColor = Color(0xFF00C853);

  static double get avatarFontSize => 15.0;
  static double avatarSize(BuildContext context) =>
      responsive.isMobile(context) ? 40.0 : 48.0;

  static double get statusSize => 15;
  static Color get statusBorderColor => Colors.white;
  static double get statusBorderSize => 2;

  static double get letterSpacingRoomName => 0.15;
  static double get letterSpacingStatusContent => 0.5;

  static TextStyle? appBarTitleStyle(BuildContext context) =>
      responsive.isMobile(context)
          ? Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
              )
          : Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
              );

  static TextStyle? offlineStatusTextStyle(BuildContext context) =>
      responsive.isMobile(context)
          ? Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LinagoraRefColors.material().tertiary[30],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingStatusContent,
              )
          : Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LinagoraRefColors.material().neutral[50],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
              );

  static TextStyle? onlineStatusTextStyle(BuildContext context) =>
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
