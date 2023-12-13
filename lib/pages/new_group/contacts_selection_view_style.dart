import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContactsSelectionViewStyle {
  static EdgeInsetsDirectional getSelectionListPadding({
    required bool haveSelectedContact,
  }) =>
      haveSelectedContact
          ? EdgeInsetsDirectional.zero
          : EdgeInsetsDirectional.only(top: 8.0.h);

  static EdgeInsetsDirectional webActionsButtonMargin =
      EdgeInsetsDirectional.symmetric(
    vertical: 10.0.h,
    horizontal: 24.0.w,
  );

  static double webActionsButtonHeight = 72.0.h;

  static double webActionsButtonPaddingAll = 10.0.w;

  static double webActionsButtonBorder = 100.0.r;
}
