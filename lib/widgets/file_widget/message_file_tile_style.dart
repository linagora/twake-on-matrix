import 'package:flutter/material.dart';

import 'file_tile_widget_style.dart';

class MessageFileTileStyle extends FileTileWidgetStyle {
  const MessageFileTileStyle();

  @override
  double get iconSize => 40;

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
  Widget get paddingBottomText => const SizedBox(height: 8.0);

  @override
  Widget get paddingRightIcon => const SizedBox(width: 4.0);

  EdgeInsets get paddingDownloadFileIcon => const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 4.0,
      );

  double get strokeWidthLoading => 2;

  double get cancelButtonSize => 24;

  double get iconSizeDownload => 24;

  double get circularProgressLoadingSize => 32;

  double get downloadIconSize => 28;

  EdgeInsets get marginDownloadIcon => const EdgeInsets.all(4);

  Color iconBackgroundColor({
    required bool hasError,
    required BuildContext context,
  }) =>
      hasError
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary;
}
