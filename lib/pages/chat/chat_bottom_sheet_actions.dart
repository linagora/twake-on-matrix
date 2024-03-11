import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ChatBottomSheetActions {
  reply,
  select,
  copyMessage,
  pinChat,
  forward,
  downloadFile;

  String getTitle(
    BuildContext context, {
    bool isSelected = false,
    bool unpin = false,
  }) {
    switch (this) {
      case ChatBottomSheetActions.reply:
        return L10n.of(context)!.reply;
      case ChatBottomSheetActions.select:
        return isSelected
            ? L10n.of(context)!.unselect
            : L10n.of(context)!.select;
      case ChatBottomSheetActions.copyMessage:
        return L10n.of(context)!.copyMessageText;
      case ChatBottomSheetActions.pinChat:
        return unpin ? L10n.of(context)!.unpin : L10n.of(context)!.pinChat;
      case ChatBottomSheetActions.forward:
        return L10n.of(context)!.forward;
      case ChatBottomSheetActions.downloadFile:
        return L10n.of(context)!.download;
    }
  }

  IconData? getIconData({
    bool isSelected = false,
    bool unpin = false,
  }) {
    switch (this) {
      case ChatBottomSheetActions.reply:
        return Icons.reply_outlined;
      case ChatBottomSheetActions.select:
        return isSelected ? Icons.circle_outlined : Icons.check_circle_outline;
      case ChatBottomSheetActions.copyMessage:
        return Icons.content_copy;
      case ChatBottomSheetActions.pinChat:
        return !unpin ? Icons.push_pin_outlined : null;
      case ChatBottomSheetActions.forward:
        return Icons.shortcut;
      case ChatBottomSheetActions.downloadFile:
        return Icons.download;
      default:
        return null;
    }
  }

  String? getImagePath({
    bool unpin = false,
  }) {
    switch (this) {
      case ChatBottomSheetActions.pinChat:
        return unpin ? ImagePaths.icUnpin : null;
      default:
        return null;
    }
  }
}
