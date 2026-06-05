import 'package:fluffychat/utils/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';

extension TextEdittingControllerExtension on TextEditingController {
  Future<void> pasteText({ClipboardReader? clipboardReader}) async {
    final start = selection.start;
    final end = selection.end;
    TwakeClipboard.instance.initReader();
    final pastedText = await TwakeClipboard.instance.pasteText(
      clipboardReader: clipboardReader,
    );
    if (pastedText == null) return;

    if (start == -1 || end == -1) {
      text = pastedText + text;
      selection = TextSelection.collapsed(offset: pastedText.length);
      return;
    }

    // Replace [start, end) with pastedText, then place cursor after insertion.
    text = text.replaceRange(start, end, pastedText);
    selection = TextSelection.collapsed(offset: start + pastedText.length);
  }

  Future<void> copyText() async {
    final start = selection.start;
    final end = selection.end;
    if (start < end) {
      await TwakeClipboard.instance.copyText(text.substring(start, end));
    }
  }

  Future<void> cutText() async {
    final start = selection.start;
    final end = selection.end;
    if (start < end) {
      await TwakeClipboard.instance.copyText(text.substring(start, end));
      text = text.replaceRange(start, end, "");
      selection = TextSelection.collapsed(offset: start);
    }
  }

  void addNewLine() {
    final start = selection.start;
    final end = selection.end;
    if (start != end) {
      text = text.replaceRange(start, end, "\n");
    } else {
      text = "${text.substring(0, start)}\n${text.substring(end, text.length)}";
    }
    selection = TextSelection.collapsed(offset: start + 1);
  }
}
