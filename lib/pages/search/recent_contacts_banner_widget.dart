import 'package:fluffychat/pages/search/recent_contacts_banner_widget_style.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/utils/display_name_widget.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:matrix/matrix.dart';

class PreSearchRecentContactsContainer extends StatelessWidget {
  final SearchController searchController;
  final List<User> contactsList;
  const PreSearchRecentContactsContainer({
    super.key,
    required this.searchController,
    required this.contactsList,
  });

  @override
  Widget build(BuildContext context) {
    if (contactsList.isEmpty) {
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
          itemCount: contactsList.length,
          itemBuilder: (context, index) {
            return PreSearchRecentContactWidget(
              user: contactsList[index],
              searchController: searchController,
            );
          },
        ),
      );
    }
  }
}

class PreSearchRecentContactWidget extends StatelessWidget {
  final SearchController searchController;
  final User user;
  const PreSearchRecentContactWidget({
    super.key,
    required this.user,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        searchController.goToChatScreenFormRecentChat(user);
      },
      child: SizedBox(
        width: RecentContactsBannerWidgetStyle.chatRecentContactItemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: RecentContactsBannerWidgetStyle.avatarWidthSize,
              height: RecentContactsBannerWidgetStyle.avatarWidthSize,
              child: Avatar(
                mxContent: user.avatarUrl,
                name: user.displayName ?? "",
              ),
            ),
            Padding(
              padding:
                  RecentContactsBannerWidgetStyle.chatRecentContactItemPadding,
              child: BuildDisplayName(
                profileDisplayName: user.displayName ?? "",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
