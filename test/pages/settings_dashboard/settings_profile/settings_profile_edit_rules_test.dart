import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_edit_rules.dart';

void main() {
  const userId = '@alice:example.org';

  group('SettingsProfileEditRules.editedDisplayName', () {
    test('returns the trimmed name when it differs', () {
      expect(
        SettingsProfileEditRules.editedDisplayName(
          text: '  Bob  ',
          currentName: 'Alice',
        ),
        'Bob',
      );
    });

    test('ignores a whitespace-only name', () {
      expect(
        SettingsProfileEditRules.editedDisplayName(
          text: '   ',
          currentName: 'Alice',
        ),
        isNull,
      );
    });

    test('ignores the current name surrounded by spaces', () {
      expect(
        SettingsProfileEditRules.editedDisplayName(
          text: ' Alice ',
          currentName: 'Alice',
        ),
        isNull,
      );
    });
  });

  group('SettingsProfileEditRules.hasChanges', () {
    test('keeps Done for an edited name once the picked avatar is removed', () {
      expect(
        SettingsProfileEditRules.hasChanges(
          text: 'Bob',
          currentName: 'Alice',
          hasPendingAvatar: false,
        ),
        isTrue,
      );
    });

    test('shows Done for a pending avatar with an unchanged name', () {
      expect(
        SettingsProfileEditRules.hasChanges(
          text: 'Alice',
          currentName: 'Alice',
          hasPendingAvatar: true,
        ),
        isTrue,
      );
    });

    test('hides Done when nothing changed', () {
      expect(
        SettingsProfileEditRules.hasChanges(
          text: ' Alice ',
          currentName: 'Alice',
          hasPendingAvatar: false,
        ),
        isFalse,
      );
    });
  });

  group('SettingsProfileEditRules.reloadedProfile', () {
    test('keeps the saved profile when the fresh read fails', () {
      expect(
        SettingsProfileEditRules.reloadedProfile(
          fetched: null,
          userId: userId,
          fresh: true,
        ),
        isNull,
      );
    });

    test('falls back to an id-only profile on the first read', () {
      final profile = SettingsProfileEditRules.reloadedProfile(
        fetched: null,
        userId: userId,
        fresh: false,
      );

      expect(profile?.userId, userId);
      expect(profile?.displayName, isNull);
      expect(profile?.avatarUrl, isNull);
    });

    test('uses the fetched profile', () {
      final profile = SettingsProfileEditRules.reloadedProfile(
        fetched: const MatrixUserProfile(
          matrixId: userId,
          displayName: 'Bob',
          avatarUrl: 'mxc://example.org/avatar',
        ),
        userId: userId,
        fresh: true,
      );

      expect(profile?.displayName, 'Bob');
      expect(profile?.avatarUrl, Uri.parse('mxc://example.org/avatar'));
    });
  });

  group('SettingsProfileEditRules.shouldOverwriteName', () {
    test('overwrites an untouched field', () {
      expect(
        SettingsProfileEditRules.shouldOverwriteName(
          textBeforeRead: 'Alice',
          textAfterRead: 'Alice',
          hadUnsavedEditBeforeRead: false,
        ),
        isTrue,
      );
    });

    test('keeps a name typed during the read', () {
      expect(
        SettingsProfileEditRules.shouldOverwriteName(
          textBeforeRead: 'Alice',
          textAfterRead: 'Bob',
          hadUnsavedEditBeforeRead: false,
        ),
        isFalse,
      );
    });

    test('keeps an unsaved edit across an avatar removal', () {
      expect(
        SettingsProfileEditRules.shouldOverwriteName(
          textBeforeRead: 'Bob',
          textAfterRead: 'Bob',
          hadUnsavedEditBeforeRead: true,
        ),
        isFalse,
      );
    });
  });
}
