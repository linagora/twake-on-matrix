import 'search_options.dart';
import 'steps/lower_case_step.dart';
import 'steps/normalization_step.dart';

part 'search_engine_impl.dart';

class SearchEngine {
  const SearchEngine();

  List<T> matchAnyField<T>(
    String needle,
    List<T> haystack, {
    required List<String? Function(T)> fieldExtractors,
    SearchOptions options = const SearchOptions(),
  }) => _matchAnyField(
    needle,
    haystack,
    fieldExtractors: fieldExtractors,
    options: options,
  );

  bool matchesText(
    String needle,
    String haystack, {
    SearchOptions options = const SearchOptions(),
  }) => _matchesText(needle, haystack, options: options);
}
