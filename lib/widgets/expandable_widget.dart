import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ExpandableWidget extends StatefulWidget {
  final Widget parentWidget;
  final Widget? childWidget;
  final bool enableExpand;
  final bool isExpanded;
  final void Function()? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final EdgeInsets? dividerPadding;

  const ExpandableWidget({
    super.key,
    required this.parentWidget,
    this.childWidget,
    this.enableExpand = true,
    this.isExpanded = true,
    this.onTap,
    this.padding,
    this.margin,
    this.dividerPadding,
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
  void didUpdateWidget(covariant ExpandableWidget oldWidget) {
    if (oldWidget.isExpanded != widget.isExpanded) {
      isExpandedNotifier.value = widget.isExpanded;
    }
    super.didUpdateWidget(oldWidget);
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
                if (!widget.enableExpand) return;
                isExpandedNotifier.toggle();
              },
              child: Container(
                padding:
                    widget.padding ??
                    const EdgeInsets.symmetric(
                      vertical: 13.0,
                      horizontal: 16.0,
                    ),
                margin: widget.margin,
                child: widget.parentWidget,
              ),
            ),
            if (isExpanded) child!,
            Padding(
              padding: widget.dividerPadding ?? EdgeInsets.zero,
              child: Divider(
                color: LinagoraStateLayer(
                  LinagoraSysColors.material().surfaceTint,
                ).opacityLayer3,
                height: 1,
                thickness: 1,
              ),
            ),
          ],
        );
      },
      child: widget.childWidget ?? const SizedBox.shrink(),
    );
  }
}
