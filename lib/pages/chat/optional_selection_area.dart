import 'package:flutter/material.dart';

class OptionalSelectionArea extends StatelessWidget {
  final Widget child;
  final bool isEnabled;

  const OptionalSelectionArea({
    super.key,
    required this.child,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return isEnabled ? SelectionArea(child: child) : child;
  }
}
