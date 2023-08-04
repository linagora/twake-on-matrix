import 'package:fluffychat/presentation/model/search/presentation_search.dart';

class ComparablePresentationSearchMixin {
  int comparePresentationSearch(PresentationSearch searchResultOne, PresentationSearch searchResultTwo) {
    return searchResultOne.toString().compareTo(searchResultTwo.toString());
  }
}