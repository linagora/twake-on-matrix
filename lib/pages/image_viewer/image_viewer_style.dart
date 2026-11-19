import 'package:twake_chat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

class ImageViewerStyle {
  static const double minScaleInteractiveViewer = 1.0;
  static const double maxScaleInteractiveViewer = 10.0;
  static double? appBarHeight = PlatformInfos.isDesktop ? 56 : null;
  static EdgeInsetsGeometry paddingTopAppBar = EdgeInsetsDirectional.only(
    top: PlatformInfos.isDesktop ? 0 : 56,
  );
}
