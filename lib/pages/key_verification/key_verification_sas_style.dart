import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class KeyVerificationSasStyle {
  const KeyVerificationSasStyle._();

  static const double mascotWidth = 180;
  static const double mascotHeight = 168;
  static const double verifiedMascotWidth = 180;
  static const double verifiedMascotHeight = 180;

  static const double spinnerSize = 68;
  static Color spinnerColor(BuildContext context) =>
      LinagoraSysColors.material().outlineVariant;

  static const EdgeInsets headingPadding = EdgeInsets.all(LinagoraSpacing.base);

  static const double emojiFontSize = 32;

  static Color get titleColor => LinagoraSysColors.material().onSurface;

  /// Figma #5C6268 — no matching token in the design system yet.
  static const Color supportingColor = Color(0xFF5C6268);

  static Color get primaryColor => LinagoraSysColors.material().primary;

  // Taller vertical padding than VerifyDeviceView's retry button.
  static const EdgeInsets filledButtonPadding = EdgeInsets.symmetric(
    horizontal: LinagoraSpacing.base * 3,
    vertical: 14,
  );
  static const double buttonRadius = 100;
  static const double gapEmojiButtons = 28;
  static const double startChattingButtonWidth = 142;

  static TextStyle? titleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(color: titleColor);

  static TextStyle? supportingStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(color: supportingColor);

  static TextStyle? textButtonStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(color: primaryColor);

  static TextStyle? filledButtonTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge?.copyWith(
        color: LinagoraSysColors.material().onPrimary,
      );

  static TextStyle recoveryKeyLabelStyle(BuildContext context) =>
      LinagoraTextTheme.material().labelSmall!.copyWith(
        color: LinagoraSysColors.material().onSurface,
      );
}
