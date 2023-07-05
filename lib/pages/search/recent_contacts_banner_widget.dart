import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/pages/search/recent_contacts_banner_widget_style.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/utils/display_name_widget.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class RecentContactsBannerWidget extends StatelessWidget {
  final SearchController searchController;
  const RecentContactsBannerWidget({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Either<Failure, GetContactsSuccess>>(
      stream: searchController.contactsStreamController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasError || snapshot.data!.isLeft()) {
          return const SizedBox();
        }

        final contactsList = searchController.fetchContactsController.getContactsFromFetchStream(snapshot.data!);

        final contactsListSorted = contactsList.sorted((pre, next) => searchController.comparePresentationContacts(pre, next));

        if (contactsListSorted.isEmpty) {
          return const SizedBox();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: contactsListSorted.length,
          itemBuilder: (context, index) {
            return ChatRecentContactItemWidget(
              contact: contactsListSorted[index],
              searchController: searchController,
            );
          },
        );
      },
    );
  }
}

class ChatRecentContactItemWidget extends StatelessWidget {
  final SearchController searchController;
  final PresentationContact contact;
  const ChatRecentContactItemWidget({super.key, required this.contact, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileInformation?>(
      future: searchController.getProfile(context, contact),
      builder: (context, snapshot) {
        return SizedBox(
          width: RecentContactsBannerWidgetStyle.chatRecentContactItemWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: RecentContactsBannerWidgetStyle.avatarWidthSize,
                child: Avatar(
                  mxContent: snapshot.data?.avatarUrl,
                  name: contact.displayName,
                ),
              ),
              Padding(
                padding: RecentContactsBannerWidgetStyle.chatRecentContactItemPadding,
                child: BuildDisplayName(
                  profileDisplayName: snapshot.data?.displayname,
                  contactDisplayName: contact.displayName
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

