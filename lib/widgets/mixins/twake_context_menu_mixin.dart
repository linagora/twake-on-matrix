import 'package:fluffychat/pages/chat/events/message/message_content_with_timestamp_builder.dart';
import 'package:fluffychat/widgets/context_menu/twake_context_menu.dart';
import 'package:flutter/material.dart';

/// Show a [TwakeContextMenu] on the given [BuildContext]. For other parameters, see [TwakeContextMenu].
mixin TwakeContextMenuMixin {
  void showTwakeContextMenu({
    required Offset offset,
    required BuildContext context,
    required ContextMenuBuilder builder,
    double? verticalPadding,
    VoidCallback? onClose,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) => TwakeContextMenu(
        position: offset,
        builder: builder,
        verticalPadding: verticalPadding,
      ),
    ).then((value) {
      onClose?.call();
    });
  }
}
