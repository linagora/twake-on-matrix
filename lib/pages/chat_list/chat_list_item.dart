import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_mixin.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends StatelessWidget with ChatListItemMixin {
  final Room room;
  final bool activeChat;
  final bool isSelectedItem;
  final bool isEnableSelectMode;
  final Widget? checkBoxWidget;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const ChatListItem(
    this.room, {
    this.checkBoxWidget,
    this.activeChat = false,
    this.isSelectedItem = false,
    this.isEnableSelectMode = false,
    this.onTap,
    this.onLongPress,
    Key? key,
  }) : super(key: key);

  void clickAction(BuildContext context) async {
    if (onTap != null) return onTap!();
    if (activeChat) return;
    switch (room.membership) {
      case Membership.ban:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context)!.youHaveBeenBannedFromThisChat),
          ),
        );
        return;
      case Membership.leave:
        context.go('/archive/${room.id}');
      case Membership.invite:
      case Membership.join:
        context.go('/rooms/${room.id}');
      default:
        return;
    }
  }

  Future<void> archiveAction(BuildContext context) async {
    {
      if ([Membership.leave, Membership.ban].contains(room.membership)) {
        await showFutureLoadingDialog(
          context: context,
          future: () => room.forget(),
        );
        return;
      }
      final confirmed = await showOkCancelAlertDialog(
        useRootNavigator: false,
        context: context,
        title: L10n.of(context)!.areYouSure,
        okLabel: L10n.of(context)!.yes,
        cancelLabel: L10n.of(context)!.no,
      );
      if (confirmed == OkCancelResult.cancel) return;
      await showFutureLoadingDialog(
        context: context,
        future: () => room.leave(),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayname = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 1,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        clipBehavior: Clip.hardEdge,
        color: isSelectedItem
            ? Theme.of(context).colorScheme.primaryContainer
            : activeChat
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
        child: InkWell(
          onTap: () => clickAction(context),
          // onLongPress: onLongPress,
          onSecondaryTap: () {},
          onDoubleTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (isEnableSelectMode) checkBoxWidget ?? const SizedBox(),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Avatar(
                    mxContent: room.avatar,
                    name: displayname,
                    onTap: onLongPress,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      ChatListItemTitle(room: room),
                      ChatListItemSubtitle(room: room)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
