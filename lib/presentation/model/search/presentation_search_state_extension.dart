import 'package:fluffychat/domain/app_state/contact/get_all_contacts_state.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/presentation/extensions/search/search_model_extension.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state.dart';

extension GetContactsSuccessToPresentationExtension on GetContactsAllSuccess {
  GetContactAndRecentChatPresentation toPresentation({
    GetContactAndRecentChatPresentation? oldPresentation,
  }) {
    final oldResult = oldPresentation?.tomContacts ?? [];
    final newResult = tomContacts
        .expand((contact) => contact.toSearch())
        .map((model) => model.toPresentation())
        .toList();
    return GetContactAndRecentChatPresentation(
      tomContacts: oldResult + newResult,
      keyword: keyword,
    );
  }
}

extension SearchRecentChatSuccessToPresentationExtension
    on SearchRecentChatSuccess {
  GetContactAndRecentChatPresentation toPresentation() {
    final tomContacts = data.map((model) => model.toPresentation()).toList();
    return GetContactAndRecentChatPresentation(
      tomContacts: tomContacts,
      keyword: keyword,
    );
  }
}
