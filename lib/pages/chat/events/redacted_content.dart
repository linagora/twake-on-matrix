import 'package:fluffychat/pages/chat/events/button_content.dart';
import 'package:fluffychat/pages/chat/events/message_content_mixin.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RedactedContent extends StatelessWidget with MessageContentMixin {
  final Event event;

  const RedactedContent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ButtonContent(
      title: event.calcLocalizedBodyFallback(
        MatrixLocals(L10n.of(context)!),
        withSenderNamePrefix: false,
        hideReply: true,
      ),
      icon: Icons.delete_outlined,
      onTap: () => showEventInfo(context, event),
    );
  }
}
