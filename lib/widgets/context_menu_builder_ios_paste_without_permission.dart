import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:flutter/material.dart';

Widget mobileTwakeContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  // On iOS, SystemContextMenu (iOS 16+) avoids the clipboard permission alert
  // but only shows "Paste" when the clipboard holds plain text. URLs copied
  // from a browser are stored as public.url — a non-plain-text type — so the
  // native system menu omits the Paste button entirely.
  //
  // AdaptiveTextSelectionToolbar has the same blind spot: it derives button
  // visibility from ClipboardStatus, which is populated via
  // Clipboard.getData('text/plain') and therefore also misses public.url.
  //
  // Fix: build the button list from editableTextState.contextMenuButtonItems
  // and, when Paste is absent, add it explicitly. The injected Paste button
  // routes through TextEdittingControllerExtension.pasteText() so that the
  // Formats.uri fallback and correct cursor/undo behaviour are preserved.
  final buttonItems = _buttonItemsWithPaste(editableTextState);

  if (SystemContextMenu.isSupported(context)) {
    // Use the native iOS 16+ menu (no clipboard permission alert).
    // We can't inject buttons into SystemContextMenu directly, so fall back
    // to AdaptiveTextSelectionToolbar only when Paste was missing and we had
    // to add it ourselves.
    final pasteAlreadyPresent = editableTextState.contextMenuButtonItems.any(
      (item) => item.type == ContextMenuButtonType.paste,
    );
    if (pasteAlreadyPresent) {
      return SystemContextMenu.editableText(
        editableTextState: editableTextState,
      );
    }
  }

  // iOS <16, or iOS 16+ where Paste was injected: use Flutter's adaptive
  // toolbar with the corrected button list.
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

/// Returns [editableTextState.contextMenuButtonItems] with a Paste button
/// guaranteed to be present when the clipboard is non-empty, regardless of
/// content type (plain text, URL, image, etc.).
List<ContextMenuButtonItem> _buttonItemsWithPaste(
  EditableTextState editableTextState,
) {
  final items = editableTextState.contextMenuButtonItems;
  final hasPaste = items.any(
    (item) => item.type == ContextMenuButtonType.paste,
  );
  if (hasPaste) return items;

  // Route through the repo's controller extension so the Formats.uri fallback
  // and cursor placement in TextEdittingControllerExtension.pasteText() apply,
  // rather than calling Flutter's internal EditableTextState.pasteText().
  final controller = editableTextState.widget.controller;
  final pasteItem = ContextMenuButtonItem(
    type: ContextMenuButtonType.paste,
    onPressed: () {
      editableTextState.hideToolbar();
      controller.pasteText();
    },
  );

  // Insert Paste after Cut or at the front when Cut is absent.
  final cutIndex = items.indexWhere(
    (item) => item.type == ContextMenuButtonType.cut,
  );
  final insertAt = cutIndex == -1 ? 0 : cutIndex + 1;
  return [...items.sublist(0, insertAt), pasteItem, ...items.sublist(insertAt)];
}
