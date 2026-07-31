import 'package:fluffychat/pages/key_verification/key_verification_sas_style.dart';
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

  static const double spaceXs = LinagoraSpacing.base;
  static const double spaceS = LinagoraSpacing.base * 2;
  static const double spaceM = LinagoraSpacing.base * 3;

  static const double closeButtonInset = spaceXs;

  static const double webMascotWidth = 180;
  static const double webMascotHeight = 168;

  static const double mobileMascotWidth = 106;
  static const double mobileMascotHeight = 96;

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
    vertical: spaceS,
  );
  static const double dragHandleWidth = 32;
  static const double dragHandleHeight = 4;

  static const double gapMascotToSpinner = 20;
  static const double gapOptionsToButton = 1;
  static const EdgeInsets headingPadding = EdgeInsets.symmetric(
    horizontal: spaceXs,
  );

  static const double settingItemHeight = 92;
  static const EdgeInsets settingItemPadding = EdgeInsets.only(
    left: spaceXs,
    top: spaceS,
    bottom: spaceS,
  );
  static const double settingIconSize = spaceM;
  static const double settingGap = spaceXs;
  static const double settingTextGap = spaceXs / 2;

  static const double dividerIndent = 41;

  static Color get subtitleColor =>
      LinagoraRefColors.material().tertiary[30] ?? const Color(0xFF99A0A9);

  /// Figma: #6750A4 at 16% opacity ([LinagoraSysColors.surfaceTint]).
  static Color get dividerColor =>
      LinagoraSysColors.material().surfaceTint.withAlpha(0x29);

  static Color get buttonColor => LinagoraSysColors.material().primary;

  static Color get buttonTextColor => LinagoraSysColors.material().onPrimary;

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 10,
  );
  static const double buttonRadius = KeyVerificationSasStyle.buttonRadius;
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
