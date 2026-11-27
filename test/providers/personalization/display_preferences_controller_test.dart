import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.provider.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/providers/personalization/display_preferences_controller.dart';

import 'fake_display_preferences_repository.dart';

/// One option of the display preferences: a choice that is not the default,
/// how to choose it, how to read it and the choices with it set.
class _Option {
  const _Option(
    this.name, {
    required this.other,
    required this.choose,
    required this.read,
    required this.withOther,
  });

  final String name;

  /// The name of a choice that is not the default.
  final String other;
  final void Function(DisplayPreferencesController controller) choose;
  final String Function(DisplayPreferencesState preferences) read;
  final DisplayPreferencesState Function(DisplayPreferencesState preferences)
  withOther;
}

final _options = [
  _Option(
    'density',
    other: 'compact',
    choose: (controller) => controller.setDensity(ChatListDensity.compact),
    read: (preferences) => preferences.density.name,
    withOther: (p) => p.copyWith(density: ChatListDensity.compact),
  ),
  _Option(
    'room order',
    other: 'sections',
    choose: (controller) => controller.setRoomOrder(RoomOrder.sections),
    read: (preferences) => preferences.roomOrder.name,
    withOther: (p) => p.copyWith(roomOrder: RoomOrder.sections),
  ),
  _Option(
    'bubble alignment',
    other: 'left',
    choose: (controller) => controller.setBubbleAlign(BubbleAlign.left),
    read: (preferences) => preferences.bubbleAlign.name,
    withOther: (p) => p.copyWith(bubbleAlign: BubbleAlign.left),
  ),
];

/// Every option set to its other choice.
final _allOther = _options.fold(
  const DisplayPreferencesState(),
  (preferences, option) => option.withOther(preferences),
);

/// A started app over [storage]: the controller is listened to. `heard`
/// holds every set of choices the app was given.
class _App {
  _App(this.storage) {
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        displayPreferencesRepositoryProvider.overrideWithValue(storage),
      ],
    );
    container.listen(displayPreferencesControllerProvider, (_, next) {
      if (next.hasValue) heard.add(next.requireValue);
    });
  }

  final FakeDisplayPreferencesRepository storage;
  late final ProviderContainer container;
  final heard = <DisplayPreferencesState>[];

  /// The app once the storage has answered.
  static Future<_App> loaded(FakeDisplayPreferencesRepository storage) async {
    final app = _App(storage);
    await app.container.read(displayPreferencesControllerProvider.future);
    await pumpEventQueue();
    app.heard.clear();
    return app;
  }

  AsyncValue<DisplayPreferencesState> get state =>
      container.read(displayPreferencesControllerProvider);

  DisplayPreferencesState get preferences => state.requireValue;

  DisplayPreferencesController get controller =>
      container.read(displayPreferencesControllerProvider.notifier);

  bool get alignOwnRight => container.read(alignOwnMessagesRightProvider);

  /// The same device started again.
  Future<_App> restart() => loaded(storage);
}

void main() {
  _loadingTests();
  _optionTests();
  _choiceTests();
}

void _loadingTests() {
  group('the display preferences of the device', () {
    test('nothing stored: the default of each option', () async {
      final app = await _App.loaded(FakeDisplayPreferencesRepository());

      expect(app.preferences, const DisplayPreferencesState());
    });

    test('what the device stored is what the app shows', () async {
      final app = await _App.loaded(
        FakeDisplayPreferencesRepository(stored: _allOther),
      );

      expect(app.preferences, _allOther);
    });

    test('loading them never writes to the device', () async {
      final storage = FakeDisplayPreferencesRepository(stored: _allOther);

      await _App.loaded(storage);

      expect(storage.writes, 0);
    });

    test('a storage that cannot be read: the default of each option', () async {
      final app = await _App.loaded(
        FakeDisplayPreferencesRepository(failLoad: true),
      );

      expect(app.preferences, const DisplayPreferencesState());
      expect(app.alignOwnRight, isTrue);
    });
  });

  group('own messages on the right', () {
    test('while the storage has not answered: on the right, the default', () {
      final storage = FakeDisplayPreferencesRepository(
        stored: const DisplayPreferencesState(bubbleAlign: BubbleAlign.left),
      )..holdLoads();
      final app = _App(storage);

      expect(app.state.isLoading, isTrue);
      expect(app.alignOwnRight, isTrue);
    });

    test('every message on the left once the device said so', () async {
      final app = await _App.loaded(
        FakeDisplayPreferencesRepository(
          stored: const DisplayPreferencesState(bubbleAlign: BubbleAlign.left),
        ),
      );

      expect(app.alignOwnRight, isFalse);
    });

    test('follows a choice', () async {
      final app = await _App.loaded(FakeDisplayPreferencesRepository());

      app.controller.setBubbleAlign(BubbleAlign.left);
      await pumpEventQueue();

      expect(app.alignOwnRight, isFalse);
    });
  });
}

void _optionTests() {
  for (final option in _options) {
    group('choosing the ${option.name}', () {
      test('shows at once to who listens', () async {
        final app = await _App.loaded(FakeDisplayPreferencesRepository());

        option.choose(app.controller);
        await pumpEventQueue();

        expect(option.read(app.preferences), option.other);
        expect(app.heard.map(option.read), [option.other]);
      });

      test('is kept on the device: the next start reads it', () async {
        final app = await _App.loaded(FakeDisplayPreferencesRepository());

        option.choose(app.controller);
        await pumpEventQueue();

        expect(app.storage.saved.map(option.read), [option.other]);
        final restarted = await app.restart();
        expect(option.read(restarted.preferences), option.other);
      });

      test('leaves the other options as they were', () async {
        final before = _options
            .where((other) => other != option)
            .fold(
              const DisplayPreferencesState(),
              (preferences, other) => other.withOther(preferences),
            );
        final app = await _App.loaded(
          FakeDisplayPreferencesRepository(stored: before),
        );

        option.choose(app.controller);
        await pumpEventQueue();

        expect(app.preferences, option.withOther(before));
        expect(app.storage.saved.last, option.withOther(before));
      });
    });
  }
}

void _choiceTests() {
  group('a choice', () {
    test('can be changed back', () async {
      final app = await _App.loaded(
        FakeDisplayPreferencesRepository(
          stored: const DisplayPreferencesState(
            density: ChatListDensity.compact,
          ),
        ),
      );

      app.controller.setDensity(ChatListDensity.comfortable);
      await pumpEventQueue();

      expect(app.preferences.density, ChatListDensity.comfortable);
      final restarted = await app.restart();
      expect(restarted.preferences.density, ChatListDensity.comfortable);
    });

    test(
      'before the storage has answered: the choice wins over what was stored',
      () async {
        final storage = FakeDisplayPreferencesRepository(
          stored: const DisplayPreferencesState(
            density: ChatListDensity.compact,
            bubbleAlign: BubbleAlign.left,
          ),
        )..holdLoads();
        final app = _App(storage);

        app.controller.setDensity(ChatListDensity.comfortable);
        storage.answer();
        await pumpEventQueue();

        expect(app.preferences.density, ChatListDensity.comfortable);
        // The preference not touched is still the stored one.
        expect(app.preferences.bubbleAlign, BubbleAlign.left);
        final restarted = await app.restart();
        expect(restarted.preferences.density, ChatListDensity.comfortable);
        expect(restarted.preferences.bubbleAlign, BubbleAlign.left);
      },
    );

    test('a storage that refuses the write: the choice still shows', () async {
      final app = await _App.loaded(
        FakeDisplayPreferencesRepository(failSave: true),
      );

      app.controller.setDensity(ChatListDensity.compact);
      await pumpEventQueue();

      expect(app.preferences.density, ChatListDensity.compact);
    });
  });
}
