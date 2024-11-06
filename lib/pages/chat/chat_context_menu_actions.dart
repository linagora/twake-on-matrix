import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ChatContextMenuActions {
  select,
  copyMessage,
  pinChat,
  forward,
  downloadFile,
  jumpToMessage;

  String getTitle(
    BuildContext context, {
    bool isSelected = false,
    bool unpin = false,
  }) {
    switch (this) {
      case ChatContextMenuActions.select:
        return isSelected
            ? L10n.of(context)!.unselect
            : L10n.of(context)!.select;
      case ChatContextMenuActions.copyMessage:
        return L10n.of(context)!.copyMessageText;
      case ChatContextMenuActions.pinChat:
        return unpin ? L10n.of(context)!.unpin : L10n.of(context)!.pinChat;
      case ChatContextMenuActions.forward:
        return L10n.of(context)!.forward;
      case ChatContextMenuActions.downloadFile:
        return L10n.of(context)!.download;
      case ChatContextMenuActions.jumpToMessage:
        return L10n.of(context)!.jumpToMessage;
    }
  }

  IconData? getIconData({
    bool isSelected = false,
    bool unpin = false,
  }) {
    switch (this) {
      case ChatContextMenuActions.select:
        return isSelected ? Icons.circle_outlined : Icons.check_circle_outline;
      case ChatContextMenuActions.copyMessage:
        return Icons.content_copy;
      case ChatContextMenuActions.pinChat:
        return !unpin ? Icons.push_pin_outlined : null;
      case ChatContextMenuActions.forward:
        return Icons.shortcut;
      case ChatContextMenuActions.downloadFile:
        return Icons.download;
      default:
        return null;
    }
  }

  String? getImagePath({
    bool unpin = false,
  }) {
    switch (this) {
      case ChatContextMenuActions.jumpToMessage:
        return ImagePaths.icGoTo;
      case ChatContextMenuActions.pinChat:
        return unpin ? ImagePaths.icUnpin : null;
      default:
        return null;
    }
  }
}
