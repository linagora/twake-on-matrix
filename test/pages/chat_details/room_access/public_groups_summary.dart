import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';

HomeserverSummary summaryWith({required bool isPublicGroupsEnabled}) =>
    HomeserverSummary(
      discoveryInformation: DiscoveryInformation(
        mHomeserver: HomeserverInformation(
          baseUrl: Uri.parse('https://matrix.example.com'),
        ),
        additionalProperties: {
          'app.twake.chat': {
            'public_groups': {'enabled': isPublicGroupsEnabled},
          },
        },
      ),
      versions: GetVersionsResponse(versions: ['r1.6.0']),
      loginFlows: [],
    );
