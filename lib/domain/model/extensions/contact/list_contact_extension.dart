import 'package:collection/collection.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/extensions/search/search_extension.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';

extension ListContactExtenstion on List<Contact> {
    List<SearchModel> toSearchesFilteredRecent(String keyword, List<SearchModel> recentChat) {
      final recentChatIds = recentChat.map((recentChat) => recentChat.directChatMatrixID).toList();
      return expand((contact) => contact.toSearch())
        .where((search) => search.searchDisplayName(keyword))
        .whereNot((element) => recentChatIds.contains(element.directChatMatrixID)).toList();
  }
}