import 'package:fluffychat/pages/chat_list/chat_list_item_mixin.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

class ChatListItemTitle extends StatelessWidget with ChatListItemMixin {
  final Room room;

  const ChatListItemTitle({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final displayname = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final unread = room.isUnread || room.membership == Membership.invite;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayname,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.titleMedium?.merge(
                            TextStyle(
                              overflow: TextOverflow.ellipsis,
                              letterSpacing:
                                  ChatListItemStyle.letterSpaceDisplayname,
                              color: unread
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                  : ChatListItemStyle.readMessageColor,
                            ),
                          ),
                    ),
                  ),
                  if (room.isFavourite)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.push_pin_outlined,
                        size: ChatListItemStyle.readIconSize,
                        color: ChatListItemStyle.readIconColor,
                      ),
                    ),
                  if (isMuted)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(
                        Icons.volume_off_outlined,
                        size: ChatListItemStyle.readIconSize,
                        color: ChatListItemStyle.readIconColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            room.timeCreated.localizedTimeShort(context),
            style: Theme.of(context).textTheme.labelSmall?.merge(
                  TextStyle(
                    letterSpacing: 0.5,
                    color: unread
                        ? Theme.of(context).colorScheme.onSurface
                        : LinagoraRefColors.material().neutral[50],
                  ),
                ),
          ),
        )
      ],
    );
  }
}
