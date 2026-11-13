import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/pages/chat/providers/message_link_providers.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

void main() {
  const roomId = '!abc:example.org';
  const eventId = r'$evt_1:example.org';
  final linkProvider = messageLinkProvider(roomId: roomId, eventId: eventId);

  HomeserverSummary summaryWith(Map<String, dynamic> twakeChat) =>
      HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          additionalProperties: {'app.twake.chat': twakeChat},
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.example.org'),
          ),
        ),
        versions: GetVersionsResponse(versions: []),
        loginFlows: [],
      );

  late ProviderContainer container;

  ProviderContainer containerFor({String? userId}) => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: [activeUserIdProvider.overrideWithValue(userId)],
  );

  setUp(() => container = containerFor());

  test('uses the web app origin named by the homeserver', () {
    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(summaryWith({'web_url': 'https://chat.example.org/'}));

    expect(
      container.read(linkProvider),
      'https://chat.example.org/rooms/!abc%3Aexample.org'
      '?event=%24evt_1%3Aexample.org',
    );
  });

  test('falls back to matrix.to without a web app origin', () {
    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(summaryWith({}));

    expect(
      container.read(linkProvider),
      'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org'
      '?via=example.org',
    );
  });

  test('adds the user server, then the room server, as via to matrix.to', () {
    container = containerFor(userId: '@me:other.org');
    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(summaryWith({}));

    expect(
      container.read(linkProvider),
      'https://matrix.to/#/!abc%3Aexample.org/%24evt_1%3Aexample.org'
      '?via=other.org&via=example.org',
    );
  });

  test('falls back to matrix.to before the summary is loaded', () {
    expect(container.read(linkProvider), startsWith('https://matrix.to/#/'));
  });

  test('follows a new homeserver summary', () {
    final subscription = container.listen(linkProvider, (_, _) {});
    expect(subscription.read(), startsWith('https://matrix.to/#/'));

    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(summaryWith({'web_url': 'https://chat.example.org'}));

    expect(subscription.read(), startsWith('https://chat.example.org/rooms/'));
  });
}
