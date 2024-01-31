import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatListViewStyle {
  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double editIconSize = 18.0;

  static Size preferredSizeAppBar(BuildContext context) =>
      const Size.fromHeight(120);

  // Between 0 and 1, scale on actions length
  static const double slidableSizeRatio = 0.23;
  static double slidableExtentRatio(int slidablesLength) {
    return slidableSizeRatio * slidablesLength;
  }

  static const Color pinSlidableColorRaw = Color(0xFF00C853);
  static const Color readSlidableColorRaw = Color(0xFFAEAAAE);
}
