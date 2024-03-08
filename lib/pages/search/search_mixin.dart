import 'package:fluffychat/presentation/model/search/presentation_search.dart';

mixin SearchMixin {
  List<PresentationSearch> combineDuplicateContactAndChat({
    required List<PresentationSearch> contacts,
    required List<PresentationSearch> recentChat,
  }) {
    final Map<String, PresentationSearch> distinctContactsAndChatsMap = {};

    for (final contact in contacts) {
      distinctContactsAndChatsMap[contact.id] = contact;
    }

    for (final chat in recentChat) {
      final isContactHasChat =
          distinctContactsAndChatsMap[chat.directChatMatrixID ?? chat.id] !=
              null;
      if (!isContactHasChat) {
        distinctContactsAndChatsMap[chat.id] = chat;
      }
    }

    return distinctContactsAndChatsMap.values.toList();
  }
}
