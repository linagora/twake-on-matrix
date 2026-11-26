import 'package:collection/collection.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:twake_chat/pages/chat/chat_app_bar_title_style.dart';
import 'package:twake_chat/pages/chat/typing_timer_wrapper.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/utils/common_helper.dart';
import 'package:twake_chat/utils/room_status_extension.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:twake_chat/widgets/connection_status_header.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/presentation/extensions/person_presence_extension.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

class ChatAppBarTitle extends StatelessWidget {
  final Widget? actions;
  final Room? room;
  final List<Event> selectedEvents;
  final bool isArchived;
  final TextEditingController sendController;
  final Stream<ConnectivityResult> connectivityResultStream;
  final VoidCallback onPushDetails;
  final String? roomName;

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
  });

  String _getRoomName(BuildContext context, List<UnifiedContact> contacts) {
    final localizedRoomName = room?.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return resolveChatAppBarTitle(
      directChatMatrixId: room?.directChatMatrixID,
      fallbackRoomName: roomName,
      localizedRoomName: localizedRoomName,
      contacts: contacts,
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
      child: Consumer(
        child: ConnectionStatusHeader(
          connectedWidget: _ChatAppBarStatusContent(
            connectivityResultStream: connectivityResultStream,
            room: room!,
          ),
        ),
        builder: (context, ref, statusContent) {
          final contacts =
              ref.watch(contactsControllerProvider).asData?.value ??
              const <UnifiedContact>[];
          final resolvedRoomName = _getRoomName(context, contacts);
          return Row(
            children: [
              Padding(
                padding: ChatAppBarTitleStyle.avatarPadding,
                child: Hero(
                  tag: 'content_banner',
                  child: _ChatAppBarAvatar(room: room!, name: resolvedRoomName),
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
                              Assets.images.icEncrypted.path,
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
  });

  final Stream<ConnectivityResult> connectivityResultStream;
  final Room room;

  @override
  Widget build(BuildContext context) {
    final peerId = room.directChatMatrixID;
    if (peerId != null) {
      return DirectChatAppBarStatusContent(
        connectivityResultStream: connectivityResultStream,
        room: room,
        peerId: peerId,
      );
    }

    return _GroupChatAppBarStatusContent(
      connectivityResultStream: connectivityResultStream,
      room: room,
    );
  }
}

class _ChatAppBarAvatar extends StatelessWidget {
  const _ChatAppBarAvatar({required this.room, required this.name});

  final Room room;
  final String name;

  @override
  Widget build(BuildContext context) {
    final size = ChatAppBarTitleStyle.avatarSize(context);
    final avatar = Avatar(
      fontSize: ChatAppBarTitleStyle.avatarFontSize,
      mxContent: room.avatar,
      name: name,
      size: size,
    );
    final peerId = room.directChatMatrixID;
    if (peerId == null) return avatar;
    return ChatAppBarPresenceBadge(peerId: peerId, size: size, child: avatar);
  }
}

@visibleForTesting
class ChatAppBarPresenceBadge extends ConsumerWidget {
  const ChatAppBarPresenceBadge({
    super.key,
    required this.peerId,
    required this.size,
    required this.child,
  });

  final String peerId;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presence = ref.watch(personPresenceProvider(peerId)).value;
    return LinagoraPresenceBadge(
      presence: presence?.badge,
      size: size,
      style: ChatAppBarTitleStyle.presenceBadgeStyle(context),
      child: child,
    );
  }
}

@visibleForTesting
class DirectChatAppBarStatusContent extends ConsumerWidget {
  const DirectChatAppBarStatusContent({
    super.key,
    required this.connectivityResultStream,
    required this.room,
    required this.peerId,
  });

  final Stream<ConnectivityResult> connectivityResultStream;
  final Room room;
  final String peerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context)!;
    final presence = ref.watch(personPresenceProvider(peerId));
    return StreamBuilder(
      stream: connectivityResultStream,
      builder: (context, connectivitySnapshot) {
        if (connectivitySnapshot.data == ConnectivityResult.none) {
          return ChatAppBarTitleText(text: l10n.noConnection);
        }
        if (presence.isLoading) {
          return ChatAppBarTitleText(text: l10n.loadingStatus);
        }
        final subtitle =
            presence.value?.localizedSubtitle(l10n) ?? l10n.offline;
        return TypingTimerWrapper(
          room: room,
          l10n: l10n,
          typingWidget: _ChatAppBarTitleTyping(
            typingText: room.getLocalizedTypingText(l10n),
          ),
          notTypingWidget: ChatAppBarTitleText(
            text: subtitle.capitalize(context),
          ),
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
  required List<UnifiedContact> contacts,
}) {
  if (directChatMatrixId == null) {
    return fallbackRoomName ?? localizedRoomName ?? '';
  }
  final availableContact = contacts.firstWhereOrNull(
    (contact) => contact.matrixId == directChatMatrixId,
  );
  return availableContact?.resolvedDisplayName ?? localizedRoomName ?? '';
}
