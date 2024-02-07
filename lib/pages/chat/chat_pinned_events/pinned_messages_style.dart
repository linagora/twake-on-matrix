import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PinnedMessagesStyle {
  static final responsiveUtils = getIt.get<ResponsiveUtils>();

  static EdgeInsets paddingListMessages(BuildContext context) =>
      EdgeInsets.symmetric(
        vertical: responsiveUtils.isMobile(context) ? 4.0 : 16.0,
      );
  static const SizedBox paddingIconAndUnpin = SizedBox(width: 4.0);
  static Widget unpinIcon({double? size}) => SvgPicture.asset(
        ImagePaths.icUnpin,
        height: size ?? unpinButtonSizeDefault,
      );

  // Web
  static const double unpinButtonHeightWeb = 56;
  static const double unpinButtonWidthWeb = 556;
  static const EdgeInsets actionBarParentPaddingWeb = EdgeInsets.all(16.0);
  static const EdgeInsets actionBarPaddingWeb = EdgeInsets.symmetric(
    horizontal: 8.0,
  );
  static const double actionBarBorderRadiusWeb = 16.0;
  static const double closeSelectionIconSizeWeb = 20.0;
  static const double unpinButtonSizeDefault = 18.0;

  // Mobile
  static const double menuHeightMobile = 80;
  static const double unpinButtonSizeMobile = 24.0;
  static const double menuActionBtnGapMobile = 4.0;

  static const double paddingAllContextMenuItem = 12;
  static const double heightContextMenuItem = 48;
}
