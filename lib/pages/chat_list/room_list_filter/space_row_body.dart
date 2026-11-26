import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';

/// What the row of a space says after its avatar: its name, how many rooms it
/// holds and how many are unread, then its fold.
class SpaceRowBody extends StatelessWidget {
  const SpaceRowBody({
    super.key,
    required this.name,
    required this.space,
    required this.isPinned,
    required this.isInvitation,
  });

  final String name;
  final SpaceRowData space;
  final bool isPinned;
  final bool isInvitation;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final small = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ListItemStyle.titleTextStyle().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isPinned)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: Icon(
                        Icons.push_pin_outlined,
                        size: ChatListItemStyle.readIconSize,
                        color: ChatListItemStyle.pinnedIconColor,
                      ),
                    ),
                ],
              ),
              if (isInvitation)
                Text(
                  l10n.invited,
                  style: small?.copyWith(
                    color: LinagoraSysColors.material().primary,
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    text: l10n.spaceRoomCount(space.roomCount),
                    children: [
                      if (space.unreadCount > 0) ...[
                        const TextSpan(text: ' · '),
                        TextSpan(
                          text: l10n.spaceUnreadCount(space.unreadCount),
                          style: TextStyle(
                            color: LinagoraSysColors.material().primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: small,
                ),
            ],
          ),
        ),
        if (space.fold != SpaceFold.none)
          LinagoraIconButton(
            icon: space.fold == SpaceFold.open
                ? Icons.expand_less
                : Icons.expand_more,
            color: ChatListItemStyle.pinnedIconColor,
            tooltip: space.fold == SpaceFold.open
                ? l10n.hideRoomsOf(name)
                : l10n.showRoomsOf(name),
            onPressed: space.onToggleFold,
          ),
      ],
    );
  }
}
