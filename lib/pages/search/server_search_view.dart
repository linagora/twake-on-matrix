import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/server_search_view_style.dart';
import 'package:fluffychat/presentation/decorators/chat_list/subtitle_text_style_decorator/subtitle_text_style_view.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_empty_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_search.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/search/empty_search_widget.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

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
        builder: (context, serverSearchNotifier, child) {
          if (serverSearchNotifier is PresentationServerSideEmptySearch) {
            if (searchController.searchContactAndRecentChatController!
                    .recentAndContactsNotifier.value.isEmpty &&
                !(searchController.isSearchMatrixUserId)) {
              return child!;
            }
            return const SizedBox.shrink();
          }

          if (serverSearchNotifier is PresentationServerSideSearch) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: serverSearchNotifier.searchResults.length,
              padding: ServerSearchViewStyle.paddingListItem,
              itemBuilder: ((context, index) {
                final searchResult =
                    serverSearchNotifier.searchResults[index].result;
                final room = Matrix.of(context).client.getRoomById(
                      searchResult?.roomId ?? '',
                    );
                if (room == null || searchResult == null) {
                  return const SizedBox.shrink();
                }
                final searchWord = searchController.searchWord;
                final event = Event.fromMatrixEvent(searchResult, room);
                final originServerTs = searchResult.originServerTs;

                return TwakeInkWell(
                  onTap: () =>
                      context.goToRoomWithEvent(event.room.id, event.eventId),
                  child: TwakeListItem(
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
                                  style: ChatLitSubSubtitleTextStyleView
                                      .textStyle
                                      .textStyle(room, context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }

          return const SizedBox();
        },
        child: const EmptySearchWidget(),
      ),
    );
  }
}
