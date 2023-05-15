import 'package:fluffychat/pages/chat/chat_app_bar_title_style.dart';
import 'package:fluffychat/utils/room_status_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/user_bottom_sheet/user_bottom_sheet.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';

class ChatAppBarTitle extends StatelessWidget {
  final ChatController controller;

  const ChatAppBarTitle(this.controller, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final room = controller.room;
    if (room == null) {
      return Container();
    }
    if (controller.selectedEvents.isNotEmpty) {
      return Text(controller.selectedEvents.length.toString());
    }
    final directChatMatrixID = room.directChatMatrixID;
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: directChatMatrixID != null
          ? () => showAdaptiveBottomSheet(
                context: context,
                builder: (c) => UserBottomSheet(
                  user: room
                      .unsafeGetUserFromMemoryOrFallback(directChatMatrixID),
                  outerContext: context,
                  onMention: () => controller.sendController.text +=
                      '${room.unsafeGetUserFromMemoryOrFallback(directChatMatrixID).mention} ',
                ),
              )
          : controller.isArchived
              ? null
              : () =>
                  VRouter.of(context).toSegments(['rooms', room.id, 'details']),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 3, top: 3),
                  child: Hero(
                    tag: 'content_banner',
                    child: Avatar(
                      fontSize: ChatAppBarTitleStyle.avatarFontSize,
                      mxContent: room.avatar,
                      name: room.getLocalizedDisplayname(
                        MatrixLocals(L10n.of(context)!),
                      ),
                      size: ChatAppBarTitleStyle.avatarSize,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: room.isDirectChat == true
                      ? Container(
                          width: ChatAppBarTitleStyle.statusSize,
                          height: ChatAppBarTitleStyle.statusSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: ChatAppBarTitleStyle.statusBorderColor,
                              width: ChatAppBarTitleStyle.statusBorderSize,
                            ),
                            color:
                                room.directChatPresence?.currentlyActive == true
                                    ? ChatAppBarTitleStyle.currentlyActiveColor
                                    : ChatAppBarTitleStyle.currentlyInactiveColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.getLocalizedDisplayname(MatrixLocals(L10n.of(context)!)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: ChatAppBarTitleStyle.letterSpacingRoomName
                    ),
                  ),
                  _buildStatusContent(context, room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildStatusContent(BuildContext context, Room room) {
    if (room.getLocalizedTypingText(context).isEmpty) {
      return Text(
        room.getLocalizedStatus(context).capitalize(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Theme.of(context).colorScheme.tertiary,
          letterSpacing: ChatAppBarTitleStyle.letterSpacingStatusContent
        ),
      );
    } else {
      return Row(
        children: [
          Image.asset(
            'assets/typing.gif',
            height: 10,
            color: Theme.of(context).colorScheme.onPrimary,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 8),
          Text(
            room.getLocalizedTypingText(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5
            ),
          )
        ],
      );
    }
  }
}
