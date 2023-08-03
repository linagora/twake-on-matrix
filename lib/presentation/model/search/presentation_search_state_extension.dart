import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/model/extensions/search/search_extension.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state.dart';

extension GetContactAndRecentChatSuccessToPresentationExtension on GetContactAndRecentChatSuccess {
  GetContactAndRecentChatPresentation toPresentation({GetContactAndRecentChatPresentation? oldPresentation}) {
    final oldResult = oldPresentation?.searchResult ?? [];
    final newResult = searchResult.map((item) => item.toPresentationSearch()).toList();
    return GetContactAndRecentChatPresentation(
      searchResult: oldResult + newResult,
      contactsOffset: contactsOffset,
      shouldLoadMoreContacts: shouldLoadMoreContacts,
      keyword: keyword,
    );
  } 
}