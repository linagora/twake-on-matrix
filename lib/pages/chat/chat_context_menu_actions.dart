import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ChatContextMenuActions {
  select,
  copyMessage,
  pinMessage,
  forward,
  downloadFile;

  String getTitle(BuildContext context) {
    switch (this) {
      case ChatContextMenuActions.select:
        return L10n.of(context)!.select;
      case ChatContextMenuActions.copyMessage:
        return L10n.of(context)!.copyMessageText;
      case ChatContextMenuActions.pinMessage:
        return L10n.of(context)!.pinMessage;
      case ChatContextMenuActions.forward:
        return L10n.of(context)!.forward;
      case ChatContextMenuActions.downloadFile:
        return L10n.of(context)!.downloadFile;
    }
  }

  IconData getIcon() {
    switch (this) {
      case ChatContextMenuActions.select:
        return Icons.check_circle_outline;
      case ChatContextMenuActions.copyMessage:
        return Icons.content_copy;
      case ChatContextMenuActions.pinMessage:
        return Icons.push_pin;
      case ChatContextMenuActions.forward:
        return Icons.shortcut;
      case ChatContextMenuActions.downloadFile:
        return Icons.download;
    }
  }
}
