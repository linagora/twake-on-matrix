import 'package:flutter/widgets.dart';

class ParticipantListItemStyle {
  // Bottom Sheet
  static const Radius bottomSheetTopRadius = Radius.circular(16);
  static const Radius bottomSheetContentTopRadius = Radius.circular(16);
  static const EdgeInsets bottomSheetContentPadding = EdgeInsets.all(16);
  static const double spacerHeight = 16;

  // Bottom Sheet drag handle
  static const double dragHandleHeight = 4;
  static const double dragHandleWidth = 32;
  static BorderRadiusGeometry dragHandleBorderRadius =
      BorderRadius.circular(100);

  // Dialog
  static const double fixedDialogWidth = 448;
  static const EdgeInsets closeButtonPadding = EdgeInsets.all(16);

  // Permission batch
  static const EdgeInsets permissionBatchTextPadding = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 2,
  );
  static const EdgeInsets permissionBatchMargin =
      EdgeInsets.symmetric(horizontal: 8);
  static BorderRadiusGeometry permissionBatchRadius = BorderRadius.circular(8);
  static const double permissionBatchTextFontSize = 14;

  // Membership batch
  static const EdgeInsets membershipBatchPadding = EdgeInsets.all(4);
  static const EdgeInsets membershipBatchMargin =
      EdgeInsets.symmetric(horizontal: 8);
  static BorderRadiusGeometry membershipBatchRadius = BorderRadius.circular(8);
}
