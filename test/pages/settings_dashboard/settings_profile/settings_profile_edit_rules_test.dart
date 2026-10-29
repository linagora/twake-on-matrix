import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_edit_rules.dart';

void main() {
  test('editedDisplayName trims and ignores unchanged names', () {
    const cases = <(String, String?)>[
      ('  Bob  ', 'Bob'),
      ('   ', null),
      (' Alice ', null),
    ];

    for (final (text, expected) in cases) {
      expect(
        SettingsProfileEditRules.editedDisplayName(
          text: text,
          currentName: 'Alice',
        ),
        expected,
        reason: 'text: "$text"',
      );
    }
  });

  test('hasChanges follows the edited name and the pending avatar', () {
    const cases = <(String, bool, bool)>[
      ('Bob', false, true),
      ('Alice', true, true),
      (' Alice ', false, false),
    ];

    for (final (text, hasPendingAvatar, expected) in cases) {
      expect(
        SettingsProfileEditRules.hasChanges(
          text: text,
          currentName: 'Alice',
          hasPendingAvatar: hasPendingAvatar,
        ),
        expected,
        reason: 'text: "$text", pending avatar: $hasPendingAvatar',
      );
    }
  });

  test('shouldOverwriteName keeps names typed or edited by the user', () {
    const cases = <(String, String, bool, bool)>[
      ('Alice', 'Alice', false, true),
      ('Alice', 'Bob', false, false),
      ('Bob', 'Bob', true, false),
    ];

    for (final (before, after, hadUnsavedEdit, expected) in cases) {
      expect(
        SettingsProfileEditRules.shouldOverwriteName(
          textBeforeRead: before,
          textAfterRead: after,
          hadUnsavedEditBeforeRead: hadUnsavedEdit,
        ),
        expected,
        reason: 'before: "$before", after: "$after", edited: $hadUnsavedEdit',
      );
    }
  });
}
