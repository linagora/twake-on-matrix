import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class DraftChatViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double toolbarHeight(BuildContext context) =>
      responsive.isMobile(context) ? 56 : 80;

  static BoxConstraints get containerMaxWidthConstraints =>
      const BoxConstraints(maxWidth: TwakeThemes.columnWidth * 2.5);

  static double animatedContainerHeight(
    BuildContext context,
    bool isShowEmojiPicker,
  ) =>
      isShowEmojiPicker ? MediaQuery.of(context).size.height / 3 : 0;

  static int get minLinesInputBar => 1;

  static int get maxLinesInputBar => 8;

  // Bottom Bar Style
  static EdgeInsetsGeometry get bottomBarPadding =>
      const EdgeInsetsDirectional.only(start: 12.0);

  static EdgeInsetsGeometry get bottomBarMargin =>
      const EdgeInsetsDirectional.only(end: 8.0);

  static BorderRadiusGeometry get bottomBarBorderRadius =>
      const BorderRadius.all(Radius.circular(25));

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
      isInputEmpty ? 5.0 : 12.0;

  static EdgeInsets get bottomBarButtonRecordMargin =>
      const EdgeInsets.only(right: 7.0);

  static double get bottomBarButtonRecordPaddingAll => 5.0;

  static EdgeInsets get buttonAddMoreMargin =>
      const EdgeInsets.only(right: 4.0);

  static EdgeInsetsGeometry get inputWidgetPadding =>
      const EdgeInsetsDirectional.only(bottom: 8.0);

  // Empty Chat Style
  static EdgeInsetsGeometry get emptyChatParentPadding =>
      const EdgeInsets.only(left: 8.0);

  static EdgeInsetsGeometry get emptyChatChildrenPadding =>
      const EdgeInsets.only(right: 3, top: 3);
  static const double emptyChatGapWidth = 12.0;
}
