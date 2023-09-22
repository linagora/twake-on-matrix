import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

class VideoViewerDialogStyle {
  static EdgeInsetsDirectional topButtonPadding = EdgeInsetsDirectional.only(
    top: PlatformInfos.isWeb ? 0 : 16.0,
  );

  static EdgeInsets topButtonBarMargin = EdgeInsets.zero;

  static const EdgeInsets bottomPaddingVideo = EdgeInsets.only(bottom: 24.0);
}
