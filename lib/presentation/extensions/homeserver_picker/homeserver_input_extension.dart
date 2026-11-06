extension HomeserverInputExtension on String {
  // `Uri.parse('host:8443')` reads `host` as the scheme, so add it first.
  Uri toHomeserverUri() => Uri.parse(contains('://') ? this : 'https://$this');
}
