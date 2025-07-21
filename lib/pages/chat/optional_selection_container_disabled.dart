import 'package:flutter/material.dart';

class OptionalSelectionContainerDisabled extends StatelessWidget {
  final Widget child;
  final bool isEnabled;

  const OptionalSelectionContainerDisabled({
    super.key,
    required this.child,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return isEnabled ? SelectionContainer.disabled(child: child) : child;
  }
}
