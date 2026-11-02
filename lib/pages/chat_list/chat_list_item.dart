import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:twake_chat/domain/model/room/room_extension.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_title.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/space_row_actions.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

import 'package:twake_chat/config/go_routes/app_routes.dart';
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
  final RoomPreviewResult? previewResult;

  /// How deep the row is in its space.
  final int depth;

  /// What the row of a space shows and does beyond a room's.
  final SpaceRowData? space;

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
    this.previewResult,
    this.depth = 0,
    this.space,
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
        ArchiveRoomRoute(roomid: room.id).go(context);
        return;
      case Membership.invite:
      case Membership.join:
        RoomRoute(roomid: room.id).go(context);
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

  IconData get _kindIcon => space != null ? Icons.view_in_ar : Icons.group;

  @override
  Widget build(BuildContext context) {
    final isChild = depth > 0;
    return Padding(
      padding: ChatListItemStyle.padding,
      child: TwakeInkWell(
        isSelected: activeChat,
        onTap: () => clickAction(context),
        onSecondaryTapDown: onSecondaryTapDown,
        onLongPress: onLongPress,
        child: TwakeListItem(
          child: FutureBuilder(
            future: room.name.isEmpty ? room.loadHeroUsers() : null,
            builder: (context, _) {
              final displayName = room.getLocalizedDisplayname(
                MatrixLocals(L10n.of(context)!),
              );
              return Container(
                height: space != null
                    ? ChatListItemStyle.spaceItemHeight
                    : ChatListItemStyle.chatItemHeight,
                padding: ChatListItemStyle.paddingBody.add(
                  EdgeInsetsDirectional.only(
                    start: depth * ChatListItemStyle.depthIndent,
                  ),
                ),
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
                            size: isChild
                                ? ChatListItemStyle.childAvatarSize
                                : AvatarStyle.defaultSize,
                            onTap: onTapAvatar,
                            keepAlive: true,
                          ),
                          if (_isGroupChat)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: ChatListItemStyle.paddingIconGroup,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                                child: Icon(
                                  _kindIcon,
                                  size: isChild
                                      ? ChatListItemStyle.childKindIconSize
                                      : ChatListItemStyle.groupIconSize,
                                  color: room.isUnreadOrInvited
                                      ? LinagoraSysColors.material()
                                            .onSurfaceVariant
                                      : LinagoraRefColors.material()
                                            .tertiary[30],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: space != null
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          ChatListItemTitle(
                            room: room,
                            originServerTs: switch (previewResult) {
                              RoomPreviewFound(:final event)
                                  when space == null =>
                                event.originServerTs,
                              _ => null,
                            },
                          ),
                          // A space is no conversation: nothing to preview.
                          if (space == null)
                            ChatListItemSubtitle(
                              room: room,
                              previewResult: previewResult,
                            )
                          else if (room.isInvitation)
                            Text(
                              L10n.of(context)!.invited,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: LinagoraSysColors.material().primary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (space case final space?)
                      SpaceRowActions(name: displayName, space: space),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
