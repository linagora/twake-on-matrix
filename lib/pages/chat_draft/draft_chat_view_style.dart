import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/chat_input_row_style.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class DraftChatViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static BoxConstraints get containerMaxWidthConstraints =>
      const BoxConstraints(maxWidth: TwakeThemes.columnWidth * 2.5);

  static int get minLinesInputBar => 1;

  static int get maxLinesInputBar => 8;

  static InputDecoration bottomBarInputDecoration(BuildContext context) =>
      InputDecoration(
        hintText: L10n.of(context)!.message,
        isDense: true,
        hintMaxLines: 1,
        contentPadding: ChatInputRowStyle.contentPadding(context),
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: responsive.isMobile(context)
                  ? LinagoraRefColors.material().tertiary[50]
                  : LinagoraRefColors.material().tertiary[30],
              fontFamily: 'Inter',
            ),
      );

  static double bottomBarInputPadding(BuildContext context) =>
      responsive.isMobile(context) ? 8.0 : 8.0;

  static EdgeInsetsGeometry get emptyChatChildrenPadding =>
      const EdgeInsetsDirectional.only(
        end: 8,
      );
  static const double emptyChatGapWidth = 12.0;

  static const EdgeInsetsGeometry iconSendPadding =
      EdgeInsetsDirectional.only(end: 8.0, start: 8, bottom: 8);
}
