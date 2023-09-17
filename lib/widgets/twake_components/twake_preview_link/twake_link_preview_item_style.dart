import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:flutter/material.dart';

class TwakeLinkPreviewItemStyle {
  static const double radiusBorder = 20;

  static const EdgeInsetsDirectional paddingAll =
      EdgeInsetsDirectional.all(8.0);
  static const EdgeInsetsDirectional paddingWidgetNoPreview =
      EdgeInsetsDirectional.only(start: 8.0);

  static const EdgeInsetsDirectional paddingCleanRichText =
      EdgeInsetsDirectional.only(
    start: 8.0,
    end: 8.0,
    top: 8.0,
  );

  static const double messageBubbleMobileMaxHeight = 200;
  static const double messageBubbleTabletMaxHeight = 260;
  static const double messageBubbleDesktopMaxHeight = 360;

  static double heightMxcImagePreview(BuildContext context) {
    return context.responsiveValue<double>(
      desktop: messageBubbleDesktopMaxHeight,
      tablet: messageBubbleTabletMaxHeight,
      mobile: messageBubbleMobileMaxHeight,
    );
  }
}
