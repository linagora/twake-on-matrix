import 'package:fluffychat/presentation/model/search/presentation_search.dart';

extension PresentationSearchExtension on PresentationSearch {
  bool _matchedMatrixId(String keyword) {
    return id.toLowerCase().contains(keyword.toLowerCase());
  }

  bool _matchedDirectChatMatrixId(String keyword) {
    return directChatMatrixID?.toLowerCase().contains(keyword.toLowerCase()) ??
        false;
  }

  bool _matchedName(String keyword) {
    return displayName?.toLowerCase().contains(keyword.toLowerCase()) ?? false;
  }

  bool _matchedEmail(String keyword) {
    return email?.toLowerCase().contains(keyword.toLowerCase()) ?? false;
  }

  bool _matchedContactInfo(String keyword) {
    return _matchedName(keyword) ||
        _matchedEmail(keyword) ||
        _matchedMatrixId(keyword) ||
        _matchedDirectChatMatrixId(keyword);
  }

  bool doesMatchKeyword(String keyword) {
    if (this is! ContactPresentationSearch) {
      return false;
    }

    return _matchedContactInfo(keyword);
  }
}
