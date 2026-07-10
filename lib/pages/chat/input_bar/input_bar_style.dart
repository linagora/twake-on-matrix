import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';

class InputBarStyle {
  static const double suggestionAvatarSize = 30;

  static const double suggestionAvatarFontSize = 15;

  static const double suggestionSize = 50;

  static const double suggestionBorderRadius = 12.0;

  static const double suggestionListPadding = 8.0;

  static TextStyle getTypeAheadTextStyle(BuildContext context) =>
      Theme.of(
        context,
      ).extension<LinagoraTextThemeExtension>()!.bodyMedium3.copyWith(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white,
      );

  static const double suggestionTileAvatarTextGap = 8.0;
}
