import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SendFileDialogStyle {
  static const dialogBorderRadius = 16.0;

  static const double dialogWidth = 360;

  static const double maxDialogHeight = 560;

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
            .copyWith(letterSpacing: -0.15),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceVariant,
      );

  static const spaceBwInputBarAndButton = SizedBox(height: 8.0);

  static const double maxHeightFilesListView = 320;

  static const EdgeInsets paddingFilesListView = EdgeInsets.only(
    top: 8.0,
  );

  static Color? listViewBackgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  static const double listViewBorderRadius = 8.0;

  static const paddingFileTile = EdgeInsets.only(bottom: 8.0);
}
