import 'package:fluffychat/pages/chat/events/button_content.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class UnknownContent extends StatelessWidget with MessageContentMixin {
  final Event event;

  const UnknownContent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: event.fetchSenderUser(),
      builder: (context, snapshot) {
        return ButtonContent(
          title: L10n.of(context)!.userSentUnknownEvent(
            snapshot.data?.calcDisplayname() ??
                event.senderFromMemoryOrFallback.calcDisplayname(),
            event.type,
          ),
          icon: Icons.info_outlined,
          onTap: () => showEventInfo(context, event),
        );
      },
    );
  }
}
