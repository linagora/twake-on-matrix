import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ChatListItemSubtitle extends StatelessWidget with ChatListItemMixin {
  final Room room;

  const ChatListItemSubtitle({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final typingText = room.getLocalizedTypingText(context);
    final isGroup = !room.isDirectChat;
    final unreadBadgeSize = ChatListItemStyle.unreadBadgeSize(
      room.isUnreadOrInvited,
      room.hasNewMessages,
      room.notificationCount > 0,
    );
    final isMediaEvent = room.lastEvent?.messageType == MessageTypes.Image ||
        room.lastEvent?.messageType == MessageTypes.Video;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: typingText.isNotEmpty
              ? typingTextWidget(typingText, context)
              : isGroup
                  ? chatListItemSubtitleForGroup(
                      context: context,
                      room: room,
                    )
                  : isMediaEvent
                      ? chatListItemMediaPreviewSubTitle(
                          context,
                          room,
                        )
                      : textContentWidget(
                          room,
                          context,
                          isGroup,
                          room.isUnreadOrInvited,
                        ),
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
            return room.lastEvent?.senderId == Matrix.of(context).client.userID
                ? Icon(
                    Icons.done_all,
                    color: room.lastEvent!.receipts.isEmpty
                        ? LinagoraRefColors.material().tertiary[30]
                        : LinagoraSysColors.material().secondary,
                    size: 20,
                  )
                : AnimatedContainer(
                    duration: TwakeThemes.animationDuration,
                    curve: TwakeThemes.animationCurve,
                    padding: const EdgeInsets.only(bottom: 4),
                    height: ChatListItemStyle.mentionIconWidth,
                    width: isMentionned && room.isUnreadOrInvited
                        ? ChatListItemStyle.mentionIconWidth
                        : 0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius:
                          BorderRadius.circular(AppConfig.borderRadius),
                    ),
                    child: Center(
                      child: isMentionned && room.isUnreadOrInvited
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
          duration: TwakeThemes.animationDuration,
          curve: TwakeThemes.animationCurve,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          height: unreadBadgeSize,
          width: ChatListItemStyle.notificationBadgeSize(
            room.isUnreadOrInvited,
            room.hasNewMessages,
            room.notificationCount,
          ),
          decoration: BoxDecoration(
            color: notificationColor(
              context: context,
              room: room,
            ),
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: Center(
            child: room.notificationCount > 0
                ? Text(
                    room.notificationCount.toString(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          letterSpacing: -0.5,
                          color: room.highlightCount > 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : room.notificationCount > 0
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                        ),
                  )
                : Container(),
          ),
        ),
      ],
    );
  }
}
