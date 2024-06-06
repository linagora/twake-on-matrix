import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/widgets.dart';

class ResponsiveUtils {
  static const double defaultSizeLeftMenuMobile = 375;
  static const double defaultSizeDrawer = 320;
  static const double defaultSizeMenu = 256;

  static const double heightShortest = 600;

  static const double minDesktopWidth = 1239;
  static const double minTabletWidth = 905;
  static const double minTabletLargeWidth = 900;
  static const double maxMobileWidth = 904;

  static const double bodyRadioWidth = 472;

  static const double defaultSizeBodyLayoutDesktop = 280;
  static const double heightBottomNavigation = 72;
  static const double heightBottomNavigationBar = 56;

  static const double bodyWithRightColumnRatio = 0.64;
  static const double groupDetailsMinWidth = 370;

  double getChatBodyRatio(BuildContext context) =>
      bodyRadioWidth / context.width;

  double getMinDesktopWidth(BuildContext context) =>
      ResponsiveUtils.groupDetailsMinWidth /
      (1 - ResponsiveUtils.bodyWithRightColumnRatio) /
      (1 - ResponsiveUtils().getChatBodyRatio(context));

  bool isScreenWithShortestSide(BuildContext context) =>
      context.mediaQueryShortestSide < minTabletWidth;

  double getSizeScreenWidth(BuildContext context) => context.width;

  double getSizeScreenHeight(BuildContext context) => context.height;

  double getSizeScreenShortestSide(BuildContext context) =>
      context.mediaQueryShortestSide;

  double getDeviceWidth(BuildContext context) => context.width;

  bool isMobile(BuildContext context) =>
      getDeviceWidth(context) < minTabletWidth;

  bool isTablet(BuildContext context) =>
      getDeviceWidth(context) >= minTabletWidth &&
      getDeviceWidth(context) < minDesktopWidth;

  bool isDesktop(BuildContext context) =>
      getDeviceWidth(context) >= minDesktopWidth;

  bool isTabletLarge(BuildContext context) =>
      getDeviceWidth(context) >= minTabletLargeWidth &&
      getDeviceWidth(context) < minDesktopWidth;

  bool isPortrait(BuildContext context) =>
      context.orientation == Orientation.portrait;

  bool isLandscape(BuildContext context) =>
      context.orientation == Orientation.landscape;

  bool isLandscapeMobile(BuildContext context) =>
      isScreenWithShortestSide(context) && isLandscape(context);

  bool isLandscapeTablet(BuildContext context) {
    return context.mediaQueryShortestSide >= minTabletWidth &&
        context.mediaQueryShortestSide < minDesktopWidth &&
        isLandscape(context);
  }

  bool isPortraitMobile(BuildContext context) =>
      isScreenWithShortestSide(context) && isPortrait(context);

  bool isPortraitTablet(BuildContext context) {
    return context.mediaQueryShortestSide >= minTabletWidth &&
        context.mediaQueryShortestSide < minDesktopWidth &&
        isPortrait(context);
  }

  bool isHeightShortest(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < heightShortest;
  }

  bool hasLeftMenuDrawerActive(BuildContext context) {
    if (PlatformInfos.isWeb) {
      return isMobile(context) || isTablet(context) || isTabletLarge(context);
    } else {
      return true;
    }
  }

  bool isWebDesktop(BuildContext context) =>
      PlatformInfos.isWeb && isDesktop(context);

  bool isWebNotDesktop(BuildContext context) =>
      PlatformInfos.isWeb && !isDesktop(context);

  bool isMobileOrTablet(BuildContext context) =>
      isMobile(context) || isTablet(context);

  bool landscapeTabletSupported(BuildContext context) {
    if (PlatformInfos.isWeb) {
      return isTabletLarge(context);
    } else {
      return !isLandscapeMobile(context) &&
          (isLandscapeTablet(context) ||
              isTabletLarge(context) ||
              isDesktop(context));
    }
  }

  bool isSingleColumnLayout(BuildContext context) {
    return isMobile(context);
  }
}
