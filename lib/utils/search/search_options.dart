import 'steps/diacritic_strip_step.dart';

export 'steps/diacritic_strip_step.dart' show UnicodeDecomposition;

// Can be extended in the future, e.g. with fuzzy matching.
enum SearchMode { exact, substring }

class SearchOptions {
  final bool caseSensitive;
  final bool diacriticSensitive;
  final UnicodeDecomposition diacriticDecomposition;
  final SearchMode mode;

  const SearchOptions({
    this.caseSensitive = false,
    this.diacriticSensitive = true,
    this.diacriticDecomposition = UnicodeDecomposition.nfd,
    this.mode = SearchMode.substring,
  });
}
