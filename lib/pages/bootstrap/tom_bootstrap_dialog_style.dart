import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

class TomBootstrapDialogStyle {
  static EdgeInsets paddingDialog = const EdgeInsets.symmetric(
    horizontal: 56,
  );

  static Color? barrierColor = Colors.transparent;

  static double? sizedDialogWeb = PlatformInfos.isMobile ? null : 400;

  static EdgeInsets lottiePadding = EdgeInsets.symmetric(
    vertical: PlatformInfos.isMobile ? 16 : 24,
  );

  static double lottieSize = PlatformInfos.isMobile ? 64 : 96;
}
