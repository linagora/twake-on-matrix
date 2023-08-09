import 'package:fluffychat/domain/model/search/contact_search_model.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

extension SearchModelExtension on SearchModel {
  PresentationSearch toPresentation() {
    if (this is ContactSearchModel) {
      return (this as ContactSearchModel).toPresentation();
    } else if (this is RecentChatSearchModel) {
      return (this as RecentChatSearchModel).toPresentation();
    } else {
      throw Exception('Unknown search model type');
    }
  }
}
