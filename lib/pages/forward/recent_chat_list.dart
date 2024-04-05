import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/pages/forward/recent_chat_list_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RecentChatList extends StatelessWidget {
  const RecentChatList({
    super.key,
    required this.rooms,
    required this.recentChatScrollController,
    required this.onSelectedChat,
    required this.selectedChatNotifier,
  });

  final List<Room> rooms;

  final ScrollController recentChatScrollController;

  final ValueNotifier<String> selectedChatNotifier;

  final void Function(String roomId) onSelectedChat;

  static const durationToggleItem = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedChatNotifier,
      builder: (context, selectedChat, child) {
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
                      Radio<String>(
                        groupValue: room.id,
                        value: selectedChat,
                        onChanged: (value) => onSelectedChat(room.id),
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
                          child: Column(
                            children: [
                              ChatListItemTitle(room: room),
                              ChatListItemSubtitle(room: room),
                            ],
                          ),
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
