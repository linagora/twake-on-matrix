import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

extension SearchExtension on SearchModel {
  PresentationSearch toPresentationSearch() {
    return PresentationSearch(
      email: email,
      displayName: displayName,
      matrixId: matrixId,
      searchElementTypeEnum: searchElementTypeEnum,
      roomSummary: roomSummary,
      directChatMatrixID: directChatMatrixID
    );
  }
}