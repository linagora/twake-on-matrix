import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/color_extension.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class FileTileWidgetStyle {
  static const paddingFileTileAll = EdgeInsets.symmetric(horizontal: 8);

  static final backgroundColor =
      LinagoraSysColors.material().surfaceTint.withOpacity(0.08);

  static BorderRadiusGeometry borderRadius = BorderRadius.circular(12);

  static const paddingIcon = EdgeInsets.only(right: 8);

  static const double iconSize = 48;

  static final fileInfoColor = LinagoraRefColors.material().tertiary[20];

  static TextStyle highlightTextStyle(BuildContext context) {
    return TextStyle(
      color: Theme.of(context).colorScheme.onBackground,
      fontWeight: FontWeight.bold,
      backgroundColor: CssColor.fromCss('gold'),
    );
  }

  static TextStyle? textStyle(BuildContext context) {
    return PlatformInfos.isWeb
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            )
        : Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            );
  }

  static TextStyle textInformationStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: FileTileWidgetStyle.fileInfoColor,
        );
  }
}
