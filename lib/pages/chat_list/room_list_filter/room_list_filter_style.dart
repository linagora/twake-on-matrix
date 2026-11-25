import 'package:flutter/widgets.dart';

class RoomListFilterStyle {
  static const double height = 44;
  static const double arrowSize = 24;
  static const double chipMaxWidth = 240;
  static const double scrollStep = 160;
  static const Duration scrollDuration = Duration(milliseconds: 200);
  static const double colorDotRadius = 4;
  static const double menuIconSize = 16;
  static const double pillGap = 4;

  static const double pillHeight = 32;
  static const double pillsTopPadding = 4;
  static const double pillsBottomPadding = 4;
  static const double pillsHeight =
      pillsTopPadding + pillHeight + pillsBottomPadding;
  static const double pillsSpacing = 8;
  static const double pillDotGap = 6;
  static const double pillsFadeWidth = 24;
  static const double pillsMaxTextScale = 1.3;
  static const EdgeInsets pillsPadding = EdgeInsets.fromLTRB(
    16,
    pillsTopPadding,
    16,
    pillsBottomPadding,
  );
  static const EdgeInsets pillContentPadding = EdgeInsets.symmetric(
    horizontal: 14,
  );

  static const EdgeInsetsDirectional chipMargin = EdgeInsetsDirectional.only(
    end: 4,
    top: 4,
    bottom: 4,
  );
  static const EdgeInsetsDirectional chipLeadingPadding =
      EdgeInsetsDirectional.only(end: 6);
}
