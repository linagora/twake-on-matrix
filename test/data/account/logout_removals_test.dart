// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/account/logout_removals.dart';

void main() {
  late LogoutRemovals removals;
  late List<String> log;
  late List<String> reports;
  late Set<String> failing;

  setUp(() {
    removals = LogoutRemovals();
    log = [];
    reports = [];
    failing = {};
  });

  Future<void> step(String name, String id) async {
    log.add('$name:$id');
    if (failing.contains('$name:$id')) throw StateError(name);
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
        'cannot remove logged-out account a',
      ]);
    },
  );

  test('a record is not written again once it worked', () async {
    failing.add('remove:a');
    await run('a');
    log.clear();

    await removals.retryAll();

    expect(log, ['remove:a']);
  });

  test('what a hold settled is not settled again by the removal', () async {
    failing.add('remove:a');
    await run('a');
    failing.clear();
    log.clear();

    await removals.retryAll();

    expect(log, ['remove:a']);
    expect(removals.failedIds, isEmpty);
  });

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
        async.elapse(const Duration(minutes: 1));
        expect(removals.failedIds, isEmpty);

        log.clear();
        async.elapse(const Duration(minutes: 5));
        expect(log, isEmpty);
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
}
