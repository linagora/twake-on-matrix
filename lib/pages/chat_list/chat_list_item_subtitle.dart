import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:fluffychat/domain/model/room/room_preview_result.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:fluffychat/pages/chat/typing_timer_wrapper.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/pages/chat_list/chat_preview_text.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_view.dart';
import 'package:fluffychat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatListItemSubtitle extends StatelessWidget with ChatListItemMixin {
  final Room room;
  final RoomPreviewResult? previewResult;

  const ChatListItemSubtitle({
    super.key,
    required this.room,
    this.previewResult,
  });

  static Event? _syncPreview(Event? candidate) {
    if (candidate == null) return null;
    return EventVisibilityResolver.isEligibleForChatListPreviewSync(candidate)
        ? candidate
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = L10n.of(context)!;
    final String typingText = room.getLocalizedTypingText(l10n);
    final bool isGroup = !room.isDirectChat;
    final double unreadBadgeSize = ChatListItemStyle.unreadBadgeSize(
      room.isUnreadOrInvited,
      room.hasNewMessages,
      room.notificationCount > 0,
    );
    final Event? lastEvent =
        _syncPreview(room.lastEvent) ??
        switch (previewResult) {
          RoomPreviewFound(:final event) => event,
          _ => null,
        };
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
            l10n,
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
                MatrixLocals(l10n),
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
                    color: MessageTimeStyle.readReceiptColor(
                      room.hasLastEventBeenSeenByOthers,
                    ),
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
    L10n l10n,
    Event? lastEvent,
    String typingText,
    bool isGroup,
    bool isMediaEvent,
  ) {
    final bool showPlaceholder =
        lastEvent == null && room.membership != Membership.invite;

    return TypingTimerWrapper(
      room: room,
      l10n: l10n,
      typingWidget: typingTextWidget(typingText, context),
      notTypingWidget: showPlaceholder
          ? ChatPreviewText(
              previewResult: previewResult,
              style: ChatListSubSubtitleTextStyleView.textStyle.textStyle(
                room,
                context,
              ),
              l10n: l10n,
            )
          : isGroup
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
