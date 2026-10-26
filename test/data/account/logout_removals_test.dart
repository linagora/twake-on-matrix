import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart' show Level, Logs;
import 'package:twake_chat/data/account/logout_removals.dart';

void main() {
  late LogoutRemovals removals;
  late List<String> log;
  late List<String> worked;
  late List<String> reports;
  late Set<String> failing;
  late Map<String, Completer<void>> gates;

  setUp(() {
    removals = LogoutRemovals();
    log = [];
    worked = [];
    reports = [];
    failing = {};
    gates = {};
  });

  Future<void> step(String name, String id) async {
    log.add('$name:$id');
    await gates['$name:$id']?.future;
    if (failing.contains('$name:$id')) throw StateError(name);
    worked.add(name);
  }

  RemovalSteps stepsOf(String id, {bool settleOnHold = true}) => RemovalSteps(
    remove: () => step('remove', id),
    hold: () => step('hold', id),
    persist: () => step('persist', id),
    settle: () => step('settle', id),
    settleOnHold: settleOnHold,
  );

  Future<bool> run(String id, {bool settleOnHold = true}) => removals.remove(
    id,
    stepsOf(id, settleOnHold: settleOnHold),
    (error, stackTrace, what) => reports.add(what),
  );

  test('removes, then settles', () async {
    expect(await run('a'), isTrue);

    expect(log, ['remove:a', 'settle:a']);
    expect(removals.failedIds, isEmpty);
    expect(reports, isEmpty);
  });

  test(
    'a removal that fails is reported, held, settled and recorded',
    () async {
      failing.add('remove:a');

      expect(await run('a'), isFalse);

      expect(log, ['remove:a', 'hold:a', 'settle:a', 'persist:a']);
      expect(removals.failedIds, {'a'});
      expect(reports, ['cannot remove logged-out account a']);
    },
  );

  test(
    'a step that keeps failing is reported once, then only logged',
    () async {
      failing.add('remove:a');
      await run('a');
      Logs().outputEvents.clear();

      await removals.retryAll();
      await removals.retryAll();

      expect(reports, ['cannot remove logged-out account a']);
      expect(
        Logs().outputEvents.where((e) => e.level == Level.warning),
        hasLength(2),
      );
    },
  );

  test('new steps for a removal that is kept are ignored and logged', () async {
    failing.add('remove:a');
    await run('a');
    log.clear();
    Logs().outputEvents.clear();

    await removals.remove(
      'a',
      stepsOf('other'),
      (error, stackTrace, what) => reports.add(what),
    );

    expect(log.where((e) => e.endsWith(':other')), isEmpty);
    expect(
      Logs().outputEvents.where(
        (e) => e.level == Level.warning && e.title.contains('ignored'),
      ),
      isNotEmpty,
    );
  });

  test(
    'retryAll skips a removal that another call finished meanwhile',
    () async {
      failing.addAll(['remove:a', 'remove:b']);
      await run('a');
      await run('b');
      failing.clear();
      log.clear();
      gates['remove:a'] = Completer<void>();

      final retry = removals.retryAll();
      await pumpEventQueue();
      await run('b');
      gates['remove:a']!.complete();
      await retry;

      expect(log.where((e) => e == 'remove:b'), hasLength(1));
      expect(removals.failedIds, isEmpty);
    },
  );

  test('a retry runs the removal again and nothing that is done', () async {
    failing.add('remove:a');
    await run('a');
    failing.clear();
    log.clear();

    await removals.retryAll();

    expect(log, ['remove:a']);
    expect(removals.failedIds, isEmpty);
  });

  test(
    'a retry that fails again keeps the removal and holds it once',
    () async {
      failing.add('remove:a');
      await run('a');

      await removals.retryAll();
      await removals.retryAll();

      expect(removals.failedIds, {'a'});
      expect(log.where((e) => e == 'hold:a'), hasLength(1));
      expect(log.where((e) => e == 'persist:a'), hasLength(1));
      expect(log.where((e) => e == 'settle:a'), hasLength(1));
    },
  );

  test(
    'a settle that fails after the removal is retried alone, the removal never runs again',
    () async {
      failing.add('settle:a');

      expect(await run('a'), isTrue);
      expect(removals.failedIds, {'a'});
      failing.clear();
      await removals.retryAll();

      expect(removals.failedIds, isEmpty);
      expect(log, ['remove:a', 'settle:a', 'settle:a']);
      expect(reports, ['after the change of account a']);
    },
  );

  test(
    'a hold that fails is retried until it works and nothing follows before',
    () async {
      failing.addAll(['remove:a', 'hold:a']);

      expect(await run('a'), isFalse);
      expect(log, ['remove:a', 'hold:a']);
      expect(reports, [
        'cannot remove logged-out account a',
        'cannot hold account a as unavailable',
      ]);

      failing.remove('hold:a');
      log.clear();
      await removals.retryAll();

      expect(log, ['remove:a', 'hold:a', 'settle:a', 'persist:a']);
    },
  );

  test(
    'a record that cannot be written is retried alone: the hold and the settle are not repeated',
    () async {
      failing.addAll(['remove:a', 'persist:a']);
      await run('a');
      failing.remove('persist:a');
      log.clear();

      await removals.retryAll();

      expect(log, ['remove:a', 'persist:a']);
      expect(reports, [
        'cannot remove logged-out account a',
        'cannot record the pending removal of account a',
      ]);
    },
  );

  test(
    'a settle that only follows a removal waits for it, a record is kept until then',
    () async {
      failing.add('remove:p');

      await run('p', settleOnHold: false);
      expect(log, ['remove:p', 'hold:p', 'persist:p']);

      failing.clear();
      log.clear();
      await removals.retryAll();

      expect(log, ['remove:p', 'settle:p']);
      expect(removals.failedIds, isEmpty);
    },
  );

  test(
    'a second removal of an account that is being removed is ignored',
    () async {
      final first = run('a');
      final second = run('a');

      expect(await second, isFalse);
      expect(await first, isTrue);
      expect(log, ['remove:a', 'settle:a']);
    },
  );

  test('retryAll retries each account that is not done', () async {
    failing.addAll(['remove:a', 'remove:b']);
    await run('a');
    await run('b');
    failing.remove('remove:a');
    log.clear();

    await removals.retryAll();

    expect(log, ['remove:a', 'remove:b']);
    expect(removals.failedIds, {'b'});
  });

  group('in the background', () {
    test('a failed removal is retried every interval until it works', () {
      fakeAsync((async) {
        removals = LogoutRemovals(retryEvery: const Duration(minutes: 1));
        failing.add('remove:a');
        run('a');
        async.flushMicrotasks();
        expect(log.where((e) => e == 'remove:a'), hasLength(1));

        async.elapse(const Duration(minutes: 1));
        expect(log.where((e) => e == 'remove:a'), hasLength(2));

        failing.clear();
        async.elapse(const Duration(minutes: 2));
        expect(removals.failedIds, isEmpty);

        log.clear();
        async.elapse(const Duration(minutes: 5));
        expect(log, isEmpty);
      });
    });

    test('the retries back off, up to a limit', () {
      fakeAsync((async) {
        removals = LogoutRemovals(
          retryEvery: const Duration(minutes: 1),
          maxRetryEvery: const Duration(minutes: 4),
        );
        failing.add('remove:a');
        run('a');
        async.flushMicrotasks();
        int tries() => log.where((e) => e == 'remove:a').length;
        expect(tries(), 1);

        async.elapse(const Duration(minutes: 1));
        expect(tries(), 2);
        async.elapse(const Duration(minutes: 1));
        expect(tries(), 2);
        async.elapse(const Duration(minutes: 1));
        expect(tries(), 3);
        async.elapse(const Duration(minutes: 4));
        expect(tries(), 4);
        async.elapse(const Duration(minutes: 4));
        expect(tries(), 5);
      });
    });

    test('a settle that fails after the removal is retried too', () {
      fakeAsync((async) {
        removals = LogoutRemovals(retryEvery: const Duration(minutes: 1));
        failing.add('settle:a');
        run('a');
        async.flushMicrotasks();
        expect(removals.failedIds, {'a'});

        failing.clear();
        async.elapse(const Duration(minutes: 1));

        expect(removals.failedIds, isEmpty);
        expect(log.where((e) => e == 'remove:a'), hasLength(1));
      });
    });

    test('the backoff starts again once the removals are done', () {
      fakeAsync((async) {
        failing.add('remove:a');
        run('a');
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 1));
        async.elapse(const Duration(minutes: 2));
        failing.clear();
        async.elapse(const Duration(minutes: 4));
        expect(removals.failedIds, isEmpty);

        failing.add('remove:b');
        run('b');
        async.flushMicrotasks();
        int tries() => log.where((e) => e == 'remove:b').length;
        expect(tries(), 1);

        async.elapse(const Duration(minutes: 1));

        expect(tries(), 2);
      });
    });

    test('a new removal starts the backoff again for the others', () {
      fakeAsync((async) {
        failing.addAll(['remove:a', 'remove:b']);
        run('a');
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 1));
        async.elapse(const Duration(minutes: 2));
        run('b');
        async.flushMicrotasks();
        int tries() => log.where((e) => e == 'remove:b').length;
        expect(tries(), 1);

        async.elapse(const Duration(minutes: 4));
        expect(tries(), 2);
        async.elapse(const Duration(minutes: 2));

        expect(tries(), 3);
      });
    });

    test('dispose stops the retries', () {
      fakeAsync((async) {
        removals = LogoutRemovals(retryEvery: const Duration(minutes: 1));
        failing.add('remove:a');
        run('a');
        async.flushMicrotasks();

        removals.dispose();
        async.elapse(const Duration(minutes: 10));

        expect(log.where((e) => e == 'remove:a'), hasLength(1));
      });
    });
  });

  group('whichever steps fail', () {
    const names = ['remove', 'hold', 'persist', 'settle'];
    for (var mask = 0; mask < 16; mask++) {
      for (final settleOnHold in [true, false]) {
        final failures = [
          for (var i = 0; i < names.length; i++)
            if (mask & (1 << i) != 0) names[i],
        ];
        test('failing ${failures.isEmpty ? 'nothing' : failures.join(', ')}'
            '${settleOnHold ? '' : ' (no settle on hold)'}: a step that worked '
            'never runs again, and a clean retry ends it', () async {
          failing.addAll([for (final name in failures) '$name:a']);
          await run('a', settleOnHold: settleOnHold);
          failing.clear();

          await removals.retryAll();

          for (final name in names) {
            expect(
              worked.where((e) => e == name).length,
              lessThanOrEqualTo(1),
              reason: '$name worked more than once',
            );
          }
          expect(removals.failedIds, isEmpty);
        });
      }
    }
  });
}
