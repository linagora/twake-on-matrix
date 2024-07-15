import 'package:fluffychat/pages/chat/events/images_builder/image_placeholder.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_image_preview_style.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/style/linagora_text_style.dart';
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
          style: LinagoraTextStyle.material().bodyMedium3.copyWith(
                color: LinagoraRefColors.material().tertiary[30],
              ),
        );
      },
    );
  }

  Widget typingTextWidget(String typingText, BuildContext context) {
    final displayedTypingText = "$typingText…";
    return Text(
      displayedTypingText,
      style: LinagoraTextStyle.material().bodyMedium2.merge(
            TextStyle(
              overflow: TextOverflow.ellipsis,
              color: LinagoraRefColors.material().tertiary[30],
            ),
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
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
            ),
            room.lastEvent?.messageType == MessageTypes.Image ||
                    room.lastEvent?.messageType == MessageTypes.Video
                ? chatlistItemMediaPreviewSubTitle(
                    context,
                    room,
                  )
                : Text(
                    subscriptions,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LinagoraTextStyle.material().bodyMedium3.copyWith(
                          color: LinagoraRefColors.material().tertiary[30],
                        ),
                  ),
          ],
        );
      },
    );
  }

  Widget chatlistItemMediaPreviewSubTitle(
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
            style: LinagoraTextStyle.material()
                .bodyMedium3
                .copyWith(color: LinagoraRefColors.material().tertiary[30]),
          ),
        ),
      ],
    );
  }
}
