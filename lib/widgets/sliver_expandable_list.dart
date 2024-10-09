import 'package:fluffychat/pages/chat_list/chat_list_body_view.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:flutter/material.dart';

class SliverExpandableList extends StatefulWidget {
  final String title;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final bool enableExpand;

  const SliverExpandableList({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.enableExpand = false,
  });

  @override
  State<SliverExpandableList> createState() => _SliverExpandableListState();
}

class _SliverExpandableListState extends State<SliverExpandableList> {
  final isExpandedNotifier = ValueNotifier<bool>(true);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isExpandedNotifier,
      builder: (context, isExpanded, child) {
        return SliverList.builder(
          itemCount: (isExpanded ? widget.itemCount : 0) + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return widget.enableExpand
                  ? ExpandableTitleBuilder(
                      title: widget.title,
                      isExpanded: isExpanded,
                      onTap: isExpandedNotifier.toggle,
                    )
                  : const SizedBox();
            }
            return widget.itemBuilder(context, index - 1);
          },
        );
      },
    );
  }
}
