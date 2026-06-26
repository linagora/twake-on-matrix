import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

const _searchOptions = SearchOptions(diacriticSensitive: false);

extension PresentationSearchExtension on PresentationSearch {
  bool _matchedMatrixId(String keyword) {
    return getIt.get<SearchEngine>().matchesText(
      keyword,
      id,
      options: _searchOptions,
    );
  }

  bool _matchedDirectChatMatrixId(String keyword) {
    return getIt.get<SearchEngine>().matchesText(
      keyword,
      directChatMatrixID ?? '',
      options: _searchOptions,
    );
  }

  bool _matchedName(String keyword) {
    return getIt.get<SearchEngine>().matchesText(
      keyword,
      displayName ?? '',
      options: _searchOptions,
    );
  }

  bool _matchedEmail(String keyword) {
    return emails?.any(
          (email) => getIt.get<SearchEngine>().matchesText(
            keyword,
            email.email,
            options: _searchOptions,
          ),
        ) ==
        true;
  }

  bool _matchedPhoneNumber(String keyword) {
    return phoneNumbers?.any(
          (phone) => getIt.get<SearchEngine>().matchesText(
            keyword,
            phone.phoneNumber.replaceAll(' ', ''),
            options: _searchOptions,
          ),
        ) ==
        true;
  }

  bool _matchedContactInfo(String keyword) {
    return _matchedName(keyword) ||
        _matchedEmail(keyword) ||
        _matchedPhoneNumber(keyword) ||
        _matchedMatrixId(keyword) ||
        _matchedDirectChatMatrixId(keyword);
  }

  bool doesMatchKeyword(String keyword) {
    if (this is! ContactPresentationSearch) {
      return false;
    }
    if (keyword.isEmpty) return true;

    return _matchedContactInfo(keyword);
  }
}
