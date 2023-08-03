import 'package:fluffychat/pages/search/search_contacts_and_chats_controller.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:flutter/material.dart';

mixin LoadMoreSearchMixin {
  final mainScrollController = ScrollController();

  void listenForScrollChanged({required SearchContactsAndChatsController? controller}) {
    mainScrollController.addListener(() {
      if (mainScrollController.shouldLoadMore) {
        controller?.loadMoreContacts();
      }
    });
  }
}