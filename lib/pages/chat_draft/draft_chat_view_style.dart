import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DraftChatViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double maxInputBarWidth = 800.0.w;

  static BoxConstraints get containerMaxWidthConstraints =>
      BoxConstraints(maxWidth: (TwakeThemes.columnWidth * 2.5).w);

  static double animatedContainerHeight(
    BuildContext context,
    bool isShowEmojiPicker,
  ) =>
      (isShowEmojiPicker ? MediaQuery.of(context).size.height / 3 : 0).h;

  static int get minLinesInputBar => 1;

  static int get maxLinesInputBar => 8;

  // Bottom Bar Style
  static EdgeInsetsGeometry get bottomBarPadding =>
      EdgeInsetsDirectional.only(start: 12.0.w);

  static BorderRadiusGeometry get bottomBarBorderRadius =>
      BorderRadius.all(Radius.circular(25.r));

  static InputDecoration bottomBarInputDecoration(BuildContext context) =>
      InputDecoration(
        hintText: L10n.of(context)!.chatMessage,
        hintMaxLines: 1,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.merge(
              Theme.of(context).inputDecorationTheme.hintStyle,
            )
            .copyWith(letterSpacing: -0.15),
      );

  static double bottomBarButtonPaddingAll(bool isInputEmpty) =>
      (isInputEmpty ? 5.0 : 12.0).w;

  static EdgeInsets get bottomBarButtonRecordMargin =>
      EdgeInsets.only(right: 7.0.w);

  static double get bottomBarButtonRecordPaddingAll => 5.0.w;

  static EdgeInsets get buttonAddMoreMargin => EdgeInsets.only(right: 4.0.w);

  static EdgeInsetsGeometry get inputWidgetPadding =>
      EdgeInsetsDirectional.only(bottom: 8.0.h);

  // Empty Chat Style
  static EdgeInsetsGeometry get emptyChatParentPadding =>
      EdgeInsets.only(left: 8.0.w);

  static EdgeInsetsGeometry get emptyChatChildrenPadding =>
      EdgeInsets.only(right: 3.0.w, top: 3.0.h);
  static double emptyChatGapWidth = 12.0.w;

  static EdgeInsetsGeometry iconSendPadding =
      EdgeInsetsDirectional.only(end: 8.0.w, start: 8.0.w, bottom: 8.0.h);

  static EdgeInsetsGeometry iconLoadingPadding = EdgeInsetsDirectional.only(
    top: 8.0.h,
    bottom: 16.0.h,
    start: 16.0.w,
    end: 8.0.w,
  );

  static EdgeInsetsGeometry inputBarPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 8.0.w);
}
