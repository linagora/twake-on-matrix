import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

import '../../config/themes.dart';
import '../../widgets/avatar/avatar.dart';
import '../../widgets/matrix.dart';
import '../chat/send_file_dialog.dart';

enum ArchivedRoomAction { delete, rejoin }

class ChatListItem extends StatelessWidget {
  final Room room;
  final bool activeChat;
  final bool selected;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const ChatListItem(
    this.room, {
    this.activeChat = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    Key? key,
  }) : super(key: key);

  void clickAction(BuildContext context) async {
    if (onTap != null) return onTap!();
    if (activeChat) return;
    if (room.membership == Membership.invite) {
      final joinResult = await showFutureLoadingDialog(
        context: context,
        future: () async {
          final waitForRoom = room.client.waitForRoomInSync(
            room.id,
            join: true,
          );
          await room.join();
          await waitForRoom;
        },
      );
      if (joinResult.error != null) return;
    }

    if (room.membership == Membership.ban) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.of(context)!.youHaveBeenBannedFromThisChat),
        ),
      );
      return;
    }

    if (room.membership == Membership.leave) {
      VRouter.of(context).toSegments(['archive', room.id]);
    }

    if (room.membership == Membership.join) {
      // Share content into this room
      final shareContent = Matrix.of(context).shareContent;
      if (shareContent != null) {
        final shareFile = shareContent.tryGet<MatrixFile>('file');
        if (shareContent.tryGet<String>('msgtype') ==
                'chat.fluffy.shared_file' &&
            shareFile != null) {
          await showDialog(
            context: context,
            useRootNavigator: false,
            builder: (c) => SendFileDialog(
              files: [shareFile],
              room: room,
            ),
          );
        } else {
          room.sendEvent(shareContent);
        }
        Matrix.of(context).shareContent = null;
      }

      VRouter.of(context).toSegments(['rooms', room.id]);
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
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final typingText = room.getLocalizedTypingText(context);

    final ownLastMessage =
        room.lastEvent?.senderId == Matrix.of(context).client.userID;
    final unread = room.isUnread || room.membership == Membership.invite;
    final unreadBadgeSize = ChatListItemStyle.unreadBadgeSize(
        unread, room.hasNewMessages, room.notificationCount > 0);
    final displayname = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    final isGroup = !room.isDirectChat;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 1,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        clipBehavior: Clip.hardEdge,
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : activeChat
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          onLongPress: onLongPress,
          leading: selected
              ? SizedBox(
                  width: AvatarStyle.defaultSize,
                  height: AvatarStyle.defaultSize,
                  child: Material(
                    color: Theme.of(context).primaryColor,
                    borderRadius:
                        BorderRadius.circular(AvatarStyle.defaultSize),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                )
              : Avatar(
                  mxContent: room.avatar,
                  name: displayname,
                  onTap: onLongPress,
                ),
          title: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayname,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.merge(
                                  TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    letterSpacing: 0.15,
                                    color: unread
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                        : ChatListItemStyle.readMessageColor,
                                  ),
                                ),
                          ),
                        ),
                        if (room.isFavourite)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.push_pin_outlined,
                              size: ChatListItemStyle.readIconSize,
                              color: ChatListItemStyle.readIconColor,
                            ),
                          ),
                        if (isMuted)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.volume_off_outlined,
                              size: ChatListItemStyle.readIconSize,
                              color: ChatListItemStyle.readIconColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  room.timeCreated.localizedTimeShort(context),
                  style: Theme.of(context).textTheme.labelSmall?.merge(
                        TextStyle(
                          letterSpacing: 0.5,
                          color: unread
                              ? Theme.of(context).colorScheme.onSurface
                              : LinagoraRefColors.material().neutral[50],
                        ),
                      ),
                ),
              )
            ],
          ),
          subtitle: SizedBox(
            height: 39,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (typingText.isEmpty &&
                    ownLastMessage &&
                    room.lastEvent!.status.isSending) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: typingText.isNotEmpty
                      ? Column(children: [
                          Expanded(
                              child: typingTextWidget(typingText, context)),
                          const Spacer(),
                        ])
                      : (isGroup
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                    child: lastSenderWidget(isGroup, unread)),
                                const SizedBox(height: 2),
                                Flexible(
                                    child: textContentWidget(
                                        context, isGroup, unread))
                              ],
                            )
                          : textContentWidget(context, isGroup, unread)),
                ),
                const SizedBox(width: 8),
                FutureBuilder<String>(
                  future: room.lastEvent?.calcLocalizedBody(
                        MatrixLocals(L10n.of(context)!),
                        hideReply: true,
                        hideEdit: true,
                        plaintextBody: true,
                        removeMarkdown: true,
                      ) ??
                      Future.value(''),
                  builder: (context, snapshot) {
                    if (snapshot.data == '' ||
                        snapshot.data == null ||
                        room.lastEvent == null) {
                      return const SizedBox.shrink();
                    }

                    final isMentionned = snapshot.data!
                        .getAllMentionedUserIdsFromMessage(room)
                        .contains(Matrix.of(context).client.userID);
                    return AnimatedContainer(
                      duration: FluffyThemes.animationDuration,
                      curve: FluffyThemes.animationCurve,
                      padding: const EdgeInsets.only(bottom: 4),
                      height: ChatListItemStyle.mentionIconWidth,
                      width: isMentionned && unread
                          ? ChatListItemStyle.mentionIconWidth
                          : 0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius:
                            BorderRadius.circular(AppConfig.borderRadius),
                      ),
                      child: Center(
                        child: isMentionned && unread
                            ? Text(
                                '@',
                                style: TextStyle(
                                  color: isMentionned
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                  fontSize: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.fontSize,
                                ),
                              )
                            : Container(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: FluffyThemes.animationDuration,
                  curve: FluffyThemes.animationCurve,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  height: unreadBadgeSize,
                  width: ChatListItemStyle.notificationBadgeSize(
                      unread, room.hasNewMessages, room.notificationCount),
                  decoration: BoxDecoration(
                    color: room.highlightCount > 0 ||
                            room.membership == Membership.invite
                        ? Theme.of(context).colorScheme.primary
                        : room.notificationCount > 0 || room.markedUnread
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppConfig.borderRadius),
                  ),
                  child: Center(
                    child: room.notificationCount > 0
                        ? Text(
                            room.notificationCount.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  letterSpacing: -0.5,
                                  color: room.highlightCount > 0
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : room.notificationCount > 0
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                ),
                          )
                        : Container(),
                  ),
                ),
              ],
            ),
          ),
          onTap: () => clickAction(context),
        ),
      ),
    );
  }

  FutureBuilder<String> textContentWidget(
      BuildContext context, bool isGroup, bool unread) {
    return FutureBuilder<String>(
      future: room.lastEvent?.calcLocalizedBody(
            MatrixLocals(L10n.of(context)!),
            hideReply: true,
            hideEdit: true,
            plaintextBody: true,
            removeMarkdown: true,
          ) ??
          Future.value(L10n.of(context)!.emptyChat),
      builder: (context, snapshot) {
        return Text(
          room.membership == Membership.invite
              ? L10n.of(context)!.youAreInvitedToThisChat
              : snapshot.data ??
                  room.lastEvent?.calcLocalizedBodyFallback(
                    MatrixLocals(L10n.of(context)!),
                    hideReply: true,
                    hideEdit: true,
                    plaintextBody: true,
                    removeMarkdown: true,
                  ) ??
                  L10n.of(context)!.emptyChat,
          softWrap: false,
          maxLines: isGroup ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 0.4,
                color: unread
                    ? Theme.of(context).colorScheme.onSurface
                    : LinagoraRefColors.material().neutral[50],
              ),
        );
      },
    );
  }

  Row typingTextWidget(String typingText, BuildContext context) {
    final displayedTypingText = "~ $typingText…";
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            displayedTypingText,
            style: Theme.of(context).textTheme.labelLarge?.merge(
                  TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            maxLines: 1,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  RenderObjectWidget lastSenderWidget(bool isGroup, bool unread) {
    return isGroup
        ? Row(
            children: [
              FutureBuilder<User?>(
                future: room.lastEvent?.fetchSenderUser(),
                builder: (context, snapshot) {
                  if (snapshot.data == null) return const SizedBox.shrink();
                  return Text(
                    snapshot.data!.displayName!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelLarge?.merge(
                          TextStyle(
                            overflow: TextOverflow.ellipsis,
                            color: unread
                                ? Theme.of(context).colorScheme.onSurface
                                : ChatListItemStyle.readMessageColor,
                          ),
                        ),
                  );
                },
              ),
              const Spacer()
            ],
          )
        : const SizedBox.shrink();
  }
}
