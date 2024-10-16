import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ReplyContentStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();
  static const double fontSizeDisplayName = AppConfig.messageFontSize * 0.76;
  static const double fontSizeDisplayContent = AppConfig.messageFontSize * 0.88;
  static const double replyContentSize = fontSizeDisplayContent * 2;

  static const EdgeInsets replyParentContainerPadding = EdgeInsets.only(
    left: 4,
    right: 8.0,
    top: 8.0,
    bottom: 8.0,
  );

  static BoxDecoration replyParentContainerDecoration(
    BuildContext context,
    bool ownMessage,
  ) {
    return BoxDecoration(
      color: ownMessage
          ? LinagoraSysColors.material().primaryContainer
          : LinagoraSysColors.material().onSurface.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8.0),
    );
  }

  static const double prefixBarWidth = 3.0;
  static const double prefixBarVerticalPadding = 4.0;
  static BoxDecoration prefixBarDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      color: Theme.of(context).colorScheme.primary,
    );
  }

  static const double contentSpacing = 6.0;
  static const BorderRadius previewedImageBorderRadius =
      BorderRadius.all(Radius.circular(4));
  static const double previewedImagePlaceholderPadding = 4.0;

  static TextStyle? displayNameTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: fontSizeDisplayName,
        );
  }

  static TextStyle? replyBodyTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: LinagoraRefColors.material().neutral[50],
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
          fontSize: fontSizeDisplayContent,
        );
  }

  static EdgeInsetsDirectional get marginReplyContent =>
      EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 4.0 * AppConfig.bubbleSizeFactor,
      );

  static const double replyContainerHeight = 60;
}
