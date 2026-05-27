import 'dart:async';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/video_call_message.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

mixin StartVideoCallMixin {
  void startVideoCall({required Room? room, required BuildContext context}) {
    if (room == null) return;
    final url = VideoCallMessage.generateUrl();
    unawaited(
      room.sendTextEvent('${L10n.of(context)!.videoCallStartedTitle} $url'),
    );
  }
}
