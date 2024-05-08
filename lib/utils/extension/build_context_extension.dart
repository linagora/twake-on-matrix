import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef OnPopUntilDoneWithResult = void Function(dynamic result);

extension ContextExtensionss on BuildContext {
  static const String resultKeySettingRoute = 'popResult';

  /// The same of [MediaQuery.sizeOf(context)]
  Size get mediaQuerySize => MediaQuery.sizeOf(this);

  /// The same of [MediaQuery.sizeOf(context).height]
  /// Note: updates when you rezise your screen (like on a browser or
  /// desktop window)
  double get height => mediaQuerySize.height;

  /// The same of [MediaQuery.sizeOf(context).width]
  /// Note: updates when you rezise your screen (like on a browser or
  /// desktop window)
  double get width => mediaQuerySize.width;

  /// Gives you the power to get a portion of the height.
  /// Useful for responsive applications.
  ///
  /// [dividedBy] is for when you want to have a portion of the value you
  /// would get like for example: if you want a value that represents a third
  /// of the screen you can set it to 3, and you will get a third of the height
  ///
  /// [reducedBy] is a percentage value of how much of the height you want
  /// if you for example want 46% of the height, then you reduce it by 56%.
  double heightTransformer({double dividedBy = 1, double reducedBy = 0.0}) {
    return (mediaQuerySize.height -
            ((mediaQuerySize.height / 100) * reducedBy)) /
        dividedBy;
  }

  /// Gives you the power to get a portion of the width.
  /// Useful for responsive applications.
  ///
  /// [dividedBy] is for when you want to have a portion of the value you
  /// would get like for example: if you want a value that represents a third
  /// of the screen you can set it to 3, and you will get a third of the width
  ///
  /// [reducedBy] is a percentage value of how much of the width you want
  /// if you for example want 46% of the width, then you reduce it by 56%.
  double widthTransformer({double dividedBy = 1, double reducedBy = 0.0}) {
    return (mediaQuerySize.width - ((mediaQuerySize.width / 100) * reducedBy)) /
        dividedBy;
  }

  /// Divide the height proportionally by the given value
  double ratio({
    double dividedBy = 1,
    double reducedByW = 0.0,
    double reducedByH = 0.0,
  }) {
    return heightTransformer(dividedBy: dividedBy, reducedBy: reducedByH) /
        widthTransformer(dividedBy: dividedBy, reducedBy: reducedByW);
  }

  /// similar to [MediaQuery.of(context).padding]
  ThemeData get theme => Theme.of(this);

  /// Check if dark mode theme is enable
  bool get isDarkMode => (theme.brightness == Brightness.dark);

  /// give access to Theme.of(context).iconTheme.color
  Color? get iconColor => theme.iconTheme.color;

  /// similar to [MediaQuery.of(context).padding]
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// similar to [MediaQuery.of(context).padding]
  EdgeInsets get mediaQueryPadding => MediaQuery.paddingOf(this);

  /// similar to [MediaQuery.of(context).padding]
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// similar to [MediaQuery.of(context).viewPadding]
  EdgeInsets get mediaQueryViewPadding => MediaQuery.viewPaddingOf(this);

  /// similar to [MediaQuery.of(context).viewInsets]
  EdgeInsets get mediaQueryViewInsets => MediaQuery.viewInsetsOf(this);

  /// similar to [MediaQuery.of(context).orientation]
  Orientation get orientation => MediaQuery.orientationOf(this);

  /// check if device is on landscape mode
  bool get isLandscape => orientation == Orientation.landscape;

  /// check if device is on portrait mode
  bool get isPortrait => orientation == Orientation.portrait;

  /// similar to [MediaQuery.of(this).devicePixelRatio]
  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(this);

  /// get the shortestSide from screen
  double get mediaQueryShortestSide => mediaQuerySize.shortestSide;

  /// True if width be larger than 800
  bool get showNavbar => (width > 800);

  /// True if the shortestSide is smaller than 600p
  bool get isPhone => (mediaQueryShortestSide < 600);

  /// True if the shortestSide is largest than 600p
  bool get isSmallTablet => (mediaQueryShortestSide >= 600);

  /// True if the shortestSide is largest than 720p
  bool get isLargeTablet => (mediaQueryShortestSide >= 720);

  /// True if the current device is Tablet
  bool get isTablet => isSmallTablet || isLargeTablet;

  /// Returns a specific value according to the screen size
  /// if the device width is higher than or equal to 1200 return
  /// [desktop] value. if the device width is higher than  or equal to 600
  /// and less than 1200 return [tablet] value.
  /// if the device width is less than 300  return [watch] value.
  /// in other cases return [mobile] value.
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? watch,
  }) {
    final deviceWidth = mediaQuerySize.width;
    if (deviceWidth >= minDesktopWidth && desktop != null) {
      return desktop;
    } else if (deviceWidth >= minTabletWidth &&
        deviceWidth < minDesktopWidth &&
        tablet != null) {
      return tablet;
    } else if (deviceWidth < defaultMinWidth && watch != null) {
      return watch;
    } else {
      return mobile;
    }
  }

  static const double minDesktopWidth = 1239;

  static const double minTabletWidth = 905;

  static const double maxMobileWidth = 904;

  static const double defaultMinWidth = 300;

  void goChild(String path, {Object? extra}) => go(
        '${GoRouterState.of(this).uri.path}/$path',
        extra: extra,
      );

  Future<T?> pushChild<T extends Object?>(String path, {Object? extra}) =>
      push('${GoRouterState.of(this).uri.path}/$path', extra: extra);

  RelativeRect getCurrentRelativeRectOfWidget() {
    final RenderBox button = findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Navigator.of(this).overlay!.context.findRenderObject()! as RenderBox;
    final Offset offset;
    offset = Offset(0.0, button.size.height);
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(offset, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero) + offset,
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    return position;
  }

  void pushInner(String path, {Object? arguments}) {
    Navigator.of(this).pushNamed(path, arguments: arguments);
  }

  void pushInnerReplace(String path, {Object? arguments}) {
    Navigator.of(this).pushReplacementNamed(path, arguments: arguments);
  }

  void popInner() {
    Navigator.of(this).pop();
  }

  void popInnerAll() {
    Navigator.of(this).popUntil((route) => route.isFirst);
  }

  void goToRoomWithEvent(String roomId, String eventId) {
    go('/rooms/$roomId?event=$eventId');
  }

  int getCacheSize(double size) {
    return (MediaQuery.devicePixelRatioOf(this) * size).round();
  }
}
