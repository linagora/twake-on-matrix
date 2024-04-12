import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class TomBootstrapDialogStyle {
  static EdgeInsets paddingDialog = const EdgeInsets.symmetric(
    horizontal: 56,
  );

  static Color? barrierColor =
      PlatformInfos.isMobile ? LinagoraSysColors.material().onPrimary : null;

  static double? sizedDialogWeb = PlatformInfos.isMobile ? null : 400;

  static Decoration? decorationDialog = PlatformInfos.isMobile
      ? null
      : BoxDecoration(
          color: LinagoraSysColors.material().surface,
          borderRadius: BorderRadius.circular(24),
        );

  static EdgeInsets lottiePadding = EdgeInsets.symmetric(
    vertical: PlatformInfos.isMobile ? 16 : 24,
  );

  static double lottieSize = PlatformInfos.isMobile ? 64 : 96;
}
