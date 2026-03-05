import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/typing_timer_wrapper.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ChatListItemSubtitle extends StatelessWidget with ChatListItemMixin {
  final Room room;
  final Event? lastEvent;

  const ChatListItemSubtitle({super.key, required this.room, this.lastEvent});

  @override
  Widget build(BuildContext context) {
    final String typingText = room.getLocalizedTypingText(L10n.of(context)!);
    final bool isGroup = !room.isDirectChat;
    final double unreadBadgeSize = ChatListItemStyle.unreadBadgeSize(
      room.isUnreadOrInvited,
      room.hasNewMessages,
      room.notificationCount > 0,
    );
    final Event? lastEvent = this.lastEvent ?? room.lastEvent;
    final bool isMediaEvent =
        lastEvent?.messageType == MessageTypes.Image ||
        lastEvent?.messageType == MessageTypes.Video;

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textScheme = theme.textTheme;

    return Row(
      mainAxisAlignment: .start,
      crossAxisAlignment: .start,
      children: <Widget>[
        Expanded(
          child: _buildMainSubtitleContent(
            context,
            lastEvent,
            typingText,
            isGroup,
            isMediaEvent,
          ),
        ),
        const SizedBox(width: 8),
        FutureBuilder<String>(
          future:
              lastEvent?.calcLocalizedBody(
                MatrixLocals(L10n.of(context)!),
                hideReply: true,
                hideEdit: true,
                plaintextBody: true,
                removeMarkdown: true,
              ) ??
              Future.value(''),
          builder: (context, snapshot) {
            if (snapshot.data == null ||
                snapshot.data!.isEmpty ||
                lastEvent == null) {
              return const SizedBox.shrink();
            }
            final isMentioned = lastEvent.isMention == true;
            return lastEvent.senderId == room.client.userID
                ? Icon(
                    Icons.done_all,
                    color: room.hasLastEventBeenSeenByOthers
                        ? LinagoraRefColors.material().tertiary[30]
                        : LinagoraSysColors.material().secondary,
                    size: 20,
                  )
                : AnimatedContainer(
                    duration: TwakeThemes.animationDuration,
                    curve: TwakeThemes.animationCurve,
                    padding: const .only(bottom: 4),
                    height: ChatListItemStyle.mentionIconWidth,
                    width: isMentioned && room.isUnreadOrInvited
                        ? ChatListItemStyle.mentionIconWidth
                        : 0,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: .circular(AppConfig.borderRadius),
                    ),
                    child: Center(
                      child: isMentioned && room.isUnreadOrInvited
                          ? Text(
                              '@',
                              style: TextStyle(
                                color: isMentioned
                                    ? colorScheme.onPrimary
                                    : colorScheme.onPrimaryContainer,
                                fontSize: textScheme.labelMedium?.fontSize,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
          },
        ),
        const SizedBox(width: 4),
        AnimatedContainer(
          duration: TwakeThemes.animationDuration,
          curve: TwakeThemes.animationCurve,
          padding: const .symmetric(horizontal: 7),
          height: unreadBadgeSize,
          width: ChatListItemStyle.notificationBadgeSize(
            room.isUnreadOrInvited,
            room.hasNewMessages,
            room.notificationCount,
          ),
          decoration: BoxDecoration(
            color: notificationColor(context: context, room: room),
            borderRadius: .circular(AppConfig.borderRadius),
          ),
          child: Center(
            child: room.notificationCount > 0
                ? Text(
                    room.notificationCount.toString(),
                    style: textScheme.labelMedium?.copyWith(
                      letterSpacing: -0.5,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainSubtitleContent(
    BuildContext context,
    Event? lastEvent,
    String typingText,
    bool isGroup,
    bool isMediaEvent,
  ) {
    return TypingTimerWrapper(
      room: room,
      l10n: L10n.of(context)!,
      typingWidget: typingTextWidget(typingText, context),
      notTypingWidget: isGroup
          ? chatListItemSubtitleForGroup(
              context: context,
              room: room,
              event: lastEvent,
            )
          : isMediaEvent
          ? chatListItemMediaPreviewSubTitle(context, lastEvent)
          : textContentWidget(
              room,
              lastEvent,
              context,
              isGroup,
              room.isUnreadOrInvited,
            ),
    );
  }
}
