import 'package:flutter/material.dart';

class OptionalInkWell extends StatelessWidget {
  final Widget child;
  final bool isEnabled;
  final VoidCallback? onTap;

  const OptionalInkWell({
    super.key,
    required this.child,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isEnabled) {
      return InkWell(onTap: onTap, child: child);
    } else {
      return child;
    }
  }
}
