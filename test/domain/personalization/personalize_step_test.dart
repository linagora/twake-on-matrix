import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/personalization/personalize_step.dart';

const _allIds = [
  'density',
  'order',
  'search-bar',
  'seen-style',
  'composer',
  'align',
];

/// The ids the release before the search bar step wrote once its flow was
/// closed: every device that went through it holds them.
const _idsBeforeSearchBar = [
  'density',
  'order',
  'seen-style',
  'composer',
  'align',
];

/// The steps a wide screen asks: no search bar, the search of a wide screen
/// stays in the header (D37).
const _wideSteps = [
  PersonalizeStep.density,
  PersonalizeStep.order,
  PersonalizeStep.seenStyle,
  PersonalizeStep.composer,
  PersonalizeStep.align,
];

/// The steps a phone asks: no composer, it keeps today's input bar.
const _phoneSteps = [
  PersonalizeStep.density,
  PersonalizeStep.order,
  PersonalizeStep.searchBar,
  PersonalizeStep.seenStyle,
  PersonalizeStep.align,
];

void main() {
  group('the steps of the personalization flow', () {
    test('are asked in this order, under ids that never change', () {
      expect(PersonalizeStep.values.map((step) => step.id), _allIds);
    });

    test('the step of the seen style is stored as « seen-style »', () {
      expect(PersonalizeStep.seenStyle.id, 'seen-style');
    });

    test('the step of the search bar is stored as « search-bar »', () {
      expect(PersonalizeStep.searchBar.id, 'search-bar');
    });

    test('the search bar is a new id: the release before never stored it', () {
      expect(
        _idsBeforeSearchBar,
        isNot(contains(PersonalizeStep.searchBar.id)),
      );
    });

    test('« theme » is not a step yet: it is kept for the dark mode', () {
      expect(
        PersonalizeStep.values.map((step) => step.id),
        isNot(contains('theme')),
      );
    });

    test('the composer alone is asked on wide screens only', () {
      final phone = pendingSteps(const [], isWide: false);

      expect(PersonalizeStep.values.where((step) => !phone.contains(step)), [
        PersonalizeStep.composer,
      ]);
    });

    test('the search bar alone is asked on phones only', () {
      final wide = pendingSteps(const [], isWide: true);

      expect(PersonalizeStep.values.where((step) => !wide.contains(step)), [
        PersonalizeStep.searchBar,
      ]);
    });
  });

  group('the steps still to ask on a wide screen', () {
    test('nothing seen: all five, in order, no search bar', () {
      expect(pendingSteps(const [], isWide: true), _wideSteps);
    });

    test('everything seen: none', () {
      expect(pendingSteps(_allIds, isWide: true), isEmpty);
    });

    test('everything seen, in another order: none', () {
      expect(pendingSteps(_allIds.reversed.toList(), isWide: true), isEmpty);
    });

    test('the five steps of the release before seen: none, though the search '
        'bar is not seen', () {
      expect(pendingSteps(_idsBeforeSearchBar, isWide: true), isEmpty);
    });

    test('the first two seen: the three others, in order', () {
      expect(pendingSteps(const ['density', 'order'], isWide: true), [
        PersonalizeStep.seenStyle,
        PersonalizeStep.composer,
        PersonalizeStep.align,
      ]);
    });

    test('a step added by a later release is asked alone', () {
      expect(
        pendingSteps(
          _allIds.where((id) => id != 'seen-style').toList(),
          isWide: true,
        ),
        [PersonalizeStep.seenStyle],
      );
    });

    test('a first step not seen is still asked, the seen ones are not', () {
      expect(pendingSteps(_allIds.skip(1).toList(), isWide: true), [
        PersonalizeStep.density,
      ]);
    });

    test('ids this version does not know hide nothing', () {
      expect(
        pendingSteps(const ['wallpaper', 'clock'], isWide: true),
        _wideSteps,
      );
    });

    test('« theme » stored by a later version hides nothing', () {
      expect(pendingSteps(const ['theme'], isWide: true), _wideSteps);
    });

    test('« seenStyle » (the Dart name) is not the stored id', () {
      expect(
        pendingSteps(const ['seenStyle'], isWide: true),
        contains(PersonalizeStep.seenStyle),
      );
    });
  });

  group('the steps still to ask on a phone', () {
    test('nothing seen: the five steps without the composer, the search bar '
        'after the order, in order', () {
      expect(pendingSteps(const [], isWide: false), _phoneSteps);
    });

    test('the five seen: none, though the composer is not seen', () {
      expect(
        pendingSteps(const [
          'density',
          'order',
          'search-bar',
          'seen-style',
          'align',
        ], isWide: false),
        isEmpty,
      );
    });

    test('the five steps of the release before seen: the search bar alone', () {
      expect(pendingSteps(_idsBeforeSearchBar, isWide: false), [
        PersonalizeStep.searchBar,
      ]);
    });

    test('the first two seen: search bar, seen style and align', () {
      expect(pendingSteps(const ['density', 'order'], isWide: false), [
        PersonalizeStep.searchBar,
        PersonalizeStep.seenStyle,
        PersonalizeStep.align,
      ]);
    });

    test('« searchBar » (the Dart name) is not the stored id', () {
      expect(
        pendingSteps(const ['searchBar'], isWide: false),
        contains(PersonalizeStep.searchBar),
      );
    });

    test('ids this version does not know hide nothing', () {
      expect(
        pendingSteps(const ['wallpaper', 'theme'], isWide: false),
        _phoneSteps,
      );
    });
  });

  group('a phone, then a tablet', () {
    test('what the phone showed is marked seen, the tablet asks the composer '
        'alone', () {
      final seenOnPhone = mergeSeenSteps(
        const [],
        pendingSteps(const [], isWide: false),
      );

      expect(seenOnPhone, isNot(contains('composer')));
      expect(pendingSteps(seenOnPhone, isWide: true), [
        PersonalizeStep.composer,
      ]);
    });

    test('once the tablet asked it, the phone asks nothing either', () {
      final seen = mergeSeenSteps(
        mergeSeenSteps(const [], pendingSteps(const [], isWide: false)),
        const [PersonalizeStep.composer],
      );

      expect(pendingSteps(seen, isWide: true), isEmpty);
      expect(pendingSteps(seen, isWide: false), isEmpty);
    });
  });

  group('a tablet, then a phone', () {
    test('what the tablet showed is marked seen, the phone asks the search '
        'bar alone', () {
      final seenOnTablet = mergeSeenSteps(
        const [],
        pendingSteps(const [], isWide: true),
      );

      expect(seenOnTablet, isNot(contains('search-bar')));
      expect(pendingSteps(seenOnTablet, isWide: false), [
        PersonalizeStep.searchBar,
      ]);
    });

    test('once the phone asked it, the tablet asks nothing either', () {
      final seen = mergeSeenSteps(
        mergeSeenSteps(const [], pendingSteps(const [], isWide: true)),
        const [PersonalizeStep.searchBar],
      );

      expect(pendingSteps(seen, isWide: true), isEmpty);
      expect(pendingSteps(seen, isWide: false), isEmpty);
    });
  });

  group('marking steps seen', () {
    test('adds the shown steps to what was seen', () {
      expect(
        mergeSeenSteps(const ['density'], const [PersonalizeStep.seenStyle]),
        unorderedEquals(['density', 'seen-style']),
      );
    });

    test('from nothing seen: the ids of the shown steps', () {
      expect(
        mergeSeenSteps(const [], PersonalizeStep.values),
        unorderedEquals(_allIds),
      );
    });

    test('keeps the ids written by a newer version', () {
      expect(
        mergeSeenSteps(
          const ['wallpaper', 'density'],
          const [PersonalizeStep.align],
        ),
        unorderedEquals(['wallpaper', 'density', 'align']),
      );
    });

    test('a step seen twice is kept once', () {
      final merged = mergeSeenSteps(_allIds, PersonalizeStep.values);

      expect(merged, unorderedEquals(_allIds));
      expect(merged.length, _allIds.length);
    });

    test('nothing shown: what was seen stays', () {
      expect(
        mergeSeenSteps(const ['wallpaper', 'align'], const []),
        unorderedEquals(['wallpaper', 'align']),
      );
    });

    test('what it returns leaves no step to ask among the shown ones', () {
      final seen = mergeSeenSteps(const ['wallpaper'], PersonalizeStep.values);

      expect(pendingSteps(seen, isWide: true), isEmpty);
      expect(pendingSteps(seen, isWide: false), isEmpty);
    });
  });

  group('reading the stored seen steps', () {
    test('a JSON list of ids: these ids', () {
      expect(
        parseSeenSteps('["density","seen-style"]'),
        unorderedEquals(['density', 'seen-style']),
      );
    });

    test('ids this version does not know are read too', () {
      expect(
        parseSeenSteps('["wallpaper","density"]'),
        unorderedEquals(['wallpaper', 'density']),
      );
    });

    test('nothing stored: nothing seen', () {
      expect(parseSeenSteps(null), isEmpty);
    });

    test('an empty string: nothing seen', () {
      expect(parseSeenSteps(''), isEmpty);
    });

    test('not JSON: nothing seen', () {
      expect(parseSeenSteps('density,align'), isEmpty);
    });

    test('JSON that is not a list: nothing seen', () {
      expect(parseSeenSteps('{"seen":["density"]}'), isEmpty);
      expect(parseSeenSteps('"density"'), isEmpty);
      expect(parseSeenSteps('1'), isEmpty);
      expect(parseSeenSteps('null'), isEmpty);
    });

    test('items that are not strings are dropped, the ids are kept', () {
      expect(
        parseSeenSteps('["density", 3, null, {"id":"align"}, ["align"]]'),
        ['density'],
      );
    });

    test('a list with no string at all: nothing seen', () {
      expect(parseSeenSteps('[1, true, null]'), isEmpty);
    });

    test('what was written by marking steps seen is read back', () {
      // The stored form is a JSON list (SettingKeys.personalizedSteps).
      expect(
        pendingSteps(
          parseSeenSteps(
            '["density","order","search-bar","seen-style","composer",'
            '"align"]',
          ),
          isWide: false,
        ),
        isEmpty,
      );
      expect(
        pendingSteps(parseSeenSteps('garbage'), isWide: false),
        _phoneSteps,
      );
    });
  });
}
