import 'package:fluffychat/presentation/enum/settings/settings_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingEnum', () {
    group('enum values', () {
      test('should not contain dataAndStorage value', () {
        final names = SettingEnum.values.map((e) => e.name).toList();
        expect(names, isNot(contains('dataAndStorage')));
      });

      test('should contain expected values after dataAndStorage removal', () {
        final names = SettingEnum.values.map((e) => e.name).toSet();
        expect(
          names,
          containsAll([
            'profile',
            'chatSettings',
            'privacyAndSecurity',
            'notificationAndSounds',
            'chatFolders',
            'appLanguage',
            'devices',
            'help',
            'about',
            'deleteAccount',
            'logout',
          ]),
        );
      });

      test('should have exactly 11 values after dataAndStorage removal', () {
        expect(SettingEnum.values.length, 11);
      });
    });

    group('isHideTrailingIcon', () {
      test('should hide trailing icon for logout', () {
        expect(SettingEnum.logout.isHideTrailingIcon, isTrue);
      });

      test('should hide trailing icon for deleteAccount', () {
        expect(SettingEnum.deleteAccount.isHideTrailingIcon, isTrue);
      });

      test('should show trailing icon for profile', () {
        expect(SettingEnum.profile.isHideTrailingIcon, isFalse);
      });

      test('should show trailing icon for chatSettings', () {
        expect(SettingEnum.chatSettings.isHideTrailingIcon, isFalse);
      });

      test('should show trailing icon for privacyAndSecurity', () {
        expect(SettingEnum.privacyAndSecurity.isHideTrailingIcon, isFalse);
      });

      test('should show trailing icon for help', () {
        expect(SettingEnum.help.isHideTrailingIcon, isFalse);
      });

      test('should show trailing icon for about', () {
        expect(SettingEnum.about.isHideTrailingIcon, isFalse);
      });

      // Boundary: only logout and deleteAccount should hide the icon.
      test('only logout and deleteAccount hide the trailing icon', () {
        const shouldHide = {SettingEnum.logout, SettingEnum.deleteAccount};
        for (final value in SettingEnum.values) {
          if (shouldHide.contains(value)) {
            expect(
              value.isHideTrailingIcon,
              isTrue,
              reason: '${value.name} should hide trailing icon',
            );
          } else {
            expect(
              value.isHideTrailingIcon,
              isFalse,
              reason: '${value.name} should not hide trailing icon',
            );
          }
        }
      });
    });
  });
}