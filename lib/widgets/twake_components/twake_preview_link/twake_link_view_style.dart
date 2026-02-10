import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class TwakeLinkViewStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const EdgeInsetsDirectional paddingMessageBody =
      EdgeInsetsDirectional.symmetric(horizontal: 8.0);

  static const EdgeInsetsDirectional paddingCleanRichText =
      EdgeInsetsDirectional.only(start: 8.0, end: 8.0, top: 8.0);

  static const double previewToBodySpacing = 2.0;
  static const previewItemPadding = EdgeInsetsDirectional.symmetric(
    horizontal: 8.0,
  );
}
