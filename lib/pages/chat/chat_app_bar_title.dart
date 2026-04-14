import 'dart:async';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/pages/chat/typing_timer_wrapper.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/common_helper.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
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

  String _getRoomName(
    BuildContext context,
    Either<Failure, Success> getContactsState,
  ) {
    final localizedRoomName = room?.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return resolveChatAppBarTitle(
      directChatMatrixId: room?.directChatMatrixID,
      fallbackRoomName: roomName,
      localizedRoomName: localizedRoomName,
      getContactsState: getContactsState,
    );
  }

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
      focusColor: Colors.transparent,
      onTap: isArchived ? null : onPushDetails,
      // Single listener drives both the avatar name and the title text;
      // the status subtree is passed via `child:` so it does not rebuild
      // when the contacts notifier emits.
      child: ValueListenableBuilder(
        valueListenable: getIt.get<ContactsManager>().getContactsNotifier(),
        child: _ChatAppBarStatusContent(
          connectivityResultStream: connectivityResultStream,
          room: room!,
          cachedPresenceNotifier: cachedPresenceNotifier,
          cachedPresenceStreamController: cachedPresenceStreamController,
        ),
        builder: (context, state, statusContent) {
          final resolvedRoomName = _getRoomName(context, state);
          return Row(
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
                        name: resolvedRoomName,
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
                            resolvedRoomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ChatAppBarTitleStyle.appBarTitleStyle(
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                    statusContent!,
                  ],
                ),
              ),
            ],
          );
        },
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
                return TypingTimerWrapper(
                  room: room,
                  l10n: L10n.of(context)!,
                  typingWidget: _ChatAppBarTitleTyping(
                    typingText: room.getLocalizedTypingText(L10n.of(context)!),
                  ),
                  notTypingWidget: ChatAppBarTitleText(
                    text: room
                        .getLocalizedStatus(
                          context,
                          presence: directChatPresence,
                        )
                        .capitalize(context),
                  ),
                );
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
        return TypingTimerWrapper(
          room: room,
          l10n: L10n.of(context)!,
          typingWidget: _ChatAppBarTitleTyping(
            typingText: room.getLocalizedTypingText(L10n.of(context)!),
          ),
          notTypingWidget: ChatAppBarTitleText(
            text: room.getLocalizedStatus(context).capitalize(context),
          ),
        );
      },
    );
  }
}

class ChatAppBarTitleText extends StatelessWidget {
  const ChatAppBarTitleText({super.key, required this.text});

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
  const _ChatAppBarTitleTyping({required this.typingText});

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

/// Resolves the string displayed in the chat app bar title (and used as the
/// avatar fallback text).
///
/// For direct chats, walks the contacts state lazily to find the first
/// [PresentationContact] whose `matrixId` matches [directChatMatrixId], and
/// uses its display name. Falls back to [localizedRoomName] when no contact
/// matches or when the state is not a success.
///
/// Lazy iteration + short-circuit on match is deliberate: do not rebuild a
/// `Set<PresentationContact>` here. `PresentationContact` is `Equatable`
/// with expensive props, and a Set-fold triggers an O(N²) `hashCode` cascade
/// on every rebuild.
@visibleForTesting
String resolveChatAppBarTitle({
  required String? directChatMatrixId,
  required String? fallbackRoomName,
  required String? localizedRoomName,
  required Either<Failure, Success> getContactsState,
}) {
  if (directChatMatrixId == null) {
    return fallbackRoomName ?? localizedRoomName ?? '';
  }
  final availableContact = getContactsState
      .getSuccessOrNull<GetContactsSuccess>()
      ?.contacts
      .expand((contact) => contact.toPresentationContacts())
      .firstWhereOrNull((contact) => contact.matrixId == directChatMatrixId);
  return availableContact?.displayName ?? localizedRoomName ?? '';
}
