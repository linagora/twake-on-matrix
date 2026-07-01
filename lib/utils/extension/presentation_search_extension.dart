import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:collection/collection.dart';

const _searchOptions = SearchOptions(diacriticSensitive: false);

extension PresentationSearchExtension on PresentationSearch {
  SearchEngine get _searchEngine => getIt.get<SearchEngine>();

  bool _matchedMatrixId(String keyword) =>
      _searchEngine.matchesText(keyword, id, options: _searchOptions);

  bool _matchedDirectChatMatrixId(String keyword) => _searchEngine.matchesText(
    keyword,
    directChatMatrixID ?? '',
    options: _searchOptions,
  );

  bool _matchedName(String keyword) => _searchEngine.matchesText(
    keyword,
    displayName ?? '',
    options: _searchOptions,
  );

  bool _matchedEmail(String keyword) =>
      emails?.firstWhereOrNull(
        (email) => _searchEngine.matchesText(
          keyword,
          email.email,
          options: _searchOptions,
        ),
      ) !=
      null;

  bool _matchedPhoneNumber(String keyword) =>
      phoneNumbers?.firstWhereOrNull(
        (phone) => _searchEngine.matchesText(
          keyword,
          phone.phoneNumber.replaceAll(' ', ''),
          options: _searchOptions,
        ),
      ) !=
      null;

  bool _matchedContactInfo(String keyword) =>
      _matchedName(keyword) ||
      _matchedEmail(keyword) ||
      _matchedPhoneNumber(keyword) ||
      _matchedMatrixId(keyword) ||
      _matchedDirectChatMatrixId(keyword);

  bool doesMatchKeyword(String keyword) {
    if (this is! ContactPresentationSearch) return false;
    if (keyword.isEmpty) return true;
    return _matchedContactInfo(keyword);
  }
}
