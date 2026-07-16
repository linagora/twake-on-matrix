import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/request_and_cache.dart';

extension ClientWellKnownExtension on Client {
  static const _cacheKey = 'well_known';

  /// Fetches the discovery information (`/.well-known/matrix/client`) from
  /// the homeserver host, returning [fallback] when it cannot be fetched.
  /// A returned fallback is persisted so it survives the next restart.
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
        cacheKey: _cacheKey,
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
      if (fallback != null && isLogged()) {
        // Persist the fallback so it survives the next restart
        try {
          await database.cacheCustomObject(_cacheKey, fallback.toJson());
        } catch (e) {
          Logs().w(
            'ClientWellKnownExtension::getWellKnownOrFallback: could not '
            'persist the fallback well-known',
            e,
          );
        }
      }
      return fallback;
    }
  }
}
