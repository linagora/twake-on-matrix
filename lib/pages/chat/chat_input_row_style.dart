import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatInputRowStyle {
  static final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double chatInputRowWidth = 52.0;
  static const double chatInputRowHeight = 40.0;
  static const EdgeInsets chatInputRowPaddingMobile =
      EdgeInsets.only(left: 8.0);
  static const BorderRadius chatInputRowBorderRadius =
      BorderRadius.all(Radius.circular(25));
  static const double chatInputRowPaddingBtnWeb = 10.0;
  static const EdgeInsets chatInputRowMoreBtnMarginMobile =
      EdgeInsets.only(right: 4.0);
  static const double chatInputRowMoreBtnSize = 24.0;
  static const EdgeInsets chatInputRowBtnMarginWeb = EdgeInsets.all(12.0);

  static const double sendIconBtnSize = 44.0;

  static const EdgeInsets sendIconPadding = EdgeInsets.only(
    left: 8,
  );

  static EdgeInsetsDirectional contentPadding(BuildContext context) =>
      EdgeInsetsDirectional.only(
        top: responsiveUtils.isMobile(context) ? 7 : 10,
        bottom: responsiveUtils.isMobile(context) ? 7 : 10,
      );

  static const double inputComposerOpacity = 0.38;
}
