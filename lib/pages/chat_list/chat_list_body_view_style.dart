import 'package:flutter/cupertino.dart';

class ChatListBodyViewStyle {
  static const double sizeIconExpand = 24;

  static double heightIsTorBrowser(bool isTorBrowser) => isTorBrowser ? 64 : 0;

  static const EdgeInsetsDirectional paddingIconSkeletons =
      EdgeInsetsDirectional.only(
    top: 64,
  );

  static const EdgeInsetsDirectional paddingOwnProfile =
      EdgeInsetsDirectional.only(
    top: 16,
  );

  static const EdgeInsetsDirectional paddingTextStartNewChatMessage =
      EdgeInsetsDirectional.only(
    start: 32,
    end: 32,
    top: 8,
  );

  static const EdgeInsetsDirectional paddingTopExpandableTitleBuilder =
      EdgeInsetsDirectional.only(
    top: 8,
  );

  static const EdgeInsetsDirectional paddingHorizontalExpandableTitleBuilder =
      EdgeInsetsDirectional.symmetric(
    horizontal: 16,
  );

  static const EdgeInsetsDirectional paddingIconExpand =
      EdgeInsetsDirectional.all(8);
}
