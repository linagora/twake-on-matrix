import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/account/client_subscriptions.dart';

void main() {
  late ClientSubscriptions subscriptions;
  late List<String> log;
  late Set<String> failing;

  setUp(() {
    subscriptions = ClientSubscriptions();
    log = [];
    failing = {};
  });

  CancelSubscription Function() listen(String what) => () {
    log.add('listen:$what');
    return () async {
      log.add('cancel:$what');
      if (failing.contains(what)) throw StateError(what);
    };
  };

  test('keeps one subscription of each kind per client', () {
    subscriptions.open('a');

    subscriptions.keep('a', 'sync', listen('a-sync'));
    subscriptions.keep('a', 'sync', listen('a-sync-again'));
    subscriptions.keep('a', 'uia', listen('a-uia'));

    expect(log, ['listen:a-sync', 'listen:a-uia']);
  });

  test('does not start a subscription for a client that is not open', () {
    subscriptions.keep('a', 'sync', listen('a-sync'));

    expect(log, isEmpty);
  });

  test('cancels the subscriptions of one client only', () async {
    subscriptions
      ..open('a')
      ..open('b')
      ..keep('a', 'sync', listen('a-sync'))
      ..keep('b', 'sync', listen('b-sync'));

    await subscriptions.cancel('a');

    expect(log, ['listen:a-sync', 'listen:b-sync', 'cancel:a-sync']);
  });

  test('a subscription that is started after the cancel is dropped', () async {
    subscriptions
      ..open('a')
      ..keep('a', 'sync', listen('a-sync'));
    await subscriptions.cancel('a');
    log.clear();

    // A set-up that was still waiting when the login was rolled back.
    subscriptions.keep('a', 'notification', listen('a-notification'));

    expect(log, isEmpty);
    expect(subscriptions.isOpen('a'), isFalse);
  });

  test('a client can be opened again after a cancel', () async {
    subscriptions.open('a');
    await subscriptions.cancel('a');

    subscriptions
      ..open('a')
      ..keep('a', 'sync', listen('a-sync'));

    expect(log, ['listen:a-sync']);
  });

  test(
    'a cancel that fails is thrown and a second call finishes the rest',
    () async {
      subscriptions
        ..open('a')
        ..keep('a', 'one', listen('one'))
        ..keep('a', 'two', listen('two'))
        ..keep('a', 'three', listen('three'));
      failing.add('two');

      await expectLater(subscriptions.cancel('a'), throwsStateError);
      failing.clear();
      log.clear();
      await subscriptions.cancel('a');

      expect(log, ['cancel:two', 'cancel:three']);
    },
  );

  test('cancelAll cancels every client', () async {
    subscriptions
      ..open('a')
      ..open('b')
      ..keep('a', 'sync', listen('a-sync'))
      ..keep('b', 'sync', listen('b-sync'));
    log.clear();

    await subscriptions.cancelAll();

    expect(log, unorderedEquals(['cancel:a-sync', 'cancel:b-sync']));
  });
}
