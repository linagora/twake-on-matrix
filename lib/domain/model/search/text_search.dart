import 'package:flutter/foundation.dart';
import 'package:fluffychat/utils/string_extension.dart';

// To be used when applying a sequence of normalization steps to a string
abstract class NormalizationStep {
  String normalize(String input);
}

class _LowerCaseStep implements NormalizationStep {
  const _LowerCaseStep();
  @override
  String normalize(String input) => input.toLowerCase();
}

class _RemoveDiacriticsStep implements NormalizationStep {
  const _RemoveDiacriticsStep();

  @override
  String normalize(String input) => input.removeDiacritics();
}

// This enum can be extended in the future when adding Fuzzy matching for example
enum SearchMode { exact, substring }

@immutable
class SearchOptions {
  final bool caseSensitive; // default: false (current behavior)
  final bool diacriticSensitive; // default: false  (changed behavior)
  final SearchMode mode; // default: SearchMode.substring
  final List<NormalizationStep>? normalize; // optional override list

  const SearchOptions({
    this.caseSensitive = false,
    this.diacriticSensitive = false,
    this.mode = SearchMode.substring,
    this.normalize,
  });
}

// From SearchOptions, build a list of what should be done to the target needle
List<NormalizationStep> _buildPipeline(SearchOptions options) {
  if (options.normalize != null) return options.normalize!;
  return [
    if (!options.caseSensitive) const _LowerCaseStep(),
    if (!options.diacriticSensitive) const _RemoveDiacriticsStep(),
  ];
}

// Build the returned list after search

// for each item in haystack (single pass):
//  for each fieldExtractor:
//    extract field from item -> normalize at compare time -> compare to normNeedle
//  if any field matches -> keep the ORIGINAL item in results
List<T> matchAnyField<T>(
  String needle,
  List<T> haystack, {
  required List<String? Function(T)> fieldExtractors,
  SearchOptions options = const SearchOptions(),
}) {
  if (needle.isEmpty) return <T>[];

  final pipeline = _buildPipeline(
    options,
  ); // List<NormalizationStep>, derived once
  String normalize(String input) =>
      pipeline.fold(input, (value, step) => step.normalize(value));

  final normNeedle = normalize(needle);

  return haystack.where((item) {
    return fieldExtractors.any((extract) {
      final field = extract(item) ?? '';
      final normField = normalize(field);
      switch (options.mode) {
        case SearchMode.exact:
          return normField == normNeedle;
        case SearchMode.substring:
          return normField.contains(normNeedle);
      }
    });
  }).toList(); // List<T>, original items, single pass
}

/// Single string-vs-string match. Thin wrapper over [matchAnyField] with a
/// one-element haystack and identity extractor - exists for call sites that
/// have no object to filter, just two strings.
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
