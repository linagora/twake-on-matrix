// Can be extended in the future, e.g. with fuzzy matching.
enum SearchMode { exact, substring }

class SearchOptions {
  final bool caseSensitive;
  final bool diacriticSensitive;
  final SearchMode mode;

  const SearchOptions({
    this.caseSensitive = false,
    this.diacriticSensitive = true,
    this.mode = SearchMode.substring,
  });
}
