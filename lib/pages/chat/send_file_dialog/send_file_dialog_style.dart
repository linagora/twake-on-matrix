import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class SendFileDialogStyle {
  static const dialogBorderRadius = 16.0;

  static const double maxDialogWidth = 480;

  static const double dialogWidthForMedia = 360;

  static const double maxDialogHeight = 620;

  static const double imageBorderRadius = 8.0;

  static const double imageSize = 328;

  static const double buttonBorderRadius = 100;

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 10.0,
  );

  static const EdgeInsets headerPadding = EdgeInsets.all(4.0);

  static InputDecoration bottomBarInputDecoration(BuildContext context) =>
      InputDecoration(
        hintText: L10n.of(context)!.enterCaption,
        hintMaxLines: 1,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.merge(
              Theme.of(context).inputDecorationTheme.hintStyle,
            )
            .copyWith(
              letterSpacing: -0.15,
              color: LinagoraRefColors.material().neutralVariant[60],
            ),
        filled: true,
        fillColor: LinagoraSysColors.material().background,
      );

  static const spaceBwInputBarAndButton = SizedBox(height: 8.0);

  static const double maxHeightFilesListView = 320;

  static const EdgeInsets paddingFilesListView = EdgeInsets.only(
    top: 4.0,
    bottom: 4.0,
    right: 4.0,
  );

  static Color? listViewBackgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static const double listViewBorderRadius = 8.0;

  static const paddingFileTile = EdgeInsets.symmetric(vertical: 4.0);

  static const double inkwellSplashBorderRadius = 8.0;

  static const EdgeInsets paddingRemoveButton = EdgeInsets.only(right: 8.0);

  static const double removeButonSize = 16.0;

  static Color? removeButtonColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.12);

  static const double paddingAllRemoveButton = 4.0;

  static TextStyle? subHeaderErrorStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LinagoraRefColors.material().error[30],
          );

  static const double errorSubHeaderWidth = 340;
}
