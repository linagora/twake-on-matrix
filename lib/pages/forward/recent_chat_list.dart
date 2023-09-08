import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RecentChatList extends StatelessWidget {
  const RecentChatList({
    super.key,
    required this.rooms,
    required this.recentChatScrollController,
    required this.selectedEventsNotifier,
    required this.onSelectedChat,
  });

  final List<Room> rooms;

  final ScrollController recentChatScrollController;

  final ValueNotifier<List<String>> selectedEventsNotifier;

  final void Function(String roomId) onSelectedChat;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: selectedEventsNotifier,
      builder: (context, selectedEvents, child) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          controller: recentChatScrollController,
          itemCount: rooms.length,
          itemBuilder: (BuildContext context, int index) {
            final room = rooms[index];
            final selected = selectedEvents.contains(room.id);
            return Material(
              borderRadius: BorderRadius.circular(16.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: () => onSelectedChat(room.id),
                child: Row(
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: (value) => onSelectedChat(room.id),
                      fillColor: MaterialStatePropertyAll(
                        Theme.of(context).primaryColor,
                      ),
                      side: BorderSide(
                        width: 2.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
                        padding: const EdgeInsetsDirectional.only(
                          top: 8.0,
                          bottom: 8.0,
                          start: 8.0,
                          end: 6.0,
                        ),
                        child: Column(
                          children: [
                            ChatListItemTitle(room: room),
                            ChatListItemSubtitle(room: room),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
