import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/search/server_search_state.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/server_search_view_style.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_view.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_event_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:flutter/material.dart' hide SearchController;

class ServerSearchMessagesList extends StatelessWidget {
  final SearchController searchController;

  const ServerSearchMessagesList({
    super.key,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ValueListenableBuilder(
        valueListenable:
            searchController.serverSearchController.serverSearchNotifier,
        builder: ((context, searchResults, child) {
          final messagesFound =
              searchResults.getSuccessOrNull<ServerSearchChatSuccess>();
          if (messagesFound == null ||
              messagesFound.results == null ||
              messagesFound.results!.isEmpty) {
            return const SizedBox();
          }

          return Padding(
            padding: ServerSearchViewStyle.paddingList,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: messagesFound.results!.length,
              padding: ServerSearchViewStyle.paddingListItem,
              itemBuilder: ((context, index) {
                final searchResult = messagesFound.results?[index].result;
                final room = searchResult?.getRoom(context);
                if (room == null || searchResult == null) {
                  return const SizedBox.shrink();
                }
                final searchWord = searchController.searchWord;
                final event = Event.fromMatrixEvent(searchResult, room);
                final originServerTs = searchResult.originServerTs;

                return Padding(
                  padding: ServerSearchViewStyle.paddingInsideListItem,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: ServerSearchViewStyle.paddingAvatar,
                        child: Avatar(
                          mxContent: room.avatar,
                          name: room.name,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChatListItemTitle(
                              room: room,
                              originServerTs: originServerTs,
                            ),
                            HighlightText(
                              text: searchController.getBodyText(
                                event,
                                searchWord,
                              ),
                              searchWord: searchWord,
                              maxLines: 2,
                              style: ChatLitSubSubtitleTextStyleView.textStyle
                                  .textStyle(room),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
