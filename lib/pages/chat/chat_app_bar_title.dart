import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/common_helper.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';

class ChatAppBarTitle extends StatelessWidget {
  final Widget? actions;
  final Room? room;
  final List<Event> selectedEvents;
  final bool isArchived;
  final TextEditingController sendController;
  final Stream<ConnectivityResult> connectivityResultStream;
  final VoidCallback onPushDetails;
  final String? roomName;
  final ValueNotifier<CachedPresence?> cachedPresenceNotifier;
  final StreamController<CachedPresence>? cachedPresenceStreamController;

  const ChatAppBarTitle({
    super.key,
    required this.actions,
    this.room,
    this.roomName,
    required this.selectedEvents,
    required this.isArchived,
    required this.sendController,
    required this.connectivityResultStream,
    required this.onPushDetails,
    required this.cachedPresenceNotifier,
    this.cachedPresenceStreamController,
  });

  @override
  Widget build(BuildContext context) {
    if (room == null) {
      return Container();
    }
    if (selectedEvents.isNotEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(selectedEvents.length.toString()),
          actions ?? const SizedBox.shrink(),
        ],
      );
    }
    return InkWell(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: isArchived ? null : onPushDetails,
      child: Row(
        children: [
          Padding(
            padding: ChatAppBarTitleStyle.avatarPadding,
            child: Stack(
              children: [
                Hero(
                  tag: 'content_banner',
                  child: Avatar(
                    fontSize: ChatAppBarTitleStyle.avatarFontSize,
                    mxContent: room!.avatar,
                    name: roomName ??
                        room!.getLocalizedDisplayname(
                          MatrixLocals(L10n.of(context)!),
                        ),
                    size: ChatAppBarTitleStyle.avatarSize(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (room?.encrypted == true) ...[
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: SvgPicture.asset(
                          ImagePaths.icEncrypted,
                          width: 16,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        roomName ??
                            room!.getLocalizedDisplayname(
                              MatrixLocals(L10n.of(context)!),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ChatAppBarTitleStyle.appBarTitleStyle(context),
                      ),
                    ),
                  ],
                ),
                _ChatAppBarStatusContent(
                  connectivityResultStream: connectivityResultStream,
                  room: room!,
                  cachedPresenceNotifier: cachedPresenceNotifier,
                  cachedPresenceStreamController:
                      cachedPresenceStreamController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAppBarStatusContent extends StatelessWidget {
  const _ChatAppBarStatusContent({
    required this.connectivityResultStream,
    required this.room,
    required this.cachedPresenceNotifier,
    this.cachedPresenceStreamController,
  });

  final Stream<ConnectivityResult> connectivityResultStream;
  final Room room;
  final ValueNotifier<CachedPresence?> cachedPresenceNotifier;
  final StreamController<CachedPresence>? cachedPresenceStreamController;

  @override
  Widget build(BuildContext context) {
    if (room.isDirectChat) {
      return _DirectChatAppBarStatusContent(
        connectivityResultStream: connectivityResultStream,
        room: room,
        cachedPresenceNotifier: cachedPresenceNotifier,
        cachedPresenceStreamController: cachedPresenceStreamController!,
      );
    }

    return _GroupChatAppBarStatusContent(
      connectivityResultStream: connectivityResultStream,
      room: room,
    );
  }
}

class _DirectChatAppBarStatusContent extends StatelessWidget {
  const _DirectChatAppBarStatusContent({
    required this.connectivityResultStream,
    required this.room,
    required this.cachedPresenceNotifier,
    required this.cachedPresenceStreamController,
  });

  final Stream<ConnectivityResult> connectivityResultStream;
  final Room room;
  final ValueNotifier<CachedPresence?> cachedPresenceNotifier;
  final StreamController<CachedPresence> cachedPresenceStreamController;

  @override
  Widget build(BuildContext context) {
    CachedPresence? directChatPresence = room.directChatPresence;
    return ValueListenableBuilder(
      valueListenable: cachedPresenceNotifier,
      builder: (context, directChatCachedPresence, child) {
        return StreamBuilder(
          stream: connectivityResultStream,
          builder: (context, connectivitySnapshot) {
            return StreamBuilder(
              stream: cachedPresenceStreamController.stream,
              builder: (context, cachedPresenceSnapshot) {
                final connectivityResult = tryCast<ConnectivityResult>(
                  connectivitySnapshot.data,
                  fallback: ConnectivityResult.none,
                );
                directChatPresence = tryCast<CachedPresence>(
                  cachedPresenceSnapshot.data,
                  fallback: directChatCachedPresence,
                );
                if (connectivitySnapshot.hasData &&
                    connectivityResult == ConnectivityResult.none) {
                  return ChatAppBarTitleText(
                    text: L10n.of(context)!.noConnection,
                  );
                }
                if (directChatPresence == null) {
                  return ChatAppBarTitleText(
                    text: L10n.of(context)!.loadingStatus,
                  );
                }
                final typingText = room.getLocalizedTypingText(context);
                if (typingText.isEmpty) {
                  return ChatAppBarTitleText(
                    text: room
                        .getLocalizedStatus(
                          context,
                          presence: directChatPresence,
                        )
                        .capitalize(context),
                  );
                } else {
                  return _ChatAppBarTitleTyping(typingText: typingText);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _GroupChatAppBarStatusContent extends StatelessWidget {
  const _GroupChatAppBarStatusContent({
    required this.connectivityResultStream,
    required this.room,
  });

  final Stream<ConnectivityResult> connectivityResultStream;
  final Room room;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: connectivityResultStream,
      builder: (context, snapshot) {
        final connectivityResult = tryCast<ConnectivityResult>(
          snapshot.data,
          fallback: ConnectivityResult.none,
        );

        if (snapshot.hasData && connectivityResult == ConnectivityResult.none) {
          return ChatAppBarTitleText(text: L10n.of(context)!.noConnection);
        }
        final typingText = room.getLocalizedTypingText(context);
        if (typingText.isEmpty) {
          return ChatAppBarTitleText(
            text: room.getLocalizedStatus(context).capitalize(context),
          );
        } else {
          return _ChatAppBarTitleTyping(typingText: typingText);
        }
      },
    );
  }
}

class ChatAppBarTitleText extends StatelessWidget {
  const ChatAppBarTitleText({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final TextStyle? statusTextStyle = text == L10n.of(context)!.online
        ? ChatAppBarTitleStyle.onlineStatusTextStyle(context)
        : ChatAppBarTitleStyle.offlineStatusTextStyle(context);

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: statusTextStyle,
    );
  }
}

class _ChatAppBarTitleTyping extends StatelessWidget {
  const _ChatAppBarTitleTyping({
    required this.typingText,
  });

  final String typingText;

  @override
  Widget build(BuildContext context) {
    final TextStyle? statusTextStyle =
        ChatAppBarTitleStyle.onlineStatusTextStyle(context);

    return IntrinsicWidth(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              typingText,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: statusTextStyle,
            ),
          ),
          SizedBox(
            width: 32,
            height: 16,
            child: Transform.translate(
              offset: const Offset(0, -2),
              child: LottieBuilder.asset(
                'assets/typing-indicator.zip',
                fit: BoxFit.fitWidth,
                width: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
