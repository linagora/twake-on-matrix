import 'package:fluffychat/pages/new_private_chat/fetch_contacts_controller.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';
import 'package:flutter/material.dart';

mixin LoadMoreSearchMixin {
  final scrollController = ScrollController();

  final haveMoreCountactsNotifier = ValueNotifier(true);

  final lastContactIndexNotifier = ValueNotifier(0);

  List<PresentationSearch> oldContactList = [];
  List<PresentationSearch> oldContactAndRecentChatList = [];

  void listenForScrollChanged({required FetchContactsController fetchContactsController}) {
    scrollController.addListener(() {});
  }

  void updateLastContactIndex(int value) {
    lastContactIndexNotifier.value = value;
  }

  void updateLastContactAndRecentChatIndex(int value) {
    lastContactIndexNotifier.value = value;
  }

  bool get isLoadMoreAction {
    return scrollController.offset >= scrollController.position.maxScrollExtent;
  }
}