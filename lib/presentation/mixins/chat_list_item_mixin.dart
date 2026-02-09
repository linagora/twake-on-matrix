import 'package:fluffychat/pages/chat/events/images_builder/image_placeholder.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_image_preview_style.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

mixin ChatListItemMixin {
  Widget textContentWidget(
    Room room,
    Event? lastEvent,
    BuildContext context,
    bool isGroup,
    bool unread,
  ) {
    return _textContentFutureBuilder(context, room, isGroup, lastEvent);
  }

  Widget _textContentFutureBuilder(
    BuildContext context,
    Room room,
    bool isGroup,
    Event? event,
  ) {
    if (event == null) return const SizedBox.shrink();
    return FutureBuilder<String>(
      future: event.calcLocalizedBodyRemoveBreakLine(L10n.of(context)!),
      builder: (context, snapshot) {
        return Text(
          room.membership == Membership.invite
              ? L10n.of(context)!.youAreInvitedToThisChat
              : snapshot.data ??
                  event.calcLocalizedBodyFallback(
                    MatrixLocals(L10n.of(context)!),
                    hideReply: true,
                    hideEdit: true,
                    plaintextBody: true,
                    removeMarkdown: true,
                  ),
          softWrap: false,
          maxLines: isGroup ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: ListItemStyle.subtitleTextStyle(
            fontFamily: 'Inter',
          ),
        );
      },
    );
  }

  Widget typingTextWidget(String typingText, BuildContext context) {
    final displayedTypingText = "$typingText…";
    return Text(
      displayedTypingText,
      style: ListItemStyle.subtitleTextStyle(
        fontFamily: 'Inter',
      ),
      maxLines: 2,
      softWrap: true,
    );
  }

  Widget chatListItemSubtitleForGroup({
    required BuildContext context,
    required Room room,
    Event? event,
  }) {
    if (room.membership == Membership.invite) {
      return Text(
        L10n.of(context)!.youAreInvitedToThisChat,
        softWrap: false,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style:
            ChatLitSubSubtitleTextStyleView.textStyle.textStyle(room, context),
      );
    }

    return FutureBuilder<User?>(
      future: event?.fetchSenderUser(),
      builder: (context, snapshot) => _subTitleFutureBuilder(
        context,
        room,
        event,
        snapshot.data,
      ),
    );
  }

  Widget _subTitleFutureBuilder(
    BuildContext context,
    Room room,
    Event? event,
    User? user,
  ) {
    if (user == null || event == null) return const SizedBox.shrink();

    final subscriptions = event.calcLocalizedBodyFallbackRemoveBreakLine(
      L10n.of(context)!,
    );
    if (event.isAFile == true) {
      return Text(
        "${user.calcDisplayname()}: ${event.filename}",
        softWrap: false,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style:
            ChatLitSubSubtitleTextStyleView.textStyle.textStyle(room, context),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.calcDisplayname(),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
          style: ListItemStyle.subtitleTextStyle(
            fontFamily: 'Inter',
          ).copyWith(
            color: LinagoraSysColors.material().onSurface,
          ),
        ),
        event.messageType == MessageTypes.Image ||
                event.messageType == MessageTypes.Video
            ? chatListItemMediaPreviewSubTitle(
                context,
                event,
              )
            : Text(
                subscriptions,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ListItemStyle.subtitleTextStyle(
                  fontFamily: 'Inter',
                ),
              ),
      ],
    );
  }

  Widget chatListItemMediaPreviewSubTitle(
    BuildContext context,
    Event? event,
  ) {
    return Row(
      children: [
        if (event == null || event.status != EventStatus.synced)
          const SizedBox.shrink()
        else
          SizedBox(
            height: SubtitleImagePreviewStyle.height,
            width: SubtitleImagePreviewStyle.width,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(SubtitleImagePreviewStyle.borderRadius),
              child: MxcImage(
                key: ValueKey(event.eventId),
                cacheKey: event.eventId,
                event: event,
                placeholder: (context) => ImagePlaceholder(
                  event: event,
                  width: SubtitleImagePreviewStyle.width,
                  height: SubtitleImagePreviewStyle.height,
                  fit: SubtitleImagePreviewStyle.fit,
                ),
                fit: SubtitleImagePreviewStyle.fit,
                enableHeroAnimation: false,
              ),
            ),
          ),
        Padding(
          padding: SubtitleImagePreviewStyle.labelPadding,
          child: Text(
            event?.messageType == MessageTypes.Image
                ? L10n.of(context)!.photo
                : L10n.of(context)!.video,
            style: ListItemStyle.subtitleTextStyle(
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  Color? notificationColor({
    required BuildContext context,
    required Room room,
  }) {
    /// highlightCount or Invitation
    if (room.highlightCount > 0 || room.membership == Membership.invite) {
      return Theme.of(context).colorScheme.primary;
    }

    if (hasNewMessage(room)) {
      return _handleNotificationColorHasNewMessage(
        room,
        context,
      );
    }

    if (room.markedUnread) {
      return _handleNotificationColorMarkedUnread(
        context: context,
        room: room,
      );
    }
    return Colors.transparent;
  }

  bool hasNewMessage(Room room) {
    // If there's a notification count, definitely has new messages
    if (room.notificationCount > 0) {
      return true;
    }

    // For mentions-only rooms, check hasNewMessages
    // This is important because they won't increment notificationCount for regular messages
    if (room.pushRuleState == PushRuleState.mentionsOnly &&
        room.hasNewMessages) {
      return true;
    }

    // For notify rooms, only trust notificationCount to avoid race conditions
    // Don't use hasNewMessages as it can lag behind the actual read state
    return false;
  }

  Color? _handleNotificationColorHasNewMessage(
    Room room,
    BuildContext context,
  ) {
    if (room.pushRuleState == PushRuleState.mentionsOnly) {
      return LinagoraRefColors.material().tertiary[30];
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Color? _handleNotificationColorMarkedUnread({
    required BuildContext context,
    required Room room,
  }) {
    if (room.pushRuleState == PushRuleState.mentionsOnly) {
      return LinagoraRefColors.material().tertiary[30];
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
}
