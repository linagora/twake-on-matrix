import 'package:flutter/material.dart';

import 'file_tile_widget_style.dart';

class MessageFileTileStyle extends FileTileWidgetStyle {
  @override
  double get iconSize => 36;

  @override
  EdgeInsets get paddingIcon => const EdgeInsets.only(right: 4);

  @override
  CrossAxisAlignment get crossAxisAlignment => CrossAxisAlignment.center;

  @override
  EdgeInsets get paddingFileTileAll =>
      const EdgeInsets.only(left: 8.0, right: 16.0, top: 4.0, bottom: 4.0);

  @override
  TextStyle? textStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        );
  }

  @override
  Widget get paddingBottomText => const SizedBox(height: 4.0);

  @override
  Widget get paddingRightIcon => const SizedBox(width: 4.0);
}
