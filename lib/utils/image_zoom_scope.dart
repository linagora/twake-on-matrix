import 'package:flutter/widgets.dart';

/// Shares the current zoom state of the inner image viewer with ancestor
/// widgets so they can stop competing for pan/drag gestures while the image is zoomed in.
class ImageZoomScope extends InheritedWidget {
  const ImageZoomScope({
    super.key,
    required this.isZoomed,
    required super.child,
  });

  final ValueNotifier<bool> isZoomed;

  static ValueNotifier<bool>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ImageZoomScope>()?.isZoomed;

  @override
  bool updateShouldNotify(ImageZoomScope oldWidget) => false;
}
