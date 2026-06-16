import 'search_options.dart';

abstract class SearchEngine {
  const SearchEngine();

  List<T> matchAnyField<T>(
    String needle,
    List<T> haystack, {
    required List<String? Function(T)> fieldExtractors,
    SearchOptions options = const SearchOptions(),
  });

  bool matchesText(
    String needle,
    String haystack, {
    SearchOptions options = const SearchOptions(),
  });
}