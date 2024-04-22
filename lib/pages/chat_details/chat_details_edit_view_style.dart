import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

class ChatDetailEditViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();
  static const double fixedWidth = 360.0;

  static Offset contextMenuAlignmentOffset(BuildContext context) =>
      responsive.isMobile(context) ? const Offset(-60, 0) : const Offset(0, 0);

  static const EdgeInsets navigationAppBarPadding =
      EdgeInsets.symmetric(horizontal: 4.0);
  static const EdgeInsetsGeometry backIconPadding =
      EdgeInsets.symmetric(vertical: 8, horizontal: 4);
  static const EdgeInsetsGeometry doneIconPadding =
      EdgeInsets.symmetric(vertical: 8, horizontal: 4);

  // Avatar
  static const int thumbnailSizeWidth = 56;
  static const int thumbnailSizeHeight = 56;
  static const double avatarRadiusForWeb = 48;
  static const double avatarRadiusForMobile = 28;

  static double avatarSize(BuildContext context) => 96;
  static const double avatarFontSize = 15;
  static const EdgeInsets editAvatarPadding =
      EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0);
  static const EdgeInsets avatarPadding = EdgeInsets.all(14.0);
  static const EdgeInsets editIconPadding = EdgeInsets.all(4.0);
  static const double editIconSize = 24.0;

  // TextFields
  static const double avatarAndTextFieldsGap = 20.0;
  static const double textFieldsGap = 16.0;
  static const EdgeInsets textFieldPadding =
      EdgeInsets.symmetric(horizontal: 8.0);

  static TextStyle? textFieldLabelStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 16,
            letterSpacing: 0.4,
            color: Theme.of(context).colorScheme.onSurface,
          );

  static TextStyle? textFieldHintStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            letterSpacing: -0.15,
            color: Theme.of(context).colorScheme.outline,
          );

  static TextStyle? textFieldStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            letterSpacing: -0.15,
            color: Colors.black,
          );

  static TextStyle? textChatDetailsEditCategoryStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: 14.0,
          );

  static const double clearIconSize = 20.0;

  static const EdgeInsetsDirectional contentPadding =
      EdgeInsetsDirectional.all(16.0);

  static const EdgeInsetsDirectional editIconMaterialPadding =
      EdgeInsetsDirectional.all(8.0);
}
