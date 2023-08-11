import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/presentation/extensions/search/search_model_extension.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state.dart';

extension GetContactsSuccessToPresentationExtension on GetContactsSuccess {
  GetContactAndRecentChatPresentation toPresentation({
    GetContactAndRecentChatPresentation? oldPresentation,
  }) {
    final oldResult = oldPresentation?.data ?? [];
    final newResult = data
        .expand((contact) => contact.toSearch())
        .map((model) => model.toPresentation())
        .toList();
    return GetContactAndRecentChatPresentation(
      data: oldResult + newResult,
      offset: offset,
      isEnd: isEnd,
      keyword: keyword,
    );
  }
}

extension SearchRecentChatSuccessToPresentationExtension
    on SearchRecentChatSuccess {
  GetContactAndRecentChatPresentation toPresentation() {
    final newResult = data.map((model) => model.toPresentation()).toList();
    return GetContactAndRecentChatPresentation(
      data: newResult,
      offset: 0,
      isEnd: keyword.isEmpty,
      keyword: keyword,
    );
  }
}
