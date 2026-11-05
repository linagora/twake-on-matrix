import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_stored_homeserver_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/client_well_known_extension.dart';

extension ClientHomeserverSummaryExtension on Client {
  /// Returns null when nothing can be read for this homeserver. [previous] is
  /// reused only when its well-known points to this client's homeserver.
  /// [onCheckFailed] runs when the homeserver itself cannot be checked.
  Future<HomeserverSummary?> fetchHomeserverSummary({
    HomeserverSummary? previous,
    void Function()? onCheckFailed,
  }) async {
    final homeserver = this.homeserver?.stripTrailingSlash();
    final previousHomeserver = previous
        ?.discoveryInformation
        ?.mHomeserver
        .baseUrl
        .stripTrailingSlash();
    final ownPrevious = homeserver != null && previousHomeserver == homeserver
        ? previous
        : null;

    // Before checkHomeserver, which sets the homeserver to null when it fails.
    final discovery = await getWellKnownOrFallback(
      fallback: ownPrevious?.discoveryInformation,
    );

    GetVersionsResponse? versions;
    List<LoginFlow>? loginFlows;
    if (homeserver != null) {
      try {
        final (_, checkedVersions, checkedLoginFlows, _) =
            await checkStoredHomeserver();
        versions = checkedVersions;
        loginFlows = checkedLoginFlows;
      } catch (e, s) {
        onCheckFailed?.call();
        Logs().w(
          'ClientHomeserverSummaryExtension::fetchHomeserverSummary: homeserver '
          'unreachable, using cached discovery information',
          e,
          s,
        );
      }
    }

    if (versions == null && discovery == null) return null;

    return HomeserverSummary(
      discoveryInformation: discovery,
      versions:
          versions ??
          ownPrevious?.versions ??
          GetVersionsResponse(versions: []),
      loginFlows: loginFlows ?? ownPrevious?.loginFlows ?? [],
    );
  }
}
