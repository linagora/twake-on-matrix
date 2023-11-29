import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title_style.dart';
import 'package:fluffychat/presentation/decorators/chat_list/title_text_style_decorator/title_text_style_view.dart';
import 'package:fluffychat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final isMuted = room.pushRuleState != PushRuleState.notify;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (room.encrypted)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 4, top: 2, bottom: 2),
                      child: SvgPicture.asset(
                        ImagePaths.icEncrypted,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          ChatAppBarTitleStyle.encryptedIconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style:
                          ChatLitTitleTextStyleView.textStyle.textStyle(room),
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
              if (room.isTypingText(context)) ...[
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
                        color: room.isUnreadOrInvited
                            ? Theme.of(context).colorScheme.onSurface
                            : LinagoraRefColors.material().neutral[50],
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
