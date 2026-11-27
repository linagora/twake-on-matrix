import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ReplyContentStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();
  static const double fontSizeDisplayContent = AppConfig.messageFontSize * 0.88;
  static const double replyContentSize = fontSizeDisplayContent * 2;

  static const EdgeInsets replyParentContainerPadding = EdgeInsets.only(
    left: 4,
    right: 8.0,
    top: 8.0,
    bottom: 8.0,
  );

  static BoxDecoration replyParentContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: LinagoraSysColors.material().onSurface.withOpacity(0.08),
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
  static const BorderRadius previewedImageBorderRadius = BorderRadius.all(
    Radius.circular(4),
  );
  static const double previewedImagePlaceholderPadding = 4.0;

  static TextStyle? displayNameTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle? replyBodyTextStyle(BuildContext context) {
    return Theme.of(
      context,
    ).extension<LinagoraTextThemeExtension>()!.bodyMedium4.copyWith(
      color: LinagoraRefColors.material().neutral[50],
      overflow: TextOverflow.ellipsis,
    );
  }

  /// How far a message bubble covers the bubble quoted above it.
  static const double quoteOverlap = 12;

  /// Width of the page-coloured ring that parts the two bubbles.
  static const double quoteRingWidth = 2;

  static const double quoteCaptionIconSize = 14;

  static const EdgeInsets quoteCaptionPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 4,
  );

  static const EdgeInsets quoteBubblePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  static BoxDecoration get quoteBubbleDecoration => BoxDecoration(
    // Opaque, or the wallpaper shows through behind the quoted text
    color: Color.alphaBlend(
      LinagoraSysColors.material().onSurface.withValues(alpha: 0.06),
      LinagoraSysColors.material().surface,
    ),
    borderRadius: BorderRadius.circular(16),
  );

  static TextStyle? quoteCaptionTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall?.copyWith(
        color: LinagoraRefColors.material().neutral[50],
      );

  static const double replyContainerHeight = 60;
}
