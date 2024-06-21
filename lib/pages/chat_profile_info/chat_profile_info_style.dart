import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatProfileInfoStyle {
  static const double iconPadding = 8;
  static const double iconSize = 24;
  static const double copyIconSize = 20;

  static const double maxWidth = 416;
  static const double textSpacing = 4;

  static const double avatarFontSize = 36;
  static const double avatarSize = 96;

  static const double toolbarHeightSliverAppBar = 340.0;

  static const double indicatorWeight = 3.0;

  static BorderRadius copiableContainerBorderRadius = BorderRadius.circular(16);

  static const EdgeInsetsGeometry mainPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 16);

  static const EdgeInsetsGeometry backIconPadding =
      EdgeInsets.symmetric(vertical: 8, horizontal: 4);

  static const EdgeInsetsGeometry copiableContainerPadding =
      EdgeInsets.all(12.0);

  static const EdgeInsetsGeometry copiableContainerMargin =
      EdgeInsets.symmetric(vertical: 12);

  static const EdgeInsetsGeometry textPadding =
      EdgeInsets.symmetric(horizontal: 8);

  static const EdgeInsetsGeometry titleSharedMediaAndFilesPadding =
      EdgeInsets.only(top: 30);

  static const EdgeInsetsGeometry indicatorPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
  );

  static TextStyle? tabBarLabelStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          );

  static TextStyle? tabBarUnselectedLabelStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );

  static Decoration tabViewDecoration = BoxDecoration(
    color: LinagoraRefColors.material().primary[100],
  );
}
