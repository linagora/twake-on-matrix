import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/account/login_sessions.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';

import '../data/account/fake_login_host.dart';

void main() {
  late ProviderContainer container;
  late LoginSessions sessions;

  setUp(() {
    container = ProviderContainer.test();
    sessions = container.read(loginSessionsProvider);
  });

  test('is one instance for the whole container', () {
    expect(container.read(loginSessionsProvider), same(sessions));
  });

  test('has no host before one is attached', () async {
    await expectLater(sessions.loginClient(), throwsStateError);
  });

  test('serves the host that was attached', () async {
    final host = FakeLoginHost();
    sessions.attach(host);

    expect((await sessions.loginClient()).clientName, 'c1');
  });

  test('a host that was released gives way to the next one', () async {
    final firstHost = FakeLoginHost();
    sessions.attach(firstHost);
    final first = await sessions.loginClient();

    sessions.release(firstHost);
    await expectLater(sessions.loginClient(), throwsStateError);
    sessions.attach(FakeLoginHost());

    expect(await sessions.loginClient(), isNot(same(first)));
  });

  test('a host that someone else attached since is not released', () async {
    final firstHost = FakeLoginHost();
    sessions.attach(firstHost);
    sessions.attach(FakeLoginHost());

    sessions.release(firstHost);

    expect((await sessions.loginClient()).clientName, 'c1');
  });
}
