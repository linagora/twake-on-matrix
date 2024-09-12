import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatListItemAvatar extends StatefulWidget {
  final Room room;
  final void Function()? onTap;
  final JoinedRoomUpdate? joinedRoomUpdate;

  const ChatListItemAvatar({
    required this.room,
    this.onTap,
    this.joinedRoomUpdate,
    super.key,
  });

  @override
  State<ChatListItemAvatar> createState() => _ChatListItemAvatarState();
}

class _ChatListItemAvatarState extends State<ChatListItemAvatar> {
  final ValueNotifier<Uri?> avatarUrlNotifier = ValueNotifier<Uri>(Uri());

  @override
  void initState() {
    avatarUrlNotifier.value = widget.room.avatar ?? Uri();
    super.initState();
  }

  @override
  void dispose() {
    avatarUrlNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatListItemAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joinedRoomUpdate != widget.joinedRoomUpdate) {
      updateAvatarUrlFromJoinedRoomUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return ValueListenableBuilder(
      valueListenable: avatarUrlNotifier,
      builder: (context, avatarUrl, child) {
        return Avatar(
          mxContent: avatarUrl,
          name: displayName,
          onTap: widget.onTap,
        );
      },
    );
  }

  void updateAvatarUrlFromJoinedRoomUpdate() {
    if (isChatHaveAvatarUpdated) {
      if (isGroupChatAvatarUpdated) {
        updateGroupAvatar();
      } else if (isDirectChatAvatarUpdated) {
        updateDirectChatAvatar();
      }
    }
  }

  bool get isChatHaveAvatarUpdated =>
      widget.joinedRoomUpdate?.timeline?.events?.isNotEmpty == true;

  bool get isDirectChatAvatarUpdated {
    return widget.room.isDirectChat &&
        widget.joinedRoomUpdate?.timeline?.events
                ?.where(
                  (event) => event.type == EventTypes.RoomMember,
                )
                .isNotEmpty ==
            true;
  }

  bool get isGroupChatAvatarUpdated =>
      widget.joinedRoomUpdate?.timeline?.events
          ?.where(
            (event) => event.type == EventTypes.RoomAvatar,
          )
          .isNotEmpty ==
      true;

  void updateDirectChatAvatar() {
    final event = widget.joinedRoomUpdate?.timeline?.events?.lastWhere(
      (event) => event.type == EventTypes.RoomMember,
    );
    final avatarMxc = event?.content['avatar_url'];
    if (event?.senderId != widget.room.directChatMatrixID) {
      return;
    }
    updateAvatarUrl(avatarMxc);
  }

  void updateGroupAvatar() {
    final avatarMxc = widget.joinedRoomUpdate?.timeline?.events
        ?.lastWhere(
          (event) => event.type == EventTypes.RoomAvatar,
        )
        .content['url'];
    updateAvatarUrl(avatarMxc);
  }

  void updateAvatarUrl(Object? avatarMxc) {
    if (avatarMxc is String) {
      avatarUrlNotifier.value = Uri.tryParse(avatarMxc) ?? Uri();
    } else if (avatarMxc == null) {
      avatarUrlNotifier.value = Uri();
    }
  }
}
