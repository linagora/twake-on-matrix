import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatInputRowStyle {
  static final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static double chatInputRowHeight = 44.0.h;
  static EdgeInsets chatInputRowPaddingMobile = EdgeInsets.only(left: 12.0.w);
  static EdgeInsets chatInputRowMargin = EdgeInsets.only(right: 8.0.w);
  static BorderRadius chatInputRowBorderRadius =
      BorderRadius.all(Radius.circular(25.r));
  static double chatInputRowPaddingBtnMobile = 12.0.w;
  static double chatInputRowMoreBtnSize = 24.0.w;

  static double sendIconBtnSize = 44.0.w;

  static EdgeInsets sendIconPadding = EdgeInsets.only(
    left: 8.0.w,
    bottom: 6.0.w,
  );
}
