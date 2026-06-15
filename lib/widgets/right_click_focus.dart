import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Gives [focusNode] focus when its subtree receives a secondary (right) mouse
/// button press, on web only.
///
/// On web, right click is handled by the native browser context menu. Unlike a
/// left click which focuses the field through its `onTap`.
class RightClickFocus extends StatelessWidget {
  const RightClickFocus({super.key, required this.child, this.focusNode});

  final Widget child;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final node = focusNode;
    if (node == null || !PlatformInfos.isWeb) return child;
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          node.requestFocus();
        }
      },
      child: child,
    );
  }
}
