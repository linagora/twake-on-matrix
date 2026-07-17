import 'package:fluffychat/domain/model/homeserver_summary.dart';
import 'package:fluffychat/providers/login_homeserver_summary_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

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
    expect(container.read(loginHomeserverSummaryProvider), isNull);
  });

  test('set publishes the summary to watchers', () {
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
    final summary = buildSummary();
    container.read(loginHomeserverSummaryProvider.notifier).set(summary);

    // Let any pending autoDispose cleanup run; keepAlive must prevent it.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(loginHomeserverSummaryProvider), same(summary));
  });
}
