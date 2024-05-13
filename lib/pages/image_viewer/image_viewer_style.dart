import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

class ImageViewerStyle {
  static const double minScaleInteractiveViewer = 1.0;
  static const double maxScaleInteractiveViewer = 10.0;
  static double? appBarHeight = PlatformInfos.isWebOrDesktop ? 56 : null;
  static EdgeInsetsGeometry paddingTopAppBar = EdgeInsetsDirectional.only(
    top: PlatformInfos.isWebOrDesktop ? 0 : 56,
  );
}
