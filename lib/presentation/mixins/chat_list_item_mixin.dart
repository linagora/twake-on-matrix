import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
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
          style: ChatLitSubSubtitleTextStyleView.textStyle.textStyle(room),
        );
      },
    );
  }

  Widget typingTextWidget(String typingText, BuildContext context) {
    final displayedTypingText = "~ $typingText…";
    return Text(
      displayedTypingText,
      style: Theme.of(context).textTheme.labelLarge?.merge(
            TextStyle(
              overflow: TextOverflow.ellipsis,
              color: LinagoraRefColors.material().secondary,
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
                          .textStyle(room),
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
        style: ChatLitSubSubtitleTextStyleView.textStyle.textStyle(room),
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

        return Text(
          "${snapshot.data!.calcDisplayname()}: $subscriptions",
          softWrap: false,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ChatLitSubSubtitleTextStyleView.textStyle.textStyle(room),
        );
      },
    );
  }
}
