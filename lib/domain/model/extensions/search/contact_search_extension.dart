import 'package:fluffychat/domain/model/search/contact_search_model.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

extension SearchExtension on ContactSearchModel {
  ContactPresentationSearch toContactPresentationSearch() {
    return ContactPresentationSearch(
      matrixId: id,
      email: email,
      displayName: displayName,
    );
  }

  bool isDisplayNameContains(String keyword) {
    return displayName?.toLowerCase().contains(keyword.toLowerCase()) ?? false;
  }
}
