import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

const _searchOptions = SearchOptions(diacriticSensitive: false);

extension PresentationSearchExtension on PresentationSearch {
  SearchEngine get _searchEngine => getIt.get<SearchEngine>();

  bool _matchesMainFields(String keyword) => _searchEngine.anyMatch(
    keyword,
    [this],
    fieldExtractors: [
      (PresentationSearch s) => [s.displayName ?? ''],
      (PresentationSearch s) => [s.id],
      (PresentationSearch s) => [s.directChatMatrixID ?? ''],
      (PresentationSearch s) => s.emails?.map((e) => e.email) ?? const [],
      (PresentationSearch s) =>
          s.phoneNumbers?.map((p) => p.phoneNumber) ?? const [],
    ],
    options: _searchOptions,
  );

  bool doesMatchKeyword(String keyword) {
    if (this is! ContactPresentationSearch) return false;
    if (keyword.isEmpty) return true;
    return _matchesMainFields(keyword);
  }
}
