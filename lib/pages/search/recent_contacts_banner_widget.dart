import 'package:fluffychat/pages/search/recent_contacts_banner_widget_style.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/utils/display_name_widget.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PreSearchRecentContactsContainer extends StatelessWidget {
  final SearchController searchController;
  final List<Room> recentRooms;
  const PreSearchRecentContactsContainer({
    super.key,
    required this.searchController,
    required this.recentRooms,
  });

  @override
  Widget build(BuildContext context) {
    if (recentRooms.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: ListView.builder(
          padding: RecentContactsBannerWidgetStyle
              .chatRecentContactHorizontalPadding,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: recentRooms.length,
          itemBuilder: (context, index) {
            return PreSearchRecentContactWidget(
              room: recentRooms[index],
            );
          },
        ),
      );
    }
  }
}

class PreSearchRecentContactWidget extends StatelessWidget {
  final Room room;
  const PreSearchRecentContactWidget({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return InkWell(
      onTap: () => context.go('/rooms/${room.id}'),
      child: SizedBox(
        width: RecentContactsBannerWidgetStyle.chatRecentContactItemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: RecentContactsBannerWidgetStyle.avatarWidthSize,
              height: RecentContactsBannerWidgetStyle.avatarWidthSize,
              child: Avatar(
                mxContent: room.avatar,
                name: displayName,
              ),
            ),
            Padding(
              padding:
                  RecentContactsBannerWidgetStyle.chatRecentContactItemPadding,
              child: BuildDisplayName(
                profileDisplayName: displayName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
