import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

enum ChatContextMenuActions {
  select,
  copyMessage,
  edit,
  pinChat,
  report,
  forward,
  reply,
  downloadFile,
  delete,
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
      case ChatContextMenuActions.reply:
        return L10n.of(context)!.reply;
      case ChatContextMenuActions.copyMessage:
        return L10n.of(context)!.copyMessageText;
      case ChatContextMenuActions.pinChat:
        return unpin ? L10n.of(context)!.unpin : L10n.of(context)!.pinChat;
      case ChatContextMenuActions.report:
        return L10n.of(context)!.report;
      case ChatContextMenuActions.forward:
        return L10n.of(context)!.forward;
      case ChatContextMenuActions.downloadFile:
        return L10n.of(context)!.download;
      case ChatContextMenuActions.jumpToMessage:
        return L10n.of(context)!.jumpToMessage;
      case ChatContextMenuActions.edit:
        return L10n.of(context)!.edit;
      case ChatContextMenuActions.delete:
        return L10n.of(context)!.delete;
    }
  }

  IconData? getIconData({bool isSelected = false, bool unpin = false}) {
    switch (this) {
      case ChatContextMenuActions.select:
        return isSelected ? Icons.circle_outlined : Icons.check_circle_outline;
      case ChatContextMenuActions.copyMessage:
        return Icons.content_copy;
      case ChatContextMenuActions.pinChat:
        return !unpin ? Icons.push_pin_outlined : null;
      case ChatContextMenuActions.report:
        return Icons.flag_outlined;
      case ChatContextMenuActions.forward:
        return Icons.shortcut;
      case ChatContextMenuActions.downloadFile:
        return Icons.download;
      case ChatContextMenuActions.edit:
        return Icons.edit_outlined;
      case ChatContextMenuActions.delete:
        return Icons.delete_outlined;
      default:
        return null;
    }
  }

  String? getImagePath({bool unpin = false}) {
    switch (this) {
      case ChatContextMenuActions.reply:
        return ImagePaths.icReply;
      case ChatContextMenuActions.jumpToMessage:
        return ImagePaths.icGoTo;
      case ChatContextMenuActions.pinChat:
        return unpin ? ImagePaths.icUnpin : null;
      default:
        return null;
    }
  }

  Color? getIconColor(
    BuildContext context,
    Event event,
    ChatContextMenuActions action,
  ) {
    if (action == ChatContextMenuActions.pinChat && event.isPinned) {
      return Theme.of(context).colorScheme.onSurface;
    }
    if (action == ChatContextMenuActions.delete) {
      return LinagoraSysColors.material().error;
    }
    return null;
  }
}
