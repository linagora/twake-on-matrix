import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// SimpleMatcher 2 — the stateless, index-free matcher, with folding on.
///
/// A pure function of (query, candidate): substring matching over text folded
/// to NFD, stripped of combining marks, and lower-cased. Nothing is derived
/// from the corpus, so there is no lifecycle to wire in and no data left
/// behind.
///
/// Folding is on unconditionally rather than opt-in per call site, so `cafe`
/// finds `Café Central` and `tieng` finds `tiếng Việt` everywhere in the app,
/// including inside encrypted rooms.
///
/// The accepted cost is that **highlighting is gone**. Marking the match would
/// mean returning match positions and mapping those offsets back through the
/// folding, which this matcher deliberately does not do; the previous
/// highlighter re-derived the match with a regex over the *raw* string and so
/// would mark nothing on exactly the matches folding buys. Rather than leave
/// that silently broken, the highlighting was removed. Results are correct but
/// unmarked: the user cannot see *why* a row matched.
///
/// Nothing here is Matrix-specific — this file is portable as-is.
class SimpleMatcher2 {
  const SimpleMatcher2();

  static final _combiningMarks = RegExp(r'\p{Mn}', unicode: true);

  /// Matches `candidate` against `query`, ignoring case and diacritics.
  ///
  /// An empty `query` matches everything.
  bool matchesText(String query, String candidate) {
    return _matches(candidate, fold(query));
  }

  /// Keeps the items of `haystack` for which at least one field extracted by
  /// `fieldExtractors` matches `query`.
  List<T> matchAnyField<T>(
    String query,
    List<T> haystack, {
    required List<Iterable<String> Function(T)> fieldExtractors,
  }) {
    final foldedQuery = fold(query);

    return haystack
        .where((item) => _anyFieldMatches(item, fieldExtractors, foldedQuery))
        .toList();
  }

  /// Same as [matchAnyField], but `fieldExtractors` is optional: when omitted,
  /// each item is matched via its `toString()`.
  List<T> match<T>(
    String query,
    List<T> haystack, {
    List<Iterable<String> Function(T)>? fieldExtractors,
  }) {
    return matchAnyField(
      query,
      haystack,
      fieldExtractors: fieldExtractors ?? _toStringExtractors<T>(),
    );
  }

  /// Returns `true` if `query` matches at least one item in `haystack`.
  bool anyMatch<T>(
    String query,
    List<T> haystack, {
    List<Iterable<String> Function(T)>? fieldExtractors,
  }) {
    final extractors = fieldExtractors ?? _toStringExtractors<T>();
    final foldedQuery = fold(query);

    return haystack.any(
      (item) => _anyFieldMatches(item, extractors, foldedQuery),
    );
  }

  /// Decomposes to NFD, drops combining marks, then lower-cases.
  ///
  /// Decomposing first is what lets a single rule cover both precomposed `é`
  /// and an `e` already followed by a combining acute.
  String fold(String input) {
    return unorm.nfd(input).replaceAll(_combiningMarks, '').toLowerCase();
  }

  /// `foldedQuery` is expected to be folded already, so a scan over a haystack
  /// folds the query once rather than once per candidate.
  bool _matches(String candidate, String foldedQuery) {
    return fold(candidate).contains(foldedQuery);
  }

  bool _anyFieldMatches<T>(
    T item,
    List<Iterable<String> Function(T)> fieldExtractors,
    String foldedQuery,
  ) {
    return fieldExtractors.any(
      (extract) => extract(item).any((value) => _matches(value, foldedQuery)),
    );
  }

  List<Iterable<String> Function(T)> _toStringExtractors<T>() => [
    (T item) => [item.toString()],
  ];
}
