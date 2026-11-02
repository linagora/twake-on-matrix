import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item_style.dart';
import 'package:twake_chat/pages/space_home/open_space_child.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

/// A sub-space of a space the user may join: a press joins and opens it.
class JoinableSubspaceRow extends ConsumerWidget {
  const JoinableSubspaceRow({super.key, required this.row});

  final RoomListJoinableRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subspace = row.subspace;
    return Padding(
      padding: ChatListItemStyle.padding,
      child: TwakeInkWell(
        isSelected: false,
        onTap: () => openSpaceChild(
          context,
          ref,
          parentSpaceId: row.parentSpaceId,
          child: subspace,
        ),
        child: TwakeListItem(
          child: Container(
            height: ChatListItemStyle.spaceItemHeight,
            padding: ChatListItemStyle.paddingBody.add(
              EdgeInsetsDirectional.only(
                start: row.depth * ChatListItemStyle.depthIndent,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: ChatListItemStyle.paddingAvatar,
                  child: Avatar(
                    mxContent: subspace.avatar,
                    name: subspace.name,
                    size: ChatListItemStyle.childAvatarSize,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subspace.name,
                        overflow: TextOverflow.ellipsis,
                        style: ListItemStyle.titleTextStyle(),
                      ),
                      Text(
                        L10n.of(context)!.joinWithMembers(subspace.memberCount),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
