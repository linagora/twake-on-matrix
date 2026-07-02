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

  List<T> matchAnyField<T>(
    String needle,
    List<T> haystack, {
    required List<String? Function(T)> fieldExtractors,
    SearchOptions options = const SearchOptions(),
  }) {
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

    return haystack.where((item) {
      return fieldExtractors.any(
        (extract) => matches(apply(extract(item) ?? '')),
      );
    }).toList();
  }

  bool matchesText(
    String needle,
    String haystack, {
    SearchOptions options = const SearchOptions(),
  }) {
    return matchAnyField(
      needle,
      [haystack],
      fieldExtractors: [(String s) => s],
      options: options,
    ).isNotEmpty;
  }
}
