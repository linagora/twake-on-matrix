import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/chat_list_header_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_components/twake_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatListHeader extends StatelessWidget {
  final ChatListController controller;
  final Function()? onTapSearch;

  const ChatListHeader({
    Key? key,
    required this.controller,
    this.onTapSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectMode = controller.selectMode;

    return Padding(
      padding: ChatListHeaderStyle.paddingChatListHeader(context),
      child: Column(
        children: [
          TwakeHeader(controller: controller),
          Container(
            height: ChatListHeaderStyle.searchBarContainerHeight,
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                if (selectMode == SelectMode.select)
                  IconButton(
                    tooltip: L10n.of(context)!.cancel,
                    icon: const Icon(Icons.close_outlined),
                    onPressed: controller.cancelAction,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                Expanded(
                  child: selectMode == SelectMode.select
                      ? Text(
                          controller.selectedRoomIds.length.toString(),
                          key: const ValueKey(SelectMode.select),
                        )
                      : SizedBox(
                          height: ChatListHeaderStyle.searchBarHeight,
                          child: InkWell(
                            onTap: onTapSearch,
                            child: TextField(
                              controller: controller.searchChatController,
                              textInputAction: TextInputAction.search,
                              onChanged: controller.onSearchEnter,
                              enabled: false,
                              decoration: InputDecoration(
                                filled: true,
                                contentPadding: const EdgeInsets.all(0),
                                fillColor:
                                    Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(
                                    ChatListHeaderStyle.searchRadiusBorder,
                                  ),
                                ),
                                hintText: L10n.of(context)!.search,
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                prefixIcon: controller.isSearchMode
                                    ? IconButton(
                                        tooltip: L10n.of(context)!.cancel,
                                        icon: const Icon(
                                          Icons.close_outlined,
                                        ),
                                        onPressed: controller.cancelSearch,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      )
                                    : Icon(
                                        Icons.search_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                suffixIcon: controller.isSearchMode
                                    ? controller.isSearching
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 9.0,
                                              horizontal: 14.0,
                                            ),
                                            child: SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator
                                                  .adaptive(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : TextButton(
                                            onPressed: controller.setServer,
                                            style: TextButton.styleFrom(
                                              textStyle: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            child: Text(
                                              controller.searchServer ??
                                                  Matrix.of(context)
                                                      .client
                                                      .homeserver!
                                                      .host,
                                              maxLines: 2,
                                            ),
                                          )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                ),
                if (selectMode == SelectMode.select)
                  IconButton(
                    tooltip: L10n.of(context)!.toggleUnread,
                    icon: Icon(
                      controller.anySelectedRoomNotMarkedUnread
                          ? Icons.mark_chat_read_outlined
                          : Icons.mark_chat_unread_outlined,
                    ),
                    onPressed: controller.toggleUnread,
                  ),
                if (selectMode == SelectMode.select)
                  IconButton(
                    tooltip: L10n.of(context)!.toggleFavorite,
                    icon: Icon(
                      controller.anySelectedRoomNotFavorite
                          ? Icons.push_pin_outlined
                          : Icons.push_pin,
                    ),
                    onPressed: controller.toggleFavouriteRoom,
                  ),
                if (selectMode == SelectMode.select)
                  IconButton(
                    icon: Icon(
                      controller.anySelectedRoomNotMuted
                          ? Icons.notifications_off_outlined
                          : Icons.notifications_outlined,
                    ),
                    tooltip: L10n.of(context)!.toggleMuted,
                    onPressed: controller.toggleMuted,
                  ),
                if (selectMode == SelectMode.select)
                  IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    tooltip: L10n.of(context)!.archive,
                    onPressed: controller.archiveAction,
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
