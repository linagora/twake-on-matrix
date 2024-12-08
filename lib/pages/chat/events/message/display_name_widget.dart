import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class DisplayNameWidget extends StatelessWidget {
  const DisplayNameWidget({
    super.key,
    required this.event,
  });

  final Event event;

  static const int maxCharactersDisplayNameBubble = 68;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: event.fetchSenderUser(),
      builder: (context, snapshot) {
        final displayName = snapshot.data?.calcDisplayname() ??
            event.senderFromMemoryOrFallback.calcDisplayname();
        return Padding(
          padding: MessageStyle.paddingDisplayName(event),
          child: Text(
            displayName.shortenDisplayName(
              maxCharacters: maxCharactersDisplayNameBubble,
            ),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: 'Inter',
                  color: LinagoraSysColors.material().secondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.clip,
          ),
        );
      },
    );
  }
}
