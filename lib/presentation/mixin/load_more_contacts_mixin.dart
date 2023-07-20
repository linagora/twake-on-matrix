import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/widgets.dart';

mixin LoadMoreContactsMixin {
  final scrollController = ScrollController();

  final haveMoreCountactsNotifier = ValueNotifier(true);

  final lastContactIndexNotifier = ValueNotifier(0);

  Set<PresentationContact> oldContactsList = {};
  bool isLoadMore = true;

  bool allowLoadMore = true;

  void listenForScrollChanged(
      {required FetchContactsController fetchContactsController}) {
    scrollController.addListener(() {
      if (allowLoadMore) {
        if (isLoadMoreAction) {
          fetchContactsController.loadMoreContacts(
              offset: fetchContactsController.lastContactIndexNotifier.value);
        }
      }
    });
  }

  void updateLastContactIndex(int value) {
    lastContactIndexNotifier.value = value;
  }

  bool get isLoadMoreAction {
    return scrollController.offset >= scrollController.position.maxScrollExtent;
  }
}
