import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class KeyVerificationSasStyle {
  const KeyVerificationSasStyle._();

  static const double mascotWidth = 180;
  static const double mascotHeight = 168.55;
  static const double verifiedMascotWidth = 180;
  static const double verifiedMascotHeight = 179.3;

  static const double spinnerSize = 68;
  static Color spinnerColor(BuildContext context) =>
      LinagoraSysColors.material().outlineVariant;

  static const double gapMascotToSpinner = 19;
  static const double gapSpinnerToHeading = 8;
  static const double gapMascotToHeading = 19;
  static const double gapTitleToSupporting = 8;
  static const EdgeInsets headingPadding = EdgeInsets.all(8);

  static const double emojiTileSize = 50;
  static const double emojiFontSize = 32;
  static const double emojiRadius = 13.009;

  static const Color titleColor = Color(0xFF1C1B1F);
  static const Color supportingColor = Color(0xFF5C6268);
  static const Color primaryColor = Color(0xFF0A84FF);

  // Taller vertical padding than VerifyDeviceView's retry button.
  static const EdgeInsets filledButtonPadding = EdgeInsets.symmetric(
    horizontal: 24,
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
      Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white);

  static TextStyle recoveryKeyLabelStyle(BuildContext context) =>
      LinagoraTextTheme.material().labelSmall!.copyWith(
        color: LinagoraSysColors.material().onSurface,
      );
}
