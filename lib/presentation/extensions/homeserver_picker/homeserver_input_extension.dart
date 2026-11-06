final _schemePrefix = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

extension HomeserverInputExtension on String {
  // `Uri.parse('host:8443')` reads `host` as the scheme, so add it first.
  Uri toHomeserverUri() =>
      Uri.parse(startsWith(_schemePrefix) ? this : 'https://$this');
}
