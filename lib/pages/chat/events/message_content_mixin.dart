import 'package:fluffychat/pages/chat/event_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin MessageContentMixin {
  void showEventInfo(BuildContext context, Event event) =>
      event.showInfoDialog(context);
}
