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
    return Container(
      padding: EdgeInsets.only(
        left: Message.responsiveUtils.isMobile(context) ? 8.0 : 0,
      ),
      color: Theme.of(context).primaryColor.withAlpha(0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (selectMode && event.redacted)
            const SizedBox(width: 20)
          else if (selectMode && event.status.isAvailable)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? LinagoraSysColors.material().primary
                    : Colors.black,
                size: 20,
              ),
            ),
          Expanded(
            flex: 9,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
