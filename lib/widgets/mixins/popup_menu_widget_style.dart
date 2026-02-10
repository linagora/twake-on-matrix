import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class PopupMenuWidgetStyle {
  // Context Menu
  static Color? defaultMenuColor(BuildContext context) {
    return LinagoraRefColors.material().primary[100];
  }

  static const double menuElevation = 2.0;
  static const double menuBorderRadius = 20.0;
  static const double menuMaxWidth = 305.0;
  static const double dividerHeight = 0.5;
  static const double dividerThickness = 1.0;

  static Color? defaultDividerColor(BuildContext context) {
    return LinagoraStateLayer(
      LinagoraSysColors.material().surfaceTint,
    ).opacityLayer3;
  }

  // Context Menu Items
  static TextStyle? defaultItemTextStyle(BuildContext context) {
    return context.textTheme.bodyMedium!.copyWith(
      color: LinagoraRefColors.material().neutral[30],
    );
  }

  static Color? defaultItemColorIcon(BuildContext context) {
    return LinagoraRefColors.material().neutral[30];
  }

  static const double defaultItemIconSize = 24.0;
  static const EdgeInsets defaultItemPadding = EdgeInsets.symmetric(
    vertical: 11.0,
    horizontal: 16.0,
  );
  static const double defaultItemHeight = 48.0;
  static const double defaultItemElementsGap = 12.0;
}
