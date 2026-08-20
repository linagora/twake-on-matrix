import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/simple_matcher_2.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

Iterable<String> _nonEmpty(String? value) =>
    (value == null || value.isEmpty) ? const [] : [value];

final _mainFieldExtractors = <Iterable<String> Function(PresentationSearch)>[
  (s) => _nonEmpty(s.displayName),
  (s) => [s.id],
  (s) => _nonEmpty(s.directChatMatrixID),
  (s) => s.emails?.map((e) => e.email) ?? const [],
  (s) => s.phoneNumbers?.map((p) => p.phoneNumber) ?? const [],
];

extension PresentationSearchExtension on PresentationSearch {
  SimpleMatcher2 get _matcher => getIt.get<SimpleMatcher2>();

  bool _matchesMainFields(String keyword) =>
      _matcher.anyMatch(keyword, [this], fieldExtractors: _mainFieldExtractors);

  bool doesMatchKeyword(String keyword) {
    if (this is! ContactPresentationSearch) return false;
    if (keyword.isEmpty) return true;
    return _matchesMainFields(keyword);
  }
}
