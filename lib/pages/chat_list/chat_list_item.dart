import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends StatelessWidget with ChatListItemMixin {
  final Room room;
  final bool activeChat;
  final bool isSelectedItem;
  final bool isEnableSelectMode;
  final Widget? checkBoxWidget;
  final void Function()? onTap;
  final void Function()? onTapAvatar;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final void Function()? onLongPress;

  const ChatListItem(
    this.room, {
    this.checkBoxWidget,
    this.activeChat = false,
    this.isSelectedItem = false,
    this.isEnableSelectMode = false,
    this.onTap,
    this.onTapAvatar,
    this.onSecondaryTapDown,
    this.onLongPress,
    super.key,
  });

  void clickAction(BuildContext context) async {
    if (onTap != null) return onTap!();
    switch (room.membership) {
      case Membership.ban:
        TwakeSnackBar.show(
          context,
          L10n.of(context)!.youHaveBeenBannedFromThisChat,
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
        await TwakeDialog.showFutureLoadingDialogFullScreen(
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
      await TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () => room.leave(),
      );
      return;
    }
  }

  bool get _isGroupChat => !room.isDirectChat;

  @override
  Widget build(BuildContext context) {
    final displayName = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return Padding(
      padding: ChatListItemStyle.padding,
      child: TwakeInkWell(
        isSelected: activeChat,
        onTap: () => clickAction(context),
        onSecondaryTapDown: onSecondaryTapDown,
        onLongPress: onLongPress,
        child: TwakeListItem(
          child: Container(
            height: ChatListItemStyle.chatItemHeight,
            padding: ChatListItemStyle.paddingBody,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isEnableSelectMode) checkBoxWidget ?? const SizedBox(),
                Padding(
                  padding: ChatListItemStyle.paddingAvatar,
                  child: Stack(
                    children: [
                      Avatar(
                        mxContent: room.avatar,
                        name: displayName,
                        onTap: onTapAvatar,
                      ),
                      if (_isGroupChat)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: ChatListItemStyle.paddingIconGroup,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: Icon(
                              Icons.group,
                              size: ChatListItemStyle.groupIconSize,
                              color: room.isUnreadOrInvited
                                  ? LinagoraSysColors.material()
                                      .onSurfaceVariant
                                  : LinagoraRefColors.material().tertiary[30],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ChatListItemTitle(
                        room: room,
                      ),
                      ChatListItemSubtitle(room: room),
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
