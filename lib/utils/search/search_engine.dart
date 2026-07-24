import 'search_options.dart';
import 'steps/diacritic_strip_step.dart';
import 'steps/lower_case_step.dart';
import 'steps/normalization_step.dart';

typedef MatchRange = ({int start, int end});

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

  /// Normalizes `input` rune-by-rune, recording which original UTF-16 offset
  /// each normalized character came from. Needed because normalization can
  /// shrink text (e.g. combining marks get stripped), so a normalized-string
  /// index does not equal the same index in the original string.
  ({String normalized, List<int> offsets}) _normalizeWithOffsets(
    String input,
    SearchOptions options,
  ) {
    final pipeline = _buildPipeline(options);
    final buffer = StringBuffer();
    final offsets = <int>[];
    var codeUnitPos = 0;
    var lastEnd = 0;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final normalizedChar = pipeline.fold<String>(
        char,
        (v, step) => step.normalize(v),
      );
      for (var i = 0; i < normalizedChar.length; i++) {
        offsets.add(codeUnitPos);
      }
      codeUnitPos += char.length;
      if (normalizedChar.isNotEmpty) {
        lastEnd = codeUnitPos;
      }
      buffer.write(normalizedChar);
    }
    offsets.add(lastEnd);
    return (normalized: buffer.toString(), offsets: offsets);
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
    final matcher = _matcher(needle, options);
    final extractors =
        fieldExtractors ??
        [
          (T item) => [item.toString()],
        ];

    return haystack.any(
      (item) => extractors.any(
        (extract) =>
            extract(item).any((value) => matcher.matches(matcher.apply(value))),
      ),
    );
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

  /// Returns every match of `needle` in `haystack` as [MatchRange]s of
  /// UTF-16 code-unit offsets into the original (non-normalized) `haystack`.
  /// Used to drive highlighting; `matches`/`matchAnyField`/`anyMatch` stay on
  /// the cheaper whole-string `_matcher` path and are unaffected.
  List<MatchRange> matchRanges(
    String needle,
    String haystack, {
    SearchOptions options = const SearchOptions(),
  }) {
    final matcher = _matcher(needle, options);
    final normalizedNeedle = matcher.apply(needle);
    if (normalizedNeedle.isEmpty) return const [];

    if (options.mode == SearchMode.exact) {
      return matcher.matches(matcher.apply(haystack))
          ? [(start: 0, end: haystack.length)]
          : const [];
    }

    final normalizedHaystack = _normalizeWithOffsets(haystack, options);

    final ranges = <MatchRange>[];
    var searchFrom = 0;
    while (true) {
      final matchIndex = normalizedHaystack.normalized.indexOf(
        normalizedNeedle,
        searchFrom,
      );
      if (matchIndex == -1) break;
      final matchEnd = matchIndex + normalizedNeedle.length;
      final start = normalizedHaystack.offsets[matchIndex];
      final end = normalizedHaystack.offsets[matchEnd];
      ranges.add((start: start, end: end));
      searchFrom = matchEnd;
    }
    return ranges;
  }
}
