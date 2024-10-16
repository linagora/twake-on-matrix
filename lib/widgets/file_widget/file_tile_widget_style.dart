import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/color_extension.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class FileTileWidgetStyle {
  const FileTileWidgetStyle();

  EdgeInsets get paddingFileTileAll =>
      const EdgeInsets.only(left: 8.0, right: 16.0);

  Color backgroundColor(BuildContext context, {bool ownMessage = false}) =>
      ownMessage
          ? LinagoraSysColors.material().primaryContainer
          : LinagoraSysColors.material().onSurface.withOpacity(0.08);

  BorderRadiusGeometry get borderRadius => BorderRadius.circular(8.0);

  EdgeInsets get paddingIcon => const EdgeInsets.only(right: 8);

  CrossAxisAlignment get crossAxisAlignment => CrossAxisAlignment.start;

  double get iconSize => 48;

  double get imageSize => 40;

  Color? get fileInfoColor => LinagoraRefColors.material().tertiary[20];

  TextStyle highlightTextStyle(BuildContext context) {
    return TextStyle(
      // TODO: change to colorSurface when its approved
      // ignore: deprecated_member_use
      color: Theme.of(context).colorScheme.onBackground,
      fontWeight: FontWeight.bold,
      backgroundColor: CssColor.fromCss('gold'),
    );
  }

  TextStyle? textStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        );
  }

  TextStyle textInformationStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: fileInfoColor,
        );
  }

  EdgeInsets get imagePadding => const EdgeInsets.all(4.0);

  Widget get paddingBottomText => const SizedBox(height: 0.0);

  Widget get paddingRightIcon => const SizedBox(width: 8.0);
}
