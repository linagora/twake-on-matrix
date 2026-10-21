import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/providers/login_sessions_provider.dart';

import 'fake_login_host.dart';

void main() {
  late LoginHostSlot slot;

  setUp(() => slot = LoginHostSlot());

  test('has no sessions before the host is set', () {
    expect(() => slot.sessions, throwsStateError);
  });

  test('keeps the sessions of the host that was set', () {
    slot.attach(FakeLoginHost());

    expect(slot.sessions, same(slot.sessions));
  });

  test('a host that was released gives way to the next one', () {
    final firstHost = FakeLoginHost();
    slot.attach(firstHost);
    final first = slot.sessions;

    slot.release(firstHost);
    expect(() => slot.sessions, throwsStateError);
    slot.attach(FakeLoginHost());

    expect(slot.sessions, isNot(same(first)));
  });

  test('a host that someone else replaced is not released', () {
    final firstHost = FakeLoginHost();
    slot.attach(firstHost);
    slot.attach(FakeLoginHost());
    final sessions = slot.sessions;

    slot.release(firstHost);

    expect(slot.sessions, same(sessions));
  });
}
