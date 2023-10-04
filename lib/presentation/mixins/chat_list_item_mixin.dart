import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
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

  RenderObjectWidget lastSenderWidget(Room room, bool isGroup, bool unread) {
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
              ),
              const Spacer()
            ],
          )
        : const SizedBox.shrink();
  }
}
