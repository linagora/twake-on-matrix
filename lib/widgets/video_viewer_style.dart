import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideoViewerStyle {
  static EdgeInsets topButtonBarMargin(context) =>
      EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top);

  static EdgeInsets bottomPaddingVideo = EdgeInsets.only(bottom: 24.0.h);

  static double seekBarHeight =
      ((PlatformInfos.isDesktop && PlatformInfos.isWeb) ? 2.0 : 6.0).h;

  static EdgeInsets bottomBarMargin(BuildContext context) => EdgeInsets.only(
        bottom: (8.0 + MediaQuery.of(context).viewPadding.bottom).h,
      );

  static EdgeInsets backButtonMargin(context) => PlatformInfos.isWeb
      ? EdgeInsets.only(top: 8.0.h, left: 16.0.w)
      : EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top);
}
