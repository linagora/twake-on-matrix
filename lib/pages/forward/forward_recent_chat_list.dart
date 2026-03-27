import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/pages/forward/recent_chat_list_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

class ForwardRecentChatList extends StatelessWidget {
  const ForwardRecentChatList({
    super.key,
    required this.rooms,
    required this.recentChatScrollController,
    required this.onSelectedChat,
    required this.selectedChatNotifier,
  });

  final List<Room> rooms;

  final ScrollController recentChatScrollController;

  final ValueNotifier<List<String>> selectedChatNotifier;

  final void Function(String roomId) onSelectedChat;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: selectedChatNotifier,
      builder: (context, selectedChats, child) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          controller: recentChatScrollController,
          itemCount: rooms.length,
          itemBuilder: (BuildContext context, int index) {
            final room = rooms[index];
            return Material(
              borderRadius: RecentChatListStyle.borderRadiusItem,
              color: LinagoraRefColors.material().primary[100],
              child: InkWell(
                borderRadius: RecentChatListStyle.borderRadiusItem,
                onTap: () => onSelectedChat(room.id),
                child: Padding(
                  padding: RecentChatListStyle.paddingVerticalBetweenItem,
                  child: Row(
                    children: [
                      Checkbox(
                        value: selectedChats.contains(room.id),
                        onChanged: (_) => onSelectedChat(room.id),
                      ),
                      Avatar(
                        mxContent: room.avatar,
                        name: room.getLocalizedDisplayname(
                          MatrixLocals(L10n.of(context)!),
                        ),
                        onTap: null,
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              RecentChatListStyle.paddingHorizontalBetweenItem,
                          child: ChatListItemTitle(room: room),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
