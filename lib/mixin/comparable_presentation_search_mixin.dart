import 'package:fluffychat/presentation/model/presentation_search.dart';

class ComparablePresentationSearchMixin {
  int comparePresentationSearch(PresentationSearch searchResultOne, PresentationSearch searchResultTwo) {
    final bufferOne = StringBuffer();
    final bufferTwo = StringBuffer();

    bufferOne.writeAll([
      searchResultOne.displayName ?? "",
      searchResultOne.matrixId ?? "",
      searchResultOne.email ?? "",
      searchResultTwo.searchElementTypeEnum ?? SearchElementTypeEnum.contact
    ]);

    bufferTwo.writeAll([
      searchResultTwo.displayName ?? "",
      searchResultTwo.matrixId ?? "",
      searchResultTwo.email ?? "",
      searchResultTwo.searchElementTypeEnum ?? SearchElementTypeEnum.contact
    ]);

    return bufferOne.toString().compareTo(bufferTwo.toString());
  }
}