import 'package:flutter/widgets.dart';
import 'package:twake_chat/widgets/twake_components/filter_pills_style.dart';

class RoomListFilterStyle {
  static const double height = FilterPillsStyle.touchTargetHeight;
  static const double arrowSize = 24;
  static const double scrollStep = 160;
  static const Duration scrollDuration = Duration(milliseconds: 200);
  static const double menuIconSize = 16;
  static const double pillGap = 4;

  static const EdgeInsets listPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsetsDirectional chipMargin = EdgeInsetsDirectional.only(
    end: 8,
  );
}
