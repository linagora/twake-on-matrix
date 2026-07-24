import 'package:fluffychat/domain/model/homeserver_summary.dart';
import 'package:fluffychat/providers/login_homeserver_summary_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  HomeserverSummary buildSummary() => HomeserverSummary(
    discoveryInformation: DiscoveryInformation(
      mHomeserver: HomeserverInformation(
        baseUrl: Uri.parse('https://matrix.example.com'),
      ),
    ),
    versions: GetVersionsResponse(versions: ['v1.11']),
    loginFlows: [],
  );

  test('starts with no summary', () {
    final container = ProviderContainer.test();

    expect(container.read(loginHomeserverSummaryProvider), isNull);
  });

  test('set publishes the summary to watchers', () {
    final container = ProviderContainer.test();
    final seen = <HomeserverSummary?>[];
    container.listen(
      loginHomeserverSummaryProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    final summary = buildSummary();

    container.read(loginHomeserverSummaryProvider.notifier).set(summary);

    expect(seen, [null, summary]);
  });

  test('summary survives without listeners (keepAlive)', () async {
    final container = ProviderContainer.test();
    final summary = buildSummary();
    container.read(loginHomeserverSummaryProvider.notifier).set(summary);

    // Let any pending autoDispose cleanup run; keepAlive must prevent it.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(loginHomeserverSummaryProvider), same(summary));
  });
}
