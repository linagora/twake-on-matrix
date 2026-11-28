import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    show LinagoraDividerStyle;
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';

/// Draws the separator under a row of the chat list around its text [child]:
/// it starts at the left edge of the title and stops before the read-status
/// icon, on every row. Place it where the title column starts. The divider
/// never sizes the row: [child] must be as high as the row's content.
class ChatListRowDivider extends StatelessWidget {
  const ChatListRowDivider({
    super.key,
    required this.child,
    this.bottomInset = 4,
  });

  final Widget child;

  /// The vertical padding of the row under [child]: the line sits below it,
  /// at the bottom edge of the row.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final divider = LinagoraDividerStyle.material();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          start: 0,
          end: ChatListItemStyle.dividerEndInset,
          bottom: -bottomInset,
          height: divider.thickness,
          child: ColoredBox(color: divider.color),
        ),
      ],
    );
  }
}
