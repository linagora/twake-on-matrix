class SearchOptions {
  final bool caseSensitive;
  final bool diacriticSensitive;

  const SearchOptions({
    this.caseSensitive = false,
    this.diacriticSensitive = true,
  });
}