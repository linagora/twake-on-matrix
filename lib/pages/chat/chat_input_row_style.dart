import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatInputRowStyle {
  static final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static const double chatInputRowWidth = 52.0;
  static const double chatInputRowHeightWeb = 56.0;
  static const double chatInputRowHeightMobile = 48.0;
  static double chatInputRowHeight(BuildContext context) =>
      responsiveUtils.isMobileOrTablet(context)
          ? ChatInputRowStyle.chatInputRowHeightMobile
          : ChatInputRowStyle.chatInputRowHeightWeb;
  static const EdgeInsets chatInputRowPaddingMobile =
      EdgeInsets.only(left: 12.0);
  static const EdgeInsets chatInputRowMargin = EdgeInsets.only(right: 8.0);
  static const BorderRadius chatInputRowBorderRadius =
      BorderRadius.all(Radius.circular(25));
  static const double chatInputRowPaddingBtnMobile = 12.0;
  static const EdgeInsets chatInputRowMoreBtnMarginMobile =
      EdgeInsets.only(right: 4.0);
  static const double chatInputRowMoreBtnSize = 24.0;
  static const EdgeInsets chatInputRowBtnMarginWeb = EdgeInsets.all(12.0);

  static const double sendIconBtnSizeMobile = 34.0;
  static const double sendIconBtnSizeWeb = 48.0;
  static double sendButtonSize(BuildContext context) =>
      responsiveUtils.isMobileOrTablet(context)
          ? ChatInputRowStyle.sendIconBtnSizeMobile
          : ChatInputRowStyle.sendIconBtnSizeWeb;
  static double sendButtonPaddingAll(BuildContext context) =>
      responsiveUtils.isMobileOrTablet(context) ? 0.0 : 8.0;
}
