import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ChatAppBarTitleStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double get avatarFontSize => 15.0.sp;

  static double get avatarSize => 40.0.w;

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
