import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/request_and_cache.dart';

extension ClientWellKnownExtension on Client {
  /// Fetches the discovery information (`/.well-known/matrix/client`) from
  /// the homeserver host, returning [fallback] when it cannot be fetched.
  Future<DiscoveryInformation?> getWellKnownOrFallback({
    DiscoveryInformation? fallback,
    Duration cacheLifetime = const Duration(minutes: 5),
  }) async {
    try {
      return await requestAndCache<DiscoveryInformation>(
        () => MatrixApi(
          homeserver: homeserver,
          httpClient: httpClient,
        ).getWellknown(),
        fromJson: DiscoveryInformation.fromJson,
        toJson: (wellKnown) => wellKnown.toJson(),
        cacheKey: 'well_known',
        cacheLifetime: cacheLifetime,
        throwOnUpdateFailure: false,
      );
    } catch (e) {
      Logs().w(
        'ClientWellKnownExtension::getWellKnownOrFallback: could not fetch '
        'well-known from the homeserver host, keeping previous discovery '
        'information',
        e,
      );
      return fallback;
    }
  }
}
