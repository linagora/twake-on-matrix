import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ExpandableWidget extends StatefulWidget {
  final Widget parentWidget;
  final Widget? childWidget;
  final bool enableExpand;
  final bool isExpanded;
  final void Function()? onTap;
  final EdgeInsets padding;

  const ExpandableWidget({
    super.key,
    required this.parentWidget,
    this.childWidget,
    this.enableExpand = true,
    this.isExpanded = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      vertical: 16.0,
    ),
  });

  @override
  State<ExpandableWidget> createState() => _ExpandableWidgetState();
}

class _ExpandableWidgetState extends State<ExpandableWidget> {
  final isExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    isExpandedNotifier.value = widget.isExpanded;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isExpandedNotifier,
      builder: (context, isExpanded, child) {
        return Column(
          children: [
            TwakeInkWell(
              onTap: () {
                widget.onTap?.call();
                isExpandedNotifier.toggle();
              },
              child: Padding(
                padding: widget.padding,
                child: widget.parentWidget,
              ),
            ),
            if (widget.enableExpand) child!,
          ],
        );
      },
      child: widget.childWidget ?? const SizedBox.shrink(),
    );
  }
}
