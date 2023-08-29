import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/pages/forward/forward_item_style.dart';
import 'package:fluffychat/pages/forward/selectable_chat_list_item_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class SelectableChatListItem extends StatelessWidget {
  final Room room;
  final bool selected;
  final void Function()? onTap;

  const SelectableChatListItem(
    this.room, {
    this.selected = false,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayName = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return Material(
      borderRadius: BorderRadius.circular(16.0),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              SizedBox(
                width: ForwardItemStyle.avatarSize,
                child: Stack(
                  children: [
                    Avatar(
                      size: ForwardItemStyle.avatarSize,
                      mxContent: room.avatar,
                      name: displayName,
                    ),
                    if (selected)
                      Positioned(
                        right: SelectableChatListItemStyle
                            .rightFromAvatarBottomRight,
                        bottom: SelectableChatListItemStyle
                            .bottomFromAvatarBottomRight,
                        child: Container(
                          width: ForwardItemStyle.selectedContainerSize,
                          height: ForwardItemStyle.selectedContainerSize,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: ForwardItemStyle.selectedIconSize,
                            color: LinagoraSysColors.material().primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        overflow: TextOverflow.ellipsis,
                        letterSpacing:
                            SelectableChatListItemStyle.letterSpacing,
                        color: room.isUnread ||
                                room.membership == Membership.invite
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : ChatListItemStyle.readMessageColor,
                      ),
                ),
              ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
