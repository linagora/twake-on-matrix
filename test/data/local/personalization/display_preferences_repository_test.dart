import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.dart';
import 'package:twake_chat/data/local/personalization/display_preferences_repository.provider.dart';
import 'package:twake_chat/domain/personalization/display_preferences.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_search_style.dart';

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
  seenStyle: SeenStyle.avatars,
  composerStyle: ComposerStyle.compact,
  bubbleAlign: BubbleAlign.left,
  searchStyle: ChatListSearchStyle.collapsing,
);
const _allOtherStored = {
  SettingKeys.chatListDensity: 'compact',
  SettingKeys.roomOrder: 'sections',
  SettingKeys.seenStyle: 'avatars',
  SettingKeys.composerStyle: 'compact',
  SettingKeys.bubbleAlign: 'left',
  SettingKeys.searchStyle: 'collapsing',
};

Future<Map<String, Object?>> _device() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)};
}

void main() {
  _choicesTests();
  _seenStepsTests();
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
        SettingKeys.bubbleAlign: 'left',
        SettingKeys.seenStyle: 'names',
      });

      expect(
        await repository.load(),
        const DisplayPreferencesState(
          bubbleAlign: BubbleAlign.left,
          seenStyle: SeenStyle.names,
        ),
      );
    });

    test(
      'changes nothing on the device, the old web switch included',
      () async {
        // Web is retired: the old « own messages on the right » switch is not
        // read any more, the align step asks everyone.
        final stored = {
          ..._allOtherStored,
          SettingKeys.enableRightAndLeftMessageAlignmentOnWeb: false,
        };
        final repository = _repository(stored);

        await repository.load();

        expect(await _device(), stored);
      },
    );

    test('the search style is stored under « chat.twake.search_style »', () {
      expect(SettingKeys.searchStyle, 'chat.twake.search_style');
    });

    test('a device of the release before (no search style stored): the '
        'bottom bar, the other choices kept', () async {
      final stored = {..._allOtherStored}..remove(SettingKeys.searchStyle);

      expect(
        await _repository(stored).load(),
        _allOther.copyWith(searchStyle: ChatListSearchStyle.bottomBar),
      );
    });

    test('the search style « collapsing » alone is read', () async {
      expect(
        (await _repository({
          SettingKeys.searchStyle: 'collapsing',
        }).load()).searchStyle,
        ChatListSearchStyle.collapsing,
      );
    });

    test('the old web switch off does not move the bubbles', () async {
      final repository = _repository({
        SettingKeys.enableRightAndLeftMessageAlignmentOnWeb: false,
      });

      expect((await repository.load()).bubbleAlign, BubbleAlign.ownRight);
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

void _seenStepsTests() {
  group('the seen steps', () {
    test('are stored under « chat.twake.personalized »', () {
      expect(SettingKeys.personalizedSteps, 'chat.twake.personalized');
    });

    test('nothing stored: none seen', () async {
      expect(await _repository({}).loadSeenSteps(), isEmpty);
    });

    test('reads the stored JSON list of ids, ids of a newer version '
        'included', () async {
      final repository = _repository({
        SettingKeys.personalizedSteps: '["density","wallpaper"]',
      });

      expect(await repository.loadSeenSteps(), {'density', 'wallpaper'});
    });

    for (final unreadable in ['oops', '{"density":true}', '', '[1,2]']) {
      test(
        'a stored value that cannot be read ($unreadable): none seen',
        () async {
          final repository = _repository({
            SettingKeys.personalizedSteps: unreadable,
          });

          expect(await repository.loadSeenSteps(), isEmpty);
        },
      );
    }

    test('are saved as a JSON list of ids', () async {
      final repository = _repository({});

      await repository.saveSeenSteps({'seen-style', 'align'});

      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString(SettingKeys.personalizedSteps)!),
        unorderedEquals(['seen-style', 'align']),
      );
    });

    test('what is saved is what the next load reads', () async {
      final repository = _repository({});

      await repository.saveSeenSteps({'density', 'wallpaper'});

      expect(await repository.loadSeenSteps(), {'density', 'wallpaper'});
    });

    test('saving them leaves the display choices alone', () async {
      final repository = _repository(_allOtherStored);

      await repository.saveSeenSteps({'density'});

      expect(await repository.load(), _allOther);
    });
  });
}
