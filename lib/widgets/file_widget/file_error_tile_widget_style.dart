import 'package:fluffychat/widgets/file_widget/file_tile_widget_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class FileErrorTileWidgetStyle extends FileTileWidgetStyle {
  @override
  Color? get fileInfoColor => LinagoraSysColors.material().error;

  @override
  TextStyle textInformationStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: fileInfoColor,
        );
  }

  @override
  TextStyle? textStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.error,
        );
  }
}
