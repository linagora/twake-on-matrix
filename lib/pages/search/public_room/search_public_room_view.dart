import 'package:fluffychat/pages/search/public_room/empty_search_public_room_widget.dart';
import 'package:fluffychat/pages/search/public_room/search_public_room_view_style.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room.dart';
import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room_empty.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter/material.dart' hide SearchController;

class SearchPublicRoomList extends StatelessWidget {
  final SearchController searchController;

  const SearchPublicRoomList({
    super.key,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ValueListenableBuilder(
        valueListenable:
            searchController.searchPublicRoomController.searchResultsNotifier,
        builder: (context, searchPublicRoomNotifier, child) {
          if (searchPublicRoomNotifier is PresentationSearchPublicRoomEmpty) {
            final genericSearchTerm =
                searchController.searchPublicRoomController.genericSearchTerm;
            if (genericSearchTerm != null || genericSearchTerm!.isNotEmpty) {
              return EmptySearchPublicRoomWidget(
                genericSearchTerm: genericSearchTerm,
                onTapJoin: () =>
                    searchController.searchPublicRoomController.joinRoom(
                  context,
                  genericSearchTerm,
                  searchController.searchPublicRoomController
                      .getServerName(genericSearchTerm),
                ),
              );
            }
            return child!;
          }

          if (searchPublicRoomNotifier is PresentationSearchPublicRoom) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: searchPublicRoomNotifier.searchResults.length,
              padding: SearchPublicRoomViewStyle.paddingListItem,
              itemBuilder: ((context, index) {
                final room = searchPublicRoomNotifier.searchResults[index];
                final action = searchController.searchPublicRoomController
                    .getAction(context, room);
                return Padding(
                  padding: SearchPublicRoomViewStyle.paddingListItem,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: SearchPublicRoomViewStyle.paddingAvatar,
                        child: Avatar(
                          mxContent: room.avatarUrl,
                          name: room.name,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name ?? room.roomId,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                              style:
                                  SearchPublicRoomViewStyle.roomNameTextStyle,
                            ),
                            const SizedBox(
                              height:
                                  SearchPublicRoomViewStyle.nameToButtonSpace,
                            ),
                            Text(
                              room.canonicalAlias ?? room.roomId,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                              style:
                                  SearchPublicRoomViewStyle.roomAliasTextStyle,
                            ),
                          ],
                        ),
                      ),
                      if (action != null)
                        TwakeTextButton(
                          message: action.getLabel(context),
                          styleMessage: action.getLabelStyle(context),
                          paddingAll: SearchPublicRoomViewStyle.paddingButton,
                          onTap: () => searchController
                              .searchPublicRoomController
                              .handlePublicRoomActions(
                            context,
                            room,
                            action,
                          ),
                          hoverColor: Colors.transparent,
                          buttonDecoration:
                              SearchPublicRoomViewStyle.actionButtonDecoration(
                            context,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            );
          }

          return child!;
        },
        child: const SizedBox(),
      ),
    );
  }
}
