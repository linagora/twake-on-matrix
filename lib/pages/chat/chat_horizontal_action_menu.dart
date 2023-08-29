import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ChatHorizontalActionMenu {
  reply,
  forward,
  more;

  String getTitle(BuildContext context) {
    switch (this) {
      case ChatHorizontalActionMenu.reply:
        return L10n.of(context)!.reply;
      case ChatHorizontalActionMenu.forward:
        return L10n.of(context)!.forward;
      case ChatHorizontalActionMenu.more:
        return L10n.of(context)!.more;
    }
  }

  IconData? getIcon() {
    switch (this) {
      case ChatHorizontalActionMenu.reply:
        return null;
      case ChatHorizontalActionMenu.forward:
        return Icons.shortcut;
      case ChatHorizontalActionMenu.more:
        return Icons.more_horiz;
    }
  }

  String? getImagePath() {
    switch (this) {
      case ChatHorizontalActionMenu.reply:
        return ImagePaths.icReply;
      case ChatHorizontalActionMenu.more:
      case ChatHorizontalActionMenu.forward:
        return null;
    }
  }

  ContextMenuItemState getContextMenuItemState() {
    switch (this) {
      case ChatHorizontalActionMenu.reply:
      case ChatHorizontalActionMenu.more:
      case ChatHorizontalActionMenu.forward:
        return ContextMenuItemState.activated;
    }
  }
}
