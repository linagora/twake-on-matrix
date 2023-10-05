import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title_style.dart';
import 'package:fluffychat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ChatListItemTitle extends StatelessWidget with ChatListItemMixin {
  final Room room;

  const ChatListItemTitle({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final displayName = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    final typingText = room.getLocalizedTypingText(context);
    final isMuted = room.pushRuleState != PushRuleState.notify;
    final unread = room.isUnread || room.membership == Membership.invite;
    final ownLastMessage =
        room.lastEvent?.senderId == Matrix.of(context).client.userID;
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
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: unread
                          ? LinagoraTextStyle.material()
                              .bodyLarge1
                              .merge(
                                FluffyThemes.fallbackTextStyle,
                              )
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                          : LinagoraTextStyle.material()
                              .bodyLarge2
                              .merge(
                                FluffyThemes.fallbackTextStyle,
                              )
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                  ),
                  if (room.isFavourite)
                    Padding(
                      padding: ChatListItemTitleStyle.paddingLeftIcon,
                      child: Icon(
                        Icons.push_pin_outlined,
                        size: ChatListItemStyle.readIconSize,
                        color: ChatListItemStyle.readIconColor,
                      ),
                    ),
                  if (isMuted)
                    Padding(
                      padding: ChatListItemTitleStyle.paddingLeftIcon,
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
          padding: ChatListItemTitleStyle.paddingLeftIcon,
          child: Row(
            children: [
              if (typingText.isEmpty &&
                  ownLastMessage &&
                  room.lastEvent!.status.isSending) ...[
                Icon(
                  Icons.schedule,
                  color: LinagoraRefColors.material().neutral[50],
                  size: ChatListItemTitleStyle.iconScheduleSize,
                ),
              ],
              Padding(
                padding: ChatListItemTitleStyle.paddingLeftIcon,
                child: Text(
                  room.timeCreated.localizedTimeShort(context),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: unread
                            ? Theme.of(context).colorScheme.onSurface
                            : LinagoraRefColors.material().neutral[50],
                      ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
