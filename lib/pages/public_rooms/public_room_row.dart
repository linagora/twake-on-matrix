import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/list_item/linagora_avatar_list_item.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/public_rooms/public_room_kind_badge.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';

class PublicRoomRow extends StatelessWidget {
  const PublicRoomRow({
    super.key,
    required this.room,
    required this.isRequested,
    required this.onTap,
  });

  final PublicRoom room;
  final bool isRequested;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final access = isRequested
        ? l10n.publicGroupRequestSentMembers(room.memberCount)
        : room.access == PublicRoomAccess.approval
        ? l10n.askToJoinPublicGroupMembers(room.memberCount)
        : l10n.joinPublicGroupMembers(room.memberCount);
    final topic = room.topic;
    return LinagoraAvatarListItem(
      avatar: AvatarWithKindBadge(
        mxContent: room.avatarUri,
        name: room.name,
        badge: room.kindBadge,
      ),
      title: room.name,
      subtitle: topic == null || topic.isEmpty ? access : '$access · $topic',
      onTap: onTap,
    );
  }
}
