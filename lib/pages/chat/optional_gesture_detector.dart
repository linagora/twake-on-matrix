import 'package:flutter/material.dart';

class OptionalGestureDetector extends StatelessWidget {
  final Widget child;
  final bool isEnabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const OptionalGestureDetector({
    super.key,
    required this.child,
    required this.isEnabled,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (isEnabled) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      );
    } else {
      return child;
    }
  }
}
