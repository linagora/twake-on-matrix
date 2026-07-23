import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class VerifyDeviceViewStyle {
  const VerifyDeviceViewStyle._();

  static const double webModalWidth = 448;
  static const double webContentWidth = 408;
  static const double webModalRadius = 16;
  static const EdgeInsets webModalPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 36,
  );
  static const List<BoxShadow> webModalShadow = [
    BoxShadow(color: Color(0x26000000), offset: Offset(0, 4), blurRadius: 4),
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 1.5),
  ];

  static const double closeButtonInset = 8;

  static const double webMascotWidth = 180;
  static const double webMascotHeight = 168.55;

  static const double mobileMascotWidth = 106;
  static const double mobileMascotHeight = 99.26;

  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(28),
  );
  static const EdgeInsets sheetContentPadding = EdgeInsets.fromLTRB(
    13,
    18,
    13,
    24,
  );
  static const EdgeInsets dragHandlePadding = EdgeInsets.symmetric(
    vertical: 16,
  );
  static const double dragHandleWidth = 32;
  static const double dragHandleHeight = 4;

  static const double gapMascotToHeading = 20;
  static const double gapTitleToSupporting = 8;
  static const double gapHeadingToOptions = 16;
  static const double gapOptionsToButton = 1;
  static const EdgeInsets headingPadding = EdgeInsets.symmetric(horizontal: 8);

  static const double settingItemHeight = 92;
  static const EdgeInsets settingItemPadding = EdgeInsets.only(
    left: 8,
    top: 16,
    bottom: 16,
  );
  static const double settingIconSize = 24;
  static const double settingGap = 8;
  static const double settingTextGap = 4;
  static const double dividerIndent = 41;

  // Light-mode fallbacks; prefer the theme-derived helpers below wherever
  // BuildContext is available.
  static const Color titleColor = Color(0xFF1C1B1F);
  static const Color supportingColor = Color(0xFF5C6268);
  static const Color subtitleColor = Color(0xFF99A0A9);
  static const Color dividerColor = Color(0x296750A4);
  static const Color buttonColor = Color(0xFF0A84FF);
  static const Color buttonTextColor = Colors.white;
  static const Color backgroundColor = Colors.white;

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 10,
  );
  static const double buttonRadius = 100;
  static const double buttonWidth = 180;

  static Color backgroundColorOf(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static Color titleColorOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color supportingColorOf(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static TextStyle? titleStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleLarge?.copyWith(color: titleColorOf(context));

  static TextStyle? supportingStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: supportingColorOf(context));

  static TextStyle? settingTitleStyle(BuildContext context) => Theme.of(context)
      .extension<LinagoraTextThemeExtension>()
      ?.bodyMedium2
      .copyWith(color: titleColorOf(context));

  static TextStyle? settingSubtitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtitleColor);

  static TextStyle? buttonTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(color: buttonTextColor);

  static Color iconColor(BuildContext context) => subtitleColor;
}
