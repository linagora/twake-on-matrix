import 'package:flutter/material.dart';

class OptionalSelectionArea extends StatefulWidget {
  final Widget child;
  final bool isEnabled;

  const OptionalSelectionArea({
    super.key,
    required this.child,
    required this.isEnabled,
  });

  @override
  State<OptionalSelectionArea> createState() => _OptionalSelectionAreaState();
}

class _OptionalSelectionAreaState extends State<OptionalSelectionArea> {
  final _bucket = PageStorageBucket();
  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: _bucket,
      child: widget.isEnabled
          ? SelectionArea(child: widget.child)
          : widget.child,
    );
  }
}
