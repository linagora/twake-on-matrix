import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/cupertino.dart';

class NewGroupChatInfoStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const double toolbarHeight = 56;
  static const int thumbnailSizeWidth = 56;
  static const int thumbnailSizeHeight = 56;
  static const double avatarRadiusForWeb = 48;
  static const double avatarRadiusForMobile = 28;
  static const double backIconPaddingAll = 8;

  static double profileSize(BuildContext context) =>
      responsive.isMobile(context) ? 56 : 96;

  static const EdgeInsetsDirectional groupNameTextFieldPadding =
      EdgeInsetsDirectional.only(
    start: 8,
    end: 8,
  );

  static const EdgeInsets backIconMargin = EdgeInsets.symmetric(
    vertical: 12.0,
    horizontal: 8.0,
  );

  static const EdgeInsetsDirectional padding =
      EdgeInsetsDirectional.symmetric(horizontal: 8.0);

  static const EdgeInsetsDirectional contentPadding =
      EdgeInsetsDirectional.all(16.0);

  static const EdgeInsetsDirectional profilePadding =
      EdgeInsetsDirectional.only(top: 16.0);

  static const EdgeInsetsDirectional screenPadding =
      EdgeInsetsDirectional.only(start: 8.0, bottom: 8.0, end: 4.0);

  static const EdgeInsetsDirectional topScreenPadding =
      EdgeInsetsDirectional.only(top: 8.0);
}
