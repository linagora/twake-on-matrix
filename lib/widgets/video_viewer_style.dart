import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

class VideoViewerStyle {
  static EdgeInsets topButtonBarMargin(context) =>
      EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top);

  static const EdgeInsets bottomPaddingVideo = EdgeInsets.only(bottom: 24.0);

  static double seekBarHeight =
      (PlatformInfos.isDesktop && PlatformInfos.isWeb) ? 2.0 : 6.0;

  static EdgeInsets bottomBarMargin(BuildContext context) => EdgeInsets.only(
        bottom: 8.0 + MediaQuery.of(context).viewPadding.bottom,
      );

  static EdgeInsets backButtonMargin(context) => PlatformInfos.isWeb
      ? const EdgeInsets.only(top: 8.0, left: 16.0)
      : EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top);

  static const Duration controlsHoverDuration = Duration(seconds: 5);
}
