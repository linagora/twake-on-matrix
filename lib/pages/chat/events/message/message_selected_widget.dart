import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/utils/extension/event_status_custom_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class MessageSelectedWidget extends StatelessWidget {
  final Event event;
  final bool selected;
  final bool selectMode;
  final Widget child;

  const MessageSelectedWidget({
    super.key,
    required this.event,
    required this.selected,
    required this.selectMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Message.responsiveUtils.isMobile(context);
    final bool showSelectionUI =
        selectMode && (event.redacted || event.status.isAvailable);
    // In normal mode on mobile, preserve the left 8px padding but skip
    // the selection UI (checkbox + row wrapper).
    if (!showSelectionUI) {
      if (!isMobile) return child;
      return Padding(padding: const EdgeInsets.only(left: 8.0), child: child);
    }

    return Padding(
      padding: EdgeInsets.only(left: isMobile ? 8.0 : 0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            width: 20,
            child: event.redacted
                ? null
                : Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected
                        ? LinagoraSysColors.material().primary
                        : Colors.black,
                    size: 20,
                  ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
