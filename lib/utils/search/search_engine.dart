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

  /// Builds the normalize/compare closures for a given `needle` and
  /// `options`, so callers can reuse the same normalization pipeline across
  /// multiple values without recomputing it per value.
  ({String Function(String) apply, bool Function(String) matches}) _matcher(
    String needle,
    SearchOptions options,
  ) {
    final pipeline = _buildPipeline(options);
    String apply(String input) =>
        pipeline.fold<String>(input, (v, step) => step.normalize(v));
    final normNeedle = apply(needle);
    bool matches(String value) {
      switch (options.mode) {
        case SearchMode.exact:
          return value == normNeedle;
        case SearchMode.substring:
          return value.contains(normNeedle);
      }
    }

    return (apply: apply, matches: matches);
  }

  List<T> matchAnyField<T>(
    String needle,
    List<T> haystack, {
    required List<Iterable<String> Function(T)> fieldExtractors,
    SearchOptions options = const SearchOptions(),
  }) {
    final matcher = _matcher(needle, options);

    return haystack.where((item) {
      return fieldExtractors.any(
        (extract) =>
            extract(item).any((value) => matcher.matches(matcher.apply(value))),
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
    return match(
      needle,
      haystack,
      fieldExtractors: fieldExtractors,
      options: options,
    ).isNotEmpty;
  }

  bool matchesText(
    String needle,
    String haystack, {
    SearchOptions options = const SearchOptions(),
  }) {
    return matchAnyField(
      needle,
      [haystack],
      fieldExtractors: [
        (String s) => [s],
      ],
      options: options,
    ).isNotEmpty;
  }
}
