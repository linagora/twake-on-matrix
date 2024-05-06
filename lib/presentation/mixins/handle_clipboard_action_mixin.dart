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

  void registerPasteShortcutListeners() {
    ClipboardEvents.instance?.registerPasteEventListener(_onPasteEvent);
  }

  void unregisterPasteShortcutListeners() {
    ClipboardEvents.instance?.unregisterPasteEventListener(_onPasteEvent);
  }

  void selectAll() {
    sendController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: sendController.text.length,
    );
  }

  Future<void> paste() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard != null) {
      final reader = await clipboard.read();
      _paste(reader);
    }
  }

  void _onPasteEvent(ClipboardReadEvent event) async {
    if (chatFocusNode.hasFocus != true) {
      return;
    }
    final clipboardReader = await event.getClipboardReader();
    _paste(clipboardReader);
  }

  void _paste(ClipboardReader reader) async {
    if (await TwakeClipboard.instance
            .isReadableImageFormat(clipboardReader: reader) &&
        room != null) {
      await pasteImage(context, room!, clipboardReader: reader);
    } else {
      sendController.pasteText(clipboardReader: reader);
    }
  }
}
