import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';

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

  /// Figma "Bubble message / Files": body/medium on mobile, body/medium2
  /// (semibold) on desktop.
  @override
  TextStyle? textStyle(BuildContext context) {
    final theme = Theme.of(context);
    final themeExtension = theme.extension<LinagoraTextThemeExtension>()!;
    final style = getIt.get<ResponsiveUtils>().isMobile(context)
        ? theme.textTheme.bodyMedium
        : themeExtension.bodyMedium2;
    return style?.copyWith(color: Theme.of(context).colorScheme.onSurface);
  }

  @override
  Widget get paddingBottomText => const SizedBox(height: 8.0);

  @override
  Widget get paddingRightIcon => const SizedBox(width: 4.0);

  EdgeInsets get paddingDownloadFileIcon =>
      const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0);

  double get strokeWidthLoading => 2;

  double get cancelButtonSize => 24;

  double get iconSizeDownload => 24;

  double get circularProgressLoadingSize => 32;

  double get downloadIconSize => 28;

  EdgeInsets get marginDownloadIcon => const EdgeInsets.all(4);

  Color iconBackgroundColor({
    required bool hasError,
    required BuildContext context,
  }) => hasError
      ? Theme.of(context).colorScheme.error
      : Theme.of(context).colorScheme.primary;
}
