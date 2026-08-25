import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/chat/events/message/message_style.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin MessageAvatarMixin {
  ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  bool _shouldDisplayAvatar(
    bool sameSender,
    bool ownMessage,
    BuildContext context,
  ) {
    return sameSender && !(ownMessage && responsive.isMobile(context));
  }

  Widget placeHolderWidget(
    Function(Event)? onAvatarTap, {
    required bool sameSender,
    required bool ownMessage,
    required Event event,
    required BuildContext context,
    required bool selectMode,
  }) {
    if (selectMode || event.room.isDirectChat) {
      return const SizedBox.shrink();
    }

    if (_shouldDisplayAvatar(sameSender, ownMessage, context)) {
      return Padding(
        padding: MessageStyle.paddingAvatar,
        child: FutureBuilder<User?>(
          future: event.fetchSenderUser(),
          builder: (context, snapshot) {
            final user = snapshot.data ?? event.senderFromMemoryOrFallback;
            return Avatar(
              size: MessageStyle.avatarSize,
              fontSize: MessageStyle.fontSize,
              mxContent: user.avatarUrl,
              name: user.calcDisplayname(),
              onTap: () => onAvatarTap!(event),
            );
          },
        ),
      );
    }

    return const Padding(
      padding: MessageStyle.paddingAvatar,
      child: SizedBox(width: MessageStyle.avatarSize),
    );
  }
}
