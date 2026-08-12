import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class TwakeLinkViewStyle {
  static ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const EdgeInsetsDirectional paddingCleanRichText =
      EdgeInsetsDirectional.only(start: 8.0, end: 8.0, top: 8.0);

  static const double previewToBodySpacing = 2.0;
}
