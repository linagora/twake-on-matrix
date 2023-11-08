import 'package:fluffychat/presentation/model/search/presentation_search.dart';

mixin ComparablePresentationSearchMixin {
  int comparePresentationSearch(
    PresentationSearch searchResultOne,
    PresentationSearch searchResultTwo,
  ) {
    return searchResultOne.toString().compareTo(searchResultTwo.toString());
  }
}
