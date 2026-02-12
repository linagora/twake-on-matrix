import 'package:flutter/material.dart';

class OptionalStack extends StatelessWidget {
  final List<Widget> children;
  final bool isEnabled;
  final AlignmentGeometry alignment;

  const OptionalStack({
    super.key,
    required this.children,
    required this.isEnabled,
    this.alignment = AlignmentDirectional.topStart,
  });

  @override
  Widget build(BuildContext context) {
    if (isEnabled) {
      return Stack(alignment: alignment, children: children);
    } else {
      return children.first;
    }
  }
}
