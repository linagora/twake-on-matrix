part of 'search_engine.dart';

List<NormalizationStep> _buildPipeline(SearchOptions options) {
  return [if (!options.caseSensitive) const LowerCaseStep()];
}

List<T> _matchAnyField<T>(
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

bool _matchesText(
  String needle,
  String haystack, {
  SearchOptions options = const SearchOptions(),
}) {
  return _matchAnyField(
    needle,
    [haystack],
    fieldExtractors: [(String s) => s],
    options: options,
  ).isNotEmpty;
}
