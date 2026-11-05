import 'search_options.dart';
import 'steps/diacritic_strip_step.dart';
import 'steps/lower_case_step.dart';
import 'steps/normalization_step.dart';

class SearchEngine {
  const SearchEngine();

  List<NormalizationStep> _buildPipeline(SearchOptions options) {
    return [
      if (!options.diacriticSensitive)
        DiacriticStripStep(decomposition: options.diacriticDecomposition),
      if (!options.caseSensitive) const LowerCaseStep(),
    ];
  }

  /// Builds a [SearchMatcher] for `needle` and `options`. The needle is
  /// normalized once; reuse the matcher for every value compared against it.
  SearchMatcher buildMatcher(
    String needle, {
    SearchOptions options = const SearchOptions(),
  }) => SearchMatcher._(needle, options, _buildPipeline(options));

  List<T> matchAnyField<T>(
    String needle,
    List<T> haystack, {
    required List<Iterable<String> Function(T)> fieldExtractors,
    SearchOptions options = const SearchOptions(),
  }) {
    final matcher = buildMatcher(needle, options: options);

    return haystack.where((item) {
      return fieldExtractors.any(
        (extract) => extract(item).any(matcher.matches),
      );
    }).toList();
  }

  /// Same as [matchAnyField], but `fieldExtractors` is optional: when
  /// omitted, each item is matched via its `toString()`.
  List<T> match<T>(
    String needle,
    List<T> haystack, {
    List<Iterable<String> Function(T)>? fieldExtractors,
    SearchOptions options = const SearchOptions(),
  }) {
    return matchAnyField(
      needle,
      haystack,
      fieldExtractors:
          fieldExtractors ??
          [
            (T item) => [item.toString()],
          ],
      options: options,
    );
  }

  /// Returns `true` if `needle` matches at least one item in `haystack`.
  bool anyMatch<T>(
    String needle,
    List<T> haystack, {
    List<Iterable<String> Function(T)>? fieldExtractors,
    SearchOptions options = const SearchOptions(),
  }) {
    final matcher = buildMatcher(needle, options: options);
    final extractors =
        fieldExtractors ??
        [
          (T item) => [item.toString()],
        ];

    return haystack.any(
      (item) => extractors.any((extract) => extract(item).any(matcher.matches)),
    );
  }

  bool matchesText(
    String needle,
    String haystack, {
    SearchOptions options = const SearchOptions(),
  }) => buildMatcher(needle, options: options).matches(haystack);
}

class SearchMatcher {
  final SearchOptions _options;
  final List<NormalizationStep> _pipeline;
  final String _normalizedNeedle;

  SearchMatcher._(String needle, this._options, this._pipeline)
    : _normalizedNeedle = _normalize(_pipeline, needle);

  static String _normalize(List<NormalizationStep> pipeline, String input) =>
      pipeline.fold<String>(input, (v, step) => step.normalize(v));

  /// Normalizes `value` with the same pipeline as the needle, then compares.
  bool matches(String value) {
    final normalized = _normalize(_pipeline, value);
    switch (_options.mode) {
      case SearchMode.exact:
        return normalized == _normalizedNeedle;
      case SearchMode.substring:
        return normalized.contains(_normalizedNeedle);
    }
  }
}
