import 'package:fluffychat/pages/search/public_room/search_public_room_view_style.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room.dart';
import 'package:fluffychat/presentation/model/search/public_room/presentation_search_public_room_empty.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:google_fonts/google_fonts.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

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
                return Padding(
                  padding: SearchPublicRoomViewStyle.paddingListItem,
                  child: Padding(
                    padding: SearchPublicRoomViewStyle.paddingInsideListItem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: SearchPublicRoomViewStyle.paddingAvatar,
                          child: Avatar(
                            mxContent: room.avatarUrl,
                            name: room.name,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            room.name ?? room.roomId,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                            style: LinagoraTextStyle.material()
                                .bodyMedium3
                                .copyWith(
                                  color: LinagoraSysColors.material().onSurface,
                                  fontFamily: GoogleFonts.inter().fontFamily,
                                ),
                          ),
                        ),
                      ],
                    ),
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
