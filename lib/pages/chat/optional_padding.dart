import 'package:flutter/material.dart';

class OptionalPadding extends StatelessWidget {
  final Widget child;
  final bool isEnabled;
  final EdgeInsetsGeometry? padding;

  const OptionalPadding({
    super.key,
    required this.child,
    required this.isEnabled,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isEnabled) {
      return Padding(padding: padding ?? EdgeInsets.zero, child: child);
    } else {
      return child;
    }
  }
}
