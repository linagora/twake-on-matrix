import 'package:fluffychat/domain/app_state/search/search_state.dart';
import 'package:fluffychat/presentation/extensions/search/search_model_extension.dart';
import 'package:fluffychat/presentation/model/search/presentation_search_state.dart';

extension SearchRecentChatSuccessToPresentationExtension
    on SearchRecentChatSuccess {
  GetContactAndRecentChatPresentation toPresentation() {
    final contacts = data.map((model) => model.toPresentation()).toList();
    return GetContactAndRecentChatPresentation(
      contacts: contacts,
      keyword: keyword,
    );
  }
}
