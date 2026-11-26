import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    show LinagoraDividerStyle;
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';

/// Draws the separator under a row of the chat list around its text [child]:
/// it starts at the left edge of the title and stops before the read-status
/// icon, on every row. Place it where the title column starts.
class ChatListRowDivider extends StatelessWidget {
  const ChatListRowDivider({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final divider = LinagoraDividerStyle.material();
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Center(child: child),
        PositionedDirectional(
          start: 0,
          end: ChatListItemStyle.dividerEndInset,
          bottom: -ChatListItemStyle.paddingBody.bottom,
          height: divider.thickness,
          child: ColoredBox(color: divider.color),
        ),
      ],
    );
  }
}
