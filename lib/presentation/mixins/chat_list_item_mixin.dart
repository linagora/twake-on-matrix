import 'package:fluffychat/pages/chat/events/images_builder/image_placeholder.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_image_preview_style.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

mixin ChatListItemMixin {
  FutureBuilder<String> textContentWidget(
    Room room,
    BuildContext context,
    bool isGroup,
    bool unread,
  ) {
    return FutureBuilder<String>(
      future: room.lastEvent?.calcLocalizedBody(
            MatrixLocals(L10n.of(context)!),
            hideReply: true,
            hideEdit: true,
            plaintextBody: true,
            removeMarkdown: true,
            removeBreakLine: true,
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

  RenderObjectWidget lastSenderWidget(Room room, bool isGroup) {
    return isGroup
        ? Row(
            children: [
              Expanded(
                child: FutureBuilder<User?>(
                  future: room.lastEvent?.fetchSenderUser(),
                  builder: (context, snapshot) {
                    if (snapshot.data == null) return const SizedBox.shrink();
                    return Text(
                      snapshot.data!.calcDisplayname(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: ChatLitSubSubtitleTextStyleView.textStyle
                          .textStyle(room, context),
                    );
                  },
                ),
              ),
              const Spacer(),
            ],
          )
        : const SizedBox.shrink();
  }

  Widget chatListItemSubtitleForGroup({
    required BuildContext context,
    required Room room,
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
      future: room.lastEvent?.fetchSenderUser(),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox.shrink();
        final subscriptions = room.lastEvent?.calcLocalizedBodyFallback(
              MatrixLocals(L10n.of(context)!),
              hideReply: true,
              hideEdit: true,
              plaintextBody: true,
              removeMarkdown: true,
              removeBreakLine: true,
            ) ??
            L10n.of(context)!.emptyChat;
        if (room.lastEvent?.isAFile == true) {
          return Text(
            "${snapshot.data!.calcDisplayname()}: ${room.lastEvent?.filename ?? subscriptions}",
            softWrap: false,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ChatLitSubSubtitleTextStyleView.textStyle
                .textStyle(room, context),
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snapshot.data!.calcDisplayname(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
              style: ListItemStyle.subtitleTextStyle(
                fontFamily: 'Inter',
              ).copyWith(
                color: LinagoraSysColors.material().onSurface,
              ),
            ),
            room.lastEvent?.messageType == MessageTypes.Image ||
                    room.lastEvent?.messageType == MessageTypes.Video
                ? chatListItemMediaPreviewSubTitle(
                    context,
                    room,
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
      },
    );
  }

  Widget chatListItemMediaPreviewSubTitle(
    BuildContext context,
    Room room,
  ) {
    return Row(
      children: [
        if (room.lastEvent?.status != EventStatus.synced)
          const SizedBox.shrink()
        else
          SizedBox(
            height: SubtitleImagePreviewStyle.height,
            width: SubtitleImagePreviewStyle.width,
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(SubtitleImagePreviewStyle.borderRadius),
              child: MxcImage(
                key: ValueKey(room.lastEvent!.eventId),
                cacheKey: room.lastEvent!.eventId,
                event: room.lastEvent!,
                placeholder: (context) => ImagePlaceholder(
                  event: room.lastEvent!,
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
            room.lastEvent!.messageType == MessageTypes.Image
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
    return room.notificationCount > 0 || room.hasNewMessages;
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
