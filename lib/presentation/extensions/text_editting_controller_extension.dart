import 'package:fluffychat/utils/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter;

extension TextEdittingControllerExtension on TextEditingController {
  Future<void> pasteText() async {
    final start = selection.start;
    final end = selection.end;
    final pastedText = await Clipboard.instance.pasteText();
    if (pastedText != null) {
      if (start == -1 || end == -1) {
        text = pastedText + text;
        return;
      }
      if (start == end) {
        final startText = text.substring(0, start);
        final trailingText = text.substring(end, text.length);
        text = startText + pastedText + trailingText;
      } else {
        text = text.replaceRange(start, end, pastedText);
      }
    }
  }

  Future<void> copyText() async {
    final start = selection.start;
    final end = selection.end;
    if (start < end) {
      await flutter.Clipboard.setData(
        flutter.ClipboardData(
          text: text.substring(start, end),
        ),
      );
    }
  }

  Future<void> cutText() async {
    //TO-DO:
  }
}
