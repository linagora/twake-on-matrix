import 'dart:async';
import 'dart:math' show Random;

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart' show Level, Logs, MatrixException;
import 'package:twake_chat/data/account/logout_removals.dart';

/// A source of randomness that always answers [value]: 1 keeps the whole
/// backoff, 0.5 halves it.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  int nextInt(int max) => (value * max).floor();
}

void main() {
  late LogoutRemovals removals;
  late List<String> log;
  late List<String> worked;
  late List<String> reports;
  late Set<String> failing;
  late Map<String, Object> errors;
  late Map<String, Completer<void>> gates;
  final noJitter = _FixedRandom(1);

  setUp(() {
    removals = LogoutRemovals(random: noJitter);
    log = [];
    worked = [];
    reports = [];
    failing = {};
    errors = {};
    gates = {};
  });

  Future<void> step(String name, String id) async {
    log.add('$name:$id');
    await gates['$name:$id']?.future;
    final error = errors['$name:$id'];
    if (error != null) throw error;
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

  /// Runs the removal of [id]. Its result is observed through [failedIds].
  Future<void> run(String id, {bool settleOnHold = true}) => removals.remove(
    id,
    stepsOf(id, settleOnHold: settleOnHold),
    (error, stackTrace, what) => reports.add(what),
  );

  /// Runs [id] 'a' again with the steps of another account.
  Future<void> runOther() => removals.remove(
    'a',
    stepsOf('other'),
    (error, stackTrace, what) => reports.add(what),
  );

  Future<void> failFirst(List<String> ids) async {
    for (final id in ids) {
      failing.add('remove:$id');
      await run(id);
    }
  }

  test('removes, then settles', () async {
    await run('a');

    expect(log, ['remove:a', 'settle:a']);
    expect(removals.failedIds, isEmpty);
    expect(reports, isEmpty);
  });

  test(
    'a removal that fails is reported, held, settled and recorded',
    () async {
      failing.add('remove:a');

      await run('a');

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

    await runOther();

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
      await failFirst(['a', 'b']);
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

  test('forget keeps a running removal pending until it settles', () async {
    gates['remove:a'] = Completer<void>();
    final running = run('a');
    await pumpEventQueue();
    expect(removals.isPending('a'), isTrue);

    expect(removals.forget('a'), isTrue);

    expect(removals.failedIds, isEmpty);
    expect(removals.isPending('a'), isTrue);
    gates['remove:a']!.complete();
    await running;

    expect(removals.isPending('a'), isFalse);
  });

  test('forget drops a kept removal, so new steps run', () async {
    failing.add('remove:a');
    await run('a');
    expect(removals.forget('a'), isTrue);
    expect(removals.failedIds, isEmpty);
    expect(removals.forget('a'), isFalse);
    log.clear();

    await runOther();

    expect(log, contains('remove:other'));
    expect(log.where((e) => e.endsWith(':a')), isEmpty);
  });

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

      await run('a');
      expect(removals.isPending('a'), isFalse);
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

      await run('a');
      expect(log, ['remove:a', 'hold:a']);
      expect(removals.isPending('a'), isTrue);
      expect(removals.failedIds, {'a'});
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

      await Future.wait([first, second]);

      // The steps ran once: the second call did not run them again.
      expect(log, ['remove:a', 'settle:a']);
      expect(removals.failedIds, isEmpty);
    },
  );

  test('retryAll retries each account that is not done', () async {
    await failFirst(['a', 'b']);
    failing.remove('remove:a');
    log.clear();

    await removals.retryAll();

    expect(log, ['remove:a', 'remove:b']);
    expect(removals.failedIds, {'b'});
  });

  int tries([String id = 'a']) => log.where((e) => e == 'remove:$id').length;

  /// Account [id] fails its removal for the first time, on the fake clock.
  void startFailing(FakeAsync async, {String id = 'a'}) {
    failing.add('remove:$id');
    run(id);
    async.flushMicrotasks();
  }

  void elapseMinutes(FakeAsync async, Iterable<int> minutes) {
    for (final m in minutes) {
      async.elapse(Duration(minutes: m));
    }
  }

  /// The tries of account 'a' after each wait, as (minutes waited, tries).
  void expectTriesAfter(FakeAsync async, List<(int, int)> steps) {
    for (final (wait, expected) in steps) {
      async.elapse(Duration(minutes: wait));
      expect(tries(), expected, reason: 'after waiting $wait more minutes');
    }
  }

  group('in the background', () {
    test('a failed removal is retried every interval until it works', () {
      fakeAsync((async) {
        startFailing(async);
        expect(tries(), 1);

        async.elapse(const Duration(minutes: 1));
        expect(tries(), 2);

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
          maxRetryEvery: const Duration(minutes: 4),
          random: noJitter,
        );
        startFailing(async);
        expect(tries(), 1);

        expectTriesAfter(async, [(1, 2), (1, 2), (1, 3), (4, 4), (4, 5)]);
      });
    });

    test('a settle that fails after the removal is retried too', () {
      fakeAsync((async) {
        failing.add('settle:a');
        run('a');
        async.flushMicrotasks();
        expect(removals.failedIds, {'a'});

        failing.clear();
        async.elapse(const Duration(minutes: 1));

        expect(removals.failedIds, isEmpty);
        expect(tries(), 1);
      });
    });

    test('the backoff starts again once the removals are done', () {
      fakeAsync((async) {
        startFailing(async);
        elapseMinutes(async, [1, 2]);
        failing.clear();
        async.elapse(const Duration(minutes: 4));
        expect(removals.failedIds, isEmpty);

        startFailing(async, id: 'b');
        expect(tries('b'), 1);

        async.elapse(const Duration(minutes: 1));

        expect(tries('b'), 2);
      });
    });

    test('a new removal has its own backoff, from the start', () {
      fakeAsync((async) {
        failing.add('remove:b');
        startFailing(async);
        elapseMinutes(async, [1, 2]);
        run('b');
        async.flushMicrotasks();
        expect(tries('b'), 1);

        async.elapse(const Duration(minutes: 1));
        expect(tries('b'), 2);
        async.elapse(const Duration(minutes: 2));

        expect(tries('b'), 3);
      });
    });

    test('dispose stops the retries', () {
      fakeAsync((async) {
        startFailing(async);

        removals.dispose();
        async.elapse(const Duration(minutes: 10));

        expect(tries(), 1);
      });
    });
  });

  group('the retries are bounded and spread out', () {
    /// The waits between the tries of 'a' over [total], from the first one.
    List<Duration> waitsOver(FakeAsync async, Duration total) {
      final times = [async.elapsed];
      var seen = tries();
      for (var i = 0; i < total.inSeconds; i++) {
        async.elapse(const Duration(seconds: 1));
        if (tries() > seen) {
          seen = tries();
          times.add(async.elapsed);
        }
      }
      return [for (var i = 1; i < times.length; i++) times[i] - times[i - 1]];
    }

    test('the background retries stop after the limit, with no timer left', () {
      fakeAsync((async) {
        removals = LogoutRemovals(maxRetryRounds: 3, random: noJitter);
        startFailing(async);

        async.elapse(const Duration(days: 1));

        expect(tries(), 4);
        expect(async.nonPeriodicTimerCount, 0);
        expect(removals.failedIds, {'a'});
        expect(reports, ['cannot remove logged-out account a']);
      });
    });

    /// With [under], the waits between the tries of 'a' are [seconds].
    void expectWaits(LogoutRemovals under, List<int> seconds) {
      fakeAsync((async) {
        removals = under;
        startFailing(async);

        final waits = waitsOver(async, const Duration(hours: 1));

        expect(waits.map((w) => w.inSeconds), seconds);
      });
    }

    test('the delays double up to the cap', () {
      expectWaits(
        LogoutRemovals(
          maxRetryEvery: const Duration(minutes: 5),
          maxRetryRounds: 6,
          random: noJitter,
        ),
        [60, 120, 240, 300, 300, 300],
      );
    });

    test('each delay is a random share of its ceiling', () {
      expectWaits(
        LogoutRemovals(maxRetryRounds: 3, random: _FixedRandom(0.5)),
        [30, 60, 120],
      );
    });

    group('after the last round', () {
      setUp(
        () => removals = LogoutRemovals(maxRetryRounds: 2, random: noJitter),
      );

      /// Every try is used up; then [ask] runs one try and arms no timer.
      void expectOneTryAndNoTimer(void Function() ask) {
        fakeAsync((async) {
          startFailing(async);
          async.elapse(const Duration(days: 1));
          expect(tries(), 3);
          expect(async.nonPeriodicTimerCount, 0);

          ask();
          async.flushMicrotasks();
          async.elapse(const Duration(days: 1));

          expect(tries(), 4);
          expect(async.nonPeriodicTimerCount, 0);
        });
      }

      test('a retry asked for by the app does not start the count again', () {
        expectOneTryAndNoTimer(() => removals.retryAll());
      });

      test('a removal asked for again does not start the count again', () {
        expectOneTryAndNoTimer(() => run('a'));
      });
    });

    test('retries asked for by the app do not keep the background going', () {
      fakeAsync((async) {
        removals = LogoutRemovals(maxRetryRounds: 3, random: noJitter);
        startFailing(async);

        // A login screen asks every 30 seconds, for longer than the three
        // rounds (1, 2 and 4 minutes) take.
        for (var i = 0; i < 20; i++) {
          async.elapse(const Duration(seconds: 30));
          removals.retryAll();
          async.flushMicrotasks();
        }

        expect(async.nonPeriodicTimerCount, 0);
      });
    });

    group('a rate limit from the server', () {
      MatrixException limit({
        String? retryAfter,
        int? retryAfterMs,
      }) => MatrixException(
        http.Response(
          '{"errcode":"M_LIMIT_EXCEEDED","error":"Too many requests"'
          '${retryAfterMs == null ? '' : ',"retry_after_ms":$retryAfterMs'}}',
          429,
          headers: {if (retryAfter != null) 'retry-after': retryAfter},
        ),
      );

      /// The removal of 'a' is refused with [error]; it is tried again after
      /// [seconds] seconds and not a second before.
      void expectRetryAfter(Object error, int seconds) {
        fakeAsync((async) {
          errors['remove:a'] = error;
          run('a');
          async.flushMicrotasks();

          async.elapse(Duration(seconds: seconds - 1));
          expect(tries(), 1);
          async.elapse(const Duration(seconds: 1));
          expect(tries(), 2);
        });
      }

      /// The removal of 'a' is refused with a 300 s rate limit, then [ask] is
      /// what the app does to try it again, 299 s later or, with
      /// [delayPassed], once the delay passed (after the background retry).
      void expectAskedAgain(void Function() ask, {required bool delayPassed}) {
        fakeAsync((async) {
          errors['remove:a'] = limit(retryAfter: '300');
          run('a');
          async.flushMicrotasks();
          if (delayPassed) {
            errors.remove('remove:a');
            failing.add('remove:a');
            async.elapse(const Duration(seconds: 301));
            expect(tries(), 2);
          } else {
            async.elapse(const Duration(seconds: 299));
          }
          final before = tries();

          ask();
          async.flushMicrotasks();

          expect(tries(), delayPassed ? before + 1 : before);
        });
      }

      test('is waited for when it is longer than the backoff', () {
        expectRetryAfter(limit(retryAfter: '300'), 300);
      });

      test('is used from retry_after_ms when there is no header', () {
        expectRetryAfter(limit(retryAfterMs: 180000), 180);
      });

      test('is read from the header before the body', () {
        expectRetryAfter(limit(retryAfter: '120', retryAfterMs: 900000), 120);
      });

      test('is ignored when it is shorter than the backoff', () {
        expectRetryAfter(limit(retryAfter: '5'), 60);
      });

      test('is not read from another error', () {
        expectRetryAfter(
          MatrixException(
            http.Response(
              '{"errcode":"M_FORBIDDEN","retry_after_ms":900000}',
              403,
              headers: {'retry-after': '900'},
            ),
          ),
          60,
        );
      });

      test('only delays the next round: the delay is not kept', () {
        fakeAsync((async) {
          errors['remove:a'] = limit(retryAfter: '600');
          run('a');
          async.flushMicrotasks();
          errors.remove('remove:a');
          failing.add('remove:a');
          async.elapse(const Duration(minutes: 10));
          expect(tries(), 2);

          async.elapse(const Duration(minutes: 2));

          expect(tries(), 3);
        });
      });

      // https://spec.matrix.org/v1.16/client-server-api/#rate-limiting
      test('a retry asked for by the app waits for the delay', () {
        expectAskedAgain(() => removals.retryAll(), delayPassed: false);
      });

      test('a retry asked for by the app goes ahead once the delay passed', () {
        expectAskedAgain(() => removals.retryAll(), delayPassed: true);
      });

      test('a removal asked for again waits for the delay, like a retry', () {
        expectAskedAgain(() => run('a'), delayPassed: false);
      });

      test('a removal asked for again goes ahead once the delay passed', () {
        expectAskedAgain(() => run('a'), delayPassed: true);
      });

      test('the delay asked for one removal does not delay another one', () {
        fakeAsync((async) {
          errors['remove:a'] = limit(retryAfter: '900');
          run('a');
          failing.add('remove:b');
          run('b');
          async.flushMicrotasks();

          async.elapse(const Duration(minutes: 1));

          expect(tries('a'), 1);
          expect(tries('b'), 2);
        });
      });

      test('a retry asked for by the app still runs the other removals', () {
        fakeAsync((async) {
          errors['remove:a'] = limit(retryAfter: '900');
          run('a');
          failing.add('remove:b');
          run('b');
          async.flushMicrotasks();

          removals.retryAll();
          async.flushMicrotasks();

          expect(tries('a'), 1);
          expect(tries('b'), 2);
        });
      });

      test('a new removal does not wait for the delay of another one', () {
        fakeAsync((async) {
          errors['remove:a'] = limit(retryAfter: '300');
          run('a');
          async.flushMicrotasks();

          run('b');
          async.flushMicrotasks();

          expect(tries('b'), 1);
        });
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

  group('an expected failure', () {
    test('is logged at debug level, never reported or warned', () async {
      errors['remove:a'] = const _Expected(retryInBackground: true);
      Logs().outputEvents.clear();

      await run('a');
      await removals.retryAll();

      expect(reports, isEmpty);
      expect(
        Logs().outputEvents.where((e) => e.level == Level.warning),
        isEmpty,
      );
      expect(log, ['remove:a', 'hold:a', 'settle:a', 'persist:a', 'remove:a']);
      expect(removals.failedIds, {'a'});
    });

    test('that asks to stop keeps the removal but does not retry it', () {
      fakeAsync((async) {
        errors['remove:a'] = const _Expected(retryInBackground: false);
        unawaited(run('a'));
        async.flushMicrotasks();
        log.clear();

        unawaited(removals.retryAll());
        async.elapse(const Duration(hours: 2));

        expect(log, isEmpty);
        expect(removals.failedIds, {'a'});

        errors.clear();
        unawaited(run('a'));
        async.flushMicrotasks();
        expect(log, ['remove:a']);
        expect(removals.failedIds, isEmpty);
      });
    });
  });
}

class _Expected implements ExpectedRemovalFailure {
  const _Expected({required this.retryInBackground});

  @override
  final bool retryInBackground;
}
