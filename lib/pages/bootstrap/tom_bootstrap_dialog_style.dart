import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TomBootstrapDialogStyle {
  static ResponsiveUtils responsiveUtils = ResponsiveUtils();

  static EdgeInsets paddingDialog = const EdgeInsets.symmetric(horizontal: 56);

  static Color? barrierColor(BuildContext context) =>
      responsiveUtils.isMobile(context)
      ? LinagoraSysColors.material().onPrimary
      : Colors.transparent;

  static double? sizedDialogWeb = PlatformInfos.isMobile ? null : 400;

  static EdgeInsets lottiePadding = EdgeInsets.symmetric(
    vertical: PlatformInfos.isMobile ? 16 : 24,
  );

  static double lottieSize = PlatformInfos.isMobile ? 64 : 96;
}
