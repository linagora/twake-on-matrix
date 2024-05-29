import 'package:fluffychat/presentation/mixins/paste_image_mixin.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:fluffychat/utils/clipboard.dart';

mixin HandleClipboardActionMixin on PasteImageMixin {
  FocusNode get chatFocusNode;

  BuildContext get context;

  Room? get room;

  TextEditingController get sendController;

  void registerPasteShortcutListeners({
    VoidCallback? onSendFileCallback,
  }) {
    ClipboardEvents.instance?.registerPasteEventListener(
      (event) => _onPasteEvent(
        event,
        onSendFileCallback: onSendFileCallback,
      ),
    );
  }

  void unregisterPasteShortcutListeners() {
    ClipboardEvents.instance?.unregisterPasteEventListener(_onPasteEvent);
  }

  void _onPasteEvent(
    ClipboardReadEvent event, {
    VoidCallback? onSendFileCallback,
  }) async {
    if (chatFocusNode.hasFocus != true) {
      return;
    }
    final clipboardReader = await event.getClipboardReader();
    if (await TwakeClipboard.instance
            .isReadableImageFormat(clipboardReader: clipboardReader) &&
        room != null) {
      await pasteImage(
        context,
        room!,
        clipboardReader: clipboardReader,
        onSendFileCallback: onSendFileCallback,
      );
    } else {
      sendController.pasteText(clipboardReader: clipboardReader);
    }
  }
}
