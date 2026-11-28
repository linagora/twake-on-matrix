import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class DefaultTouchSlop extends StatelessWidget {
  // Android's default touch slop, which the Android engine already reports.
  static const double touchSlop = 8;

  final Widget child;

  const DefaultTouchSlop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // iOS reports none, so a flick shorter than kTouchSlop (18) taps the row
    // under the finger instead of scrolling.
    if (mediaQuery.gestureSettings.touchSlop != null) return child;
    return MediaQuery(
      data: mediaQuery.copyWith(
        gestureSettings: const DeviceGestureSettings(touchSlop: touchSlop),
      ),
      child: child,
    );
  }
}
