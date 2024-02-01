import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class DraftChatViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static BoxConstraints get containerMaxWidthConstraints =>
      const BoxConstraints(maxWidth: TwakeThemes.columnWidth * 2.5);

  static int get minLinesInputBar => 1;
  static int get maxLinesInputBar => 8;

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

  static const double bottomBarInputPadding = 8.0;

  // Empty Chat Style
  static EdgeInsetsGeometry get emptyChatParentPadding =>
      const EdgeInsets.only(left: 8.0);

  static EdgeInsetsGeometry get emptyChatChildrenPadding =>
      const EdgeInsets.only(right: 3, top: 3);
  static const double emptyChatGapWidth = 12.0;

  static const EdgeInsetsGeometry iconSendPadding =
      EdgeInsetsDirectional.only(end: 8.0, start: 8, bottom: 8);
}
