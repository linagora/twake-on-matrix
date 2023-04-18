import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/custom_svg_icons.dart';

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
        if (shareContent.tryGet<String>('msgtype') == 'chat.fluffy.shared_file' &&
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
    final ownMessage =
        room.lastEvent?.senderId == Matrix.of(context).client.userID;
    final unread = room.isUnread || room.membership == Membership.invite;
    final unreadBubbleSize = unread || room.hasNewMessages
        ? room.notificationCount > 0
            ? 20.0
            : 14.0
        : 0.0;
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
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : activeChat
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
        child: Column(
          children: [
            ListTile(
              visualDensity: const VisualDensity(vertical: -0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              onLongPress: onLongPress,
              leading: selected
                  ? SizedBox(
                      width: AvatarStyle.defaultSize,
                      height: AvatarStyle.defaultSize,
                      child: Material(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(AvatarStyle.defaultSize),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                displayname,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontFamily: 'SFProDisplayHeavy',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Wrap(
                                  spacing: 6,
                                  children: [
                                    if (room.isFavourite)
                                      SvgPicture.asset(
                                        CustomSVGIcons.pinIcon,
                                        width: 16,
                                        color: const Color(0xFF99A2AD),
                                      ),
                                    if (isMuted)
                                      SvgPicture.asset(
                                        CustomSVGIcons.muteIcon,
                                        width: 16,
                                        color: const Color(0xFF99A2AD),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      room.timeCreated.localizedTimeShort(context),
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'SFProText',
                        color: unread
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).textTheme.bodyMedium!.color,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (typingText.isEmpty &&
                      ownMessage &&
                      room.lastEvent!.status.isSending) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedContainer(
                    width: typingText.isEmpty ? 0 : 18,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(),
                    duration: FluffyThemes.animationDuration,
                    curve: FluffyThemes.animationCurve,
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 14,
                    ),
                  ),
                  Expanded(
                    child: typingText.isNotEmpty
                        ? Text(
                            typingText,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            maxLines: 1,
                            softWrap: false,
                          )
                        : FutureBuilder<String>(
                            future: room.lastEvent?.calcLocalizedBody(
                                  MatrixLocals(L10n.of(context)!),
                                  hideReply: true,
                                  hideEdit: true,
                                  plaintextBody: true,
                                  removeMarkdown: true,
                                  withSenderNamePrefix: !room.isDirectChat ||
                                      room.directChatMatrixID !=
                                          room.lastEvent?.senderId,
                                ) ??
                                Future.value(L10n.of(context)!.emptyChat),
                            builder: (context, snapshot) {
                              return Text(
                                room.membership == Membership.invite
                                    ? L10n.of(context)!.youAreInvitedToThisChat
                                    : snapshot.data ??
                                        room.lastEvent
                                            ?.calcLocalizedBodyFallback(
                                          MatrixLocals(L10n.of(context)!),
                                          hideReply: true,
                                          hideEdit: true,
                                          plaintextBody: true,
                                          removeMarkdown: true,
                                          withSenderNamePrefix:
                                              !room.isDirectChat ||
                                                  room.directChatMatrixID !=
                                                      room.lastEvent?.senderId,
                                        ) ??
                                        L10n.of(context)!.emptyChat,
                                softWrap: false,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  decoration: room.lastEvent?.redacted == true
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: FluffyThemes.animationDuration,
                    curve: FluffyThemes.animationCurve,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    height: unreadBubbleSize,
                    width: room.notificationCount == 0 &&
                            !unread &&
                            !room.hasNewMessages
                        ? 0
                        : (unreadBubbleSize - 9) *
                                room.notificationCount.toString().length +
                            9,
                    decoration: BoxDecoration(
                      color: room.highlightCount > 0 ||
                              room.membership == Membership.invite
                          ? Colors.red
                          : room.notificationCount > 0 || room.markedUnread
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(AppConfig.borderRadius),
                    ),
                    child: Center(
                      child: room.notificationCount > 0
                          ? Text(
                              room.notificationCount.toString(),
                              style: TextStyle(
                                color: room.highlightCount > 0
                                    ? Colors.white
                                    : room.notificationCount > 0
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                fontSize: 13,
                              ),
                            )
                          : Container(),
                    ),
                  ),
                ],
              ),
              onTap: () => clickAction(context),
            ),
            const Divider(
              height: 0,
              indent: 82,
              thickness: 0.6,
            )
          ],
        ),
      ),
    );
  }
}
