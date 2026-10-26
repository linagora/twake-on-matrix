import 'dart:async';

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

  void openWithSync(List<String> ids) {
    for (final id in ids) {
      subscriptions
        ..open(id)
        ..keep(id, 'sync', listen('$id-sync'));
    }
  }

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
    openWithSync(['a', 'b']);

    await subscriptions.cancel('a');

    expect(log, ['listen:a-sync', 'listen:b-sync', 'cancel:a-sync']);
  });

  test('a subscription that is started after the cancel is dropped', () async {
    openWithSync(['a']);
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

    openWithSync(['a']);

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
    openWithSync(['a', 'b']);
    log.clear();

    await subscriptions.cancelAll();

    expect(log, unorderedEquals(['cancel:a-sync', 'cancel:b-sync']));
  });

  group('keepOnce', () {
    late StreamController<int> trigger;

    setUp(() => trigger = StreamController<int>.broadcast());
    tearDown(() => trigger.close());

    test('runs the action on the first event only', () async {
      subscriptions.open('a');
      var runs = 0;
      subscriptions.keepOnce('a', 'first', trigger.stream, () async => runs++);

      trigger
        ..add(1)
        ..add(2);
      await pumpEventQueue();

      expect(runs, 1);
    });

    test('does not run it once the client was closed', () async {
      subscriptions.open('a');
      var runs = 0;
      subscriptions.keepOnce('a', 'first', trigger.stream, () async => runs++);

      await subscriptions.cancel('a');
      trigger.add(1);
      await pumpEventQueue();

      expect(runs, 0);
    });

    test('a failing action is logged, not thrown into the zone', () async {
      subscriptions.open('a');
      subscriptions.keepOnce(
        'a',
        'first',
        trigger.stream,
        () async => throw StateError('action'),
      );

      trigger.add(1);
      await pumpEventQueue();
    });
  });

  group('runGuarded', () {
    test('does not run the set-up for a client that is not open', () async {
      await subscriptions.runGuarded(
        'a',
        setUp: () async => log.add('setUp'),
        undo: () async => log.add('undo'),
      );

      expect(log, isEmpty);
    });

    test('undoes a set-up that finished after the client was closed', () async {
      subscriptions.open('a');
      final gate = Completer<void>();
      final run = subscriptions.runGuarded(
        'a',
        setUp: () async {
          log.add('setUp');
          await gate.future;
        },
        undo: () async => log.add('undo'),
      );
      await subscriptions.cancel('a');

      gate.complete();
      await run;

      expect(log, ['setUp', 'undo']);
    });

    test('undoes a set-up that failed after the client was closed, and '
        'throws its error', () async {
      subscriptions.open('a');
      final gate = Completer<void>();
      final run = subscriptions.runGuarded(
        'a',
        setUp: () async {
          log.add('setUp');
          await gate.future;
          throw StateError('half done');
        },
        undo: () async => log.add('undo'),
      );
      final thrown = expectLater(run, throwsStateError);
      await subscriptions.cancel('a');

      gate.complete();
      await thrown;

      expect(log, ['setUp', 'undo']);
    });

    test('keeps a set-up of a client that is still open', () async {
      subscriptions.open('a');

      await subscriptions.runGuarded(
        'a',
        setUp: () async => log.add('setUp'),
        undo: () async => log.add('undo'),
      );

      expect(log, ['setUp']);
    });
  });
}
