import 'search_engine.dart';
import 'search_options.dart';

/// Keeps the [SearchMatcher] of the latest keyword so a per-item callback
/// (e.g. a timeline filter) builds it once per keyword, not once per item.
class KeywordMatcherCache {
  final SearchEngine _engine;
  final SearchOptions _options;

  String? _keyword;
  SearchMatcher? _matcher;

  KeywordMatcherCache({
    SearchEngine engine = const SearchEngine(),
    SearchOptions options = const SearchOptions(),
  }) : _engine = engine,
       _options = options;

  bool matches(String? keyword, String value) {
    final needle = keyword ?? '';
    var matcher = _matcher;
    if (matcher == null || _keyword != needle) {
      matcher = _engine.buildMatcher(needle, options: _options);
      _keyword = needle;
      _matcher = matcher;
    }
    return matcher.matches(value);
  }
}
