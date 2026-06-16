import 'package:fluffychat/domain/model/search/normalization_step.dart';
import 'package:fluffychat/domain/model/search/search_engine.dart';
import 'package:fluffychat/domain/model/search/search_options.dart';

import 'diacritic_strip_step.dart';
import 'lower_case_step.dart';

class TextSearchEngine extends SearchEngine {
  const TextSearchEngine();

  List<NormalizationStep> _buildPipeline(SearchOptions options) {
    return [
      if (!options.diacriticSensitive) const DiacriticStripStep(),
      if (!options.caseSensitive) const LowerCaseStep(),
    ];
  }

  @override
  List<T> matchAnyField<T>(
    String needle,
    List<T> haystack, {
    required List<String? Function(T)> fieldExtractors,
    SearchOptions options = const SearchOptions(),
  }) {
    if (needle.isEmpty) return <T>[];
    final pipeline = _buildPipeline(options);
    String applyPipeline(String input) =>
        pipeline.fold<String>(input, (value, step) => step.normalize(value));
    final normNeedle = applyPipeline(needle);
    return haystack.where((item) {
      return fieldExtractors.any((extract) {
        final field = extract(item) ?? '';
        return applyPipeline(field).contains(normNeedle);
      });
    }).toList();
  }

  @override
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