import 'package:fluffychat/utils/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';

extension TextEdittingControllerExtension on TextEditingController {
  Future<void> pasteText({ClipboardReader? clipboardReader}) async {
    final start = selection.start;
    final end = selection.end;
    Clipboard.instance.initReader();
    final pastedText =
        await Clipboard.instance.pasteText(clipboardReader: clipboardReader);
    if (pastedText != null) {
      if (start == -1 || end == -1) {
        text = pastedText + text;
        selection = TextSelection.collapsed(offset: text.length);
        return;
      }
      if (start == end) {
        final startText = text.substring(0, start);
        final trailingText = text.substring(end, text.length);
        text = startText + pastedText + trailingText;
      } else {
        text = text.replaceRange(start, end, pastedText);
      }
      selection = TextSelection.collapsed(offset: end + pastedText.length);
    }
  }

  Future<void> copyText() async {
    final start = selection.start;
    final end = selection.end;
    if (start < end) {
      await Clipboard.instance.copyText(text.substring(start, end));
    }
  }

  Future<void> cutText() async {
    final start = selection.start;
    final end = selection.end;
    if (start < end) {
      await Clipboard.instance.copyText(text.substring(start, end));
      text = text.replaceRange(start, end, "");
      selection = TextSelection.collapsed(offset: start);
    }
  }

  void addNewLine() {
    text = '$text\n';
    selection = TextSelection.collapsed(offset: text.length);
  }
}
