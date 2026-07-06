import 'package:fluffychat/utils/custom_dismissable.dart';
import 'package:fluffychat/utils/image_zoom_scope.dart';
import 'package:fluffychat/utils/pinch_detector.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';

/// Wraps [itemBuilder] with a swipe-to-dismiss gesture, disabled while the image
/// is zoomed in or a pinch is in progress so those gestures move or zoom the
/// image instead of closing the viewer.
class DismissibleMediaView extends StatefulWidget {
  const DismissibleMediaView({super.key, required this.itemBuilder});

  final Widget itemBuilder;

  @override
  State<DismissibleMediaView> createState() => _DismissibleMediaViewState();
}

class _DismissibleMediaViewState extends State<DismissibleMediaView> {
  final ValueNotifier<bool> _isZoomed = ValueNotifier<bool>(false);
  bool _pinching = false;

  @override
  void dispose() {
    _isZoomed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PinchDetector(
      onPinchChanged: (pinching) => setState(() => _pinching = pinching),
      child: ImageZoomScope(
        isZoomed: _isZoomed,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isZoomed,
          child: widget.itemBuilder,
          builder: (context, isZoomed, child) {
            return CustomDismissible(
              onDismissed: () => Navigator.of(context).pop(),
              enabled: !isZoomed && !_pinching && !PlatformInfos.isWeb,
              child: child!,
            );
          },
        ),
      ),
    );
  }
}
