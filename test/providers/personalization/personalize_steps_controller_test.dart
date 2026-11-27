import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.provider.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';
import 'package:twake_chat/providers/personalization/personalize_steps_controller.dart';

import 'fake_display_preferences_repository.dart';

const _allIds = {'density', 'order', 'seen-style', 'composer', 'align'};
const _phoneIds = {'density', 'order', 'seen-style', 'align'};

/// A started app over [storage].
class _App {
  _App(this.storage)
    : container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          displayPreferencesRepositoryProvider.overrideWithValue(storage),
        ],
      );

  /// A device that saw [seen], started.
  _App.seen(Set<String> seen)
    : this(FakeDisplayPreferencesRepository(seen: seen));

  final FakeDisplayPreferencesRepository storage;
  final ProviderContainer container;

  PersonalizeStepsController get controller =>
      container.read(personalizeStepsControllerProvider.notifier);

  /// The seen step ids the app holds now, in its `PersonalizeStepsState`.
  Set<String> get seen =>
      container.read(personalizeStepsControllerProvider).requireValue.seen;

  /// What the app is handed when it opens the flow, on a wide screen unless
  /// [isWide] says otherwise.
  Future<List<PersonalizeStep>> pending({bool isWide = true}) =>
      controller.pending(isWide: isWide);

  /// Marks [steps] seen and lets the storage answer.
  Future<void> markSeen(Iterable<PersonalizeStep> steps) async {
    await controller.markSeen(steps);
    await pumpEventQueue();
  }

  /// The same device started again.
  _App restart() => _App(storage);
}

void main() {
  _pendingTests();
  _markSeenTests();
}

void _pendingTests() {
  group('the steps to ask at start', () {
    for (final (name, seen, isWide, expected) in [
      (
        'a wide screen never asked: all five, in order',
        <String>{},
        true,
        PersonalizeStep.values,
      ),
      (
        'a phone never asked: the four steps without the composer',
        <String>{},
        false,
        const [
          PersonalizeStep.density,
          PersonalizeStep.order,
          PersonalizeStep.seenStyle,
          PersonalizeStep.align,
        ],
      ),
      (
        'a device that saw every step: none',
        _allIds,
        true,
        <PersonalizeStep>[],
      ),
      (
        'a device that saw the first two steps: the three others',
        {'density', 'order'},
        true,
        const [
          PersonalizeStep.seenStyle,
          PersonalizeStep.composer,
          PersonalizeStep.align,
        ],
      ),
      (
        'a device that saw the steps of an older release: the new step alone',
        {'density', 'order', 'composer', 'align'},
        true,
        const [PersonalizeStep.seenStyle],
      ),
      (
        'a phone that saw its four steps: none',
        _phoneIds,
        false,
        <PersonalizeStep>[],
      ),
      (
        'a tablet, after a phone saw its four steps: the composer alone',
        _phoneIds,
        true,
        const [PersonalizeStep.composer],
      ),
      (
        '« theme », stored by a later version, hides no step',
        {'theme'},
        true,
        PersonalizeStep.values,
      ),
    ]) {
      test(name, () async {
        expect(await _App.seen(seen).pending(isWide: isWide), expected);
      });
    }

    test('asked before the storage has answered: waits for it, so a device '
        'that saw every step is never given one', () async {
      final storage = FakeDisplayPreferencesRepository(seen: _allIds)
        ..holdLoads();
      final app = _App(storage);

      final pending = app.pending();
      storage.answer();

      expect(await pending, isEmpty);
    });

    test('a storage that cannot be read: every step', () async {
      final app = _App(FakeDisplayPreferencesRepository(failLoad: true));

      expect(await app.pending(), PersonalizeStep.values);
    });

    test('the state is the seen ids the device holds', () async {
      final app = _App.seen({'density', 'wallpaper'});

      await app.pending();

      expect(app.seen, {'density', 'wallpaper'});
    });

    test('loading them never writes to the device', () async {
      final app = _App.seen({'density'});

      await app.pending();

      expect(app.storage.writes, 0);
    });
  });
}

void _markSeenTests() {
  group('marking steps seen', () {
    test('they are not asked at the next start', () async {
      final app = _App.seen({});

      await app.markSeen(PersonalizeStep.values);

      expect(await app.restart().pending(), isEmpty);
    });

    test('state and pending agree at once in the running app', () async {
      final app = _App.seen({});

      await app.markSeen(const [
        PersonalizeStep.density,
        PersonalizeStep.order,
      ]);

      expect(app.seen, {'density', 'order'});
      expect(await app.pending(), [
        PersonalizeStep.seenStyle,
        PersonalizeStep.composer,
        PersonalizeStep.align,
      ]);
    });

    test('pending on a phone never includes the composer, whatever was '
        'marked', () async {
      final app = _App.seen({});

      await app.markSeen(const [PersonalizeStep.density]);

      expect(
        await app.pending(isWide: false),
        isNot(contains(PersonalizeStep.composer)),
      );
      expect(await app.pending(isWide: false), [
        PersonalizeStep.order,
        PersonalizeStep.seenStyle,
        PersonalizeStep.align,
      ]);
    });

    test('a step not marked is still asked at the next start', () async {
      final app = _App.seen({});

      await app.markSeen(
        PersonalizeStep.values.where((step) => step != PersonalizeStep.align),
      );

      expect(await app.restart().pending(), [PersonalizeStep.align]);
    });

    test('adds to what the device had stored, ids of a newer version '
        'included, each id once', () async {
      final app = _App.seen({'wallpaper', 'density'});

      await app.markSeen(PersonalizeStep.values);

      expect(app.storage.savedSeen.last, {'wallpaper', ..._allIds});
      expect(app.seen, {'wallpaper', ..._allIds});
    });

    test('before the storage has answered: what was stored is kept', () async {
      final storage = FakeDisplayPreferencesRepository(seen: {'wallpaper'})
        ..holdLoads();
      final app = _App(storage);

      final marking = app.controller.markSeen(const [PersonalizeStep.align]);
      storage.answer();
      await marking;
      await pumpEventQueue();

      expect(storage.savedSeen.last, {'wallpaper', 'align'});
      expect(app.seen, {'wallpaper', 'align'});
    });

    // Review of #3844: the state is a value; marking again what is seen
    // already leaves it equal, and nothing that listens is woken.
    test('marking steps seen already: the state stays equal, no listener is '
        'told', () async {
      final app = _App.seen({'density', 'order'});
      await app.pending();
      var notified = 0;
      app.container.listen(
        personalizeStepsControllerProvider,
        (_, _) => notified++,
      );

      await app.markSeen(const [PersonalizeStep.order]);

      expect(notified, 0);
      expect(app.seen, {'density', 'order'});
    });

    test('marking a new step seen: listeners are told once', () async {
      final app = _App.seen({'density'});
      await app.pending();
      var notified = 0;
      app.container.listen(
        personalizeStepsControllerProvider,
        (_, _) => notified++,
      );

      await app.markSeen(const [PersonalizeStep.order]);

      expect(notified, 1);
      expect(app.seen, {'density', 'order'});
    });

    test('a storage that refuses the write: no error, and the running app '
        'does not ask them again', () async {
      final app = _App(FakeDisplayPreferencesRepository(failSave: true));

      await app.markSeen(PersonalizeStep.values);

      expect(await app.pending(), isEmpty);
    });
  });
}
