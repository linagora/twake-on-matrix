import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class AssignRolesMemberPickerStyle {
  static const double avatarChipSize = 28;

  static const EdgeInsetsDirectional chipMargin = EdgeInsetsDirectional.only(
    top: 8,
  );

  static const EdgeInsetsDirectional textChipPadding =
      EdgeInsetsDirectional.only(end: 12.0, top: 4.0, bottom: 4.0);

  static const double fixedDialogWidth = 448;
  static const double fixedDialogHeight = 725;
  static const EdgeInsets closeButtonPadding = EdgeInsets.all(16);

  static TextStyle? roleNameTextStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(color: LinagoraRefColors.material().tertiary[30]);
}
