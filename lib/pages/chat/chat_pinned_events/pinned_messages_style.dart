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

  static const double unpinButtonHeight = 56;
  static const double unpinButtonWidth = 556;
  static const EdgeInsets actionBarParentPadding = EdgeInsets.all(16.0);
  static const EdgeInsets actionBarPadding = EdgeInsets.symmetric(
    horizontal: 8.0,
  );
  static const double actionBarBorderRadius = 16.0;
  static const double bottomMenuHeightMobile = 56.0;
  static const double bottomMenuCloseButtonSize = 20.0;

  static Widget unpinIcon() => SvgPicture.asset(ImagePaths.icUnpin, height: 18);
}
