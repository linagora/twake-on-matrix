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
            searchController.serverSearchController.searchResultsNotifier,
        builder: (context, severSearchNotifier, child) {
          if (severSearchNotifier.searchResults.isEmpty) {
            return child!;
          }
          return Padding(
            padding: ServerSearchViewStyle.paddingList,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: severSearchNotifier.searchResults.length,
              padding: ServerSearchViewStyle.paddingListItem,
              itemBuilder: ((context, index) {
                final searchResult =
                    severSearchNotifier.searchResults[index].result;
                final room = searchResult?.getRoom(context);
                if (room == null || searchResult == null) {
                  return const SizedBox.shrink();
                }
                final searchWord = searchController.searchWord;
                final event = Event.fromMatrixEvent(searchResult, room);
                final originServerTs = searchResult.originServerTs;

                return InkWell(
                  onTap: () => searchController.goToEvent(context, event),
                  borderRadius: ServerSearchViewStyle.itemBorderRadius,
                  child: Padding(
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
                  ),
                );
              }),
            ),
          );
        },
        child: const SizedBox(),
      ),
    );
  }
}
