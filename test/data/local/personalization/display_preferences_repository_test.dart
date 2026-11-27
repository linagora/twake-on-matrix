import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.provider.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';

/// The repository of the app, over the device storage holding [stored].
DisplayPreferencesRepository _repository(Map<String, Object> stored) {
  SharedPreferences.setMockInitialValues(stored);
  final container = ProviderContainer.test();
  return container.read(displayPreferencesRepositoryProvider);
}

/// Every option set to a choice that is not its default, and the names the
/// device stores for them. These names and keys are what devices already hold:
/// they never change.
const _allOther = DisplayPreferencesState(
  density: ChatListDensity.compact,
  roomOrder: RoomOrder.sections,
);
const _allOtherStored = {
  SettingKeys.chatListDensity: 'compact',
  SettingKeys.roomOrder: 'sections',
};

Future<Map<String, Object?>> _device() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)};
}

void main() {
  _choicesTests();
}

void _choicesTests() {
  group('loading the display choices', () {
    test('nothing stored: the default of each option', () async {
      expect(await _repository({}).load(), const DisplayPreferencesState());
    });

    test('reads each option under its key', () async {
      expect(await _repository(_allOtherStored).load(), _allOther);
    });

    test('a stored value this version does not know: the default', () async {
      final stored = {
        for (final key in _allOtherStored.keys) key: 'from-the-future',
      };

      expect(await _repository(stored).load(), const DisplayPreferencesState());
    });

    test('one unknown stored value does not lose the others', () async {
      final repository = _repository({
        SettingKeys.chatListDensity: 'cosy',
        SettingKeys.roomOrder: 'sections',
      });

      expect(
        await repository.load(),
        const DisplayPreferencesState(roomOrder: RoomOrder.sections),
      );
    });
  });

  group('saving the display choices', () {
    test('stores each option under its key, by its name', () async {
      final repository = _repository({});

      await repository.save(_allOther);

      expect(await _device(), _allOtherStored);
    });

    test('what is saved is what the next load reads', () async {
      final repository = _repository({});

      await repository.save(_allOther);

      expect(await repository.load(), _allOther);
    });

    test(
      'a choice set back to its default is read back as the default',
      () async {
        final repository = _repository(_allOtherStored);

        await repository.save(const DisplayPreferencesState());

        expect(await repository.load(), const DisplayPreferencesState());
      },
    );
  });
}
