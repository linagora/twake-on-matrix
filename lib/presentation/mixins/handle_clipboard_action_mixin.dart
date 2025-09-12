import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:fluffychat/presentation/mixins/paste_image_mixin.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:super_clipboard/super_clipboard.dart';

mixin HandleClipboardActionMixin on PasteImageMixin {
  FocusNode get chatFocusNode;

  BuildContext get context;

  Room? get room;

  TextEditingController get sendController;

  void registerPasteShortcutListeners() {
    ClipboardEvents.instance?.registerPasteEventListener(_onPasteEvent);
  }

  void unregisterPasteShortcutListeners() {
    ClipboardEvents.instance?.unregisterPasteEventListener(_onPasteEvent);
  }

  void _onPasteEvent(ClipboardReadEvent event) async {
    final clipboardReader = await event.getClipboardReader();
    if (await TwakeClipboard.instance
        .isReadableImageFormat(clipboardReader: clipboardReader)) {
      await pasteClipboardImage(clipboardReader);
    } else {
      await pasteClipboardText(clipboardReader);
    }
  }

  void onSendFileCallback();

  Future<void> pasteClipboardImage(ClipboardReader? clipboardReader) async {
    if (chatFocusNode.hasFocus != true) return;

    if (room == null) return Future.value();

    return pasteImage(
      context,
      room!,
      clipboardReader: clipboardReader,
      onSendFileCallback: onSendFileCallback,
    );
  }

  Future<void> pasteClipboardText(ClipboardReader? clipboardReader) async {
    if (chatFocusNode.hasFocus != true) return;

    sendController.pasteText(clipboardReader: clipboardReader);
  }
}
