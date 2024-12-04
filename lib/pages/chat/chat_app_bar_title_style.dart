import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatAppBarTitleStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static Color get currentlyActiveColor => const Color(0xFF5AD439);

  static Color get currentlyInactiveColor => const Color(0xFF818C99);

  static double get avatarFontSize => 15.0;

  static double avatarSize(BuildContext context) =>
      responsive.isMobile(context) ? 40.0 : 40.0;

  static double get statusSize => 15;

  static Color get statusBorderColor => Colors.white;

  static double get statusBorderSize => 2;

  static double get letterSpacingRoomName => 0.15;

  static double get letterSpacingStatusContent => 0.5;

  static TextStyle? appBarTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
          );

  static TextStyle? offlineStatusTextStyle(BuildContext context) =>
      responsive.isMobile(context)
          ? Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LinagoraRefColors.material().tertiary[30],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingStatusContent,
                fontFamily: 'Inter',
              )
          : Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LinagoraRefColors.material().neutral[50],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
                fontFamily: 'Inter',
              );

  static TextStyle? onlineStatusTextStyle(BuildContext context) =>
      responsive.isMobile(context)
          ? Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LinagoraRefColors.material().secondary[40],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingStatusContent,
              )
          : Theme.of(context).textTheme.bodySmall?.copyWith(
                color: LinagoraRefColors.material().secondary[40],
                letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName,
              );
  static const avatarPadding = EdgeInsetsDirectional.only(
    end: 8,
  );
}
