import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/common_settings_information.dart';
import 'package:twake_chat/domain/model/extensions/common_settings/common_settings_extensions.dart';

void main() {
  group('CommonSettingsInformationExtension', () {
    test(
      'completedApplicationUrl returns null when applicationUrl is null',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: null,
        );
        expect(
          commonSettings.completedApplicationUrl('@testuser:matrix.org'),
          isNull,
        );
      },
    );

    test(
      'completedApplicationUrl returns null when applicationUrl is empty',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: '',
        );
        expect(
          commonSettings.completedApplicationUrl('@testuser:matrix.org'),
          isNull,
        );
      },
    );

    test(
      'completedApplicationUrl returns null when applicationUrl does not contain {username}',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: 'https://settings.twake.app/',
        );
        expect(
          commonSettings.completedApplicationUrl('@testuser:matrix.org'),
          isNull,
        );
      },
    );

    test(
      'completedApplicationUrl returns null when userId is invalid (no @)',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: 'https://{username}-settings.twake.app/',
        );
        expect(
          commonSettings.completedApplicationUrl('testuser:matrix.org'),
          isNull,
        );
      },
    );

    test(
      'completedApplicationUrl returns null when userId is invalid (no :)',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: 'https://{username}-settings.twake.app/',
        );
        expect(commonSettings.completedApplicationUrl('@testuser'), isNull);
      },
    );

    test('completedApplicationUrl returns null when userId has double @', () {
      const commonSettings = CommonSettingsInformation(
        enabled: true,
        applicationUrl: 'https://{username}-settings.twake.app/',
      );
      expect(
        commonSettings.completedApplicationUrl('@@testuser:matrix.org'),
        isNull,
      );
    });

    test(
      'completedApplicationUrl returns null when userId has @ at the end',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: 'https://{username}-settings.twake.app/',
        );
        expect(
          commonSettings.completedApplicationUrl('testuser@:matrix.org'),
          isNull,
        );
      },
    );

    test('completedApplicationUrl returns null when userId has double :', () {
      const commonSettings = CommonSettingsInformation(
        enabled: true,
        applicationUrl: 'https://{username}-settings.twake.app/',
      );
      expect(
        commonSettings.completedApplicationUrl('@testuser::matrix.org'),
        isNull,
      );
    });

    test(
      'completedApplicationUrl returns null when userId has no username part',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: 'https://{username}-settings.twake.app/',
        );
        expect(commonSettings.completedApplicationUrl('@:matrix.org'), isNull);
      },
    );

    test(
      'completedApplicationUrl returns null when userId has no homeserver part',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: 'https://{username}-settings.twake.app/',
        );
        expect(commonSettings.completedApplicationUrl('@testuser:'), isNull);
      },
    );

    test('completedApplicationUrl returns correct URL for valid userId', () {
      const commonSettings = CommonSettingsInformation(
        enabled: true,
        applicationUrl: 'https://{username}-settings.twake.app/',
      );
      expect(
        commonSettings.completedApplicationUrl('@testuser:matrix.org'),
        'https://testuser-settings.twake.app/',
      );
    });

    test('completedApplicationUrl handles different usernames', () {
      const commonSettings = CommonSettingsInformation(
        enabled: true,
        applicationUrl: 'https://{username}-settings.twake.app/',
      );
      expect(
        commonSettings.completedApplicationUrl('@anotheruser:matrix.org'),
        'https://anotheruser-settings.twake.app/',
      );
    });

    // New test cases
    test('completedApplicationUrl handles userIds with special characters', () {
      const commonSettings = CommonSettingsInformation(
        enabled: true,
        applicationUrl: 'https://{username}-settings.twake.app/',
      );
      expect(
        commonSettings.completedApplicationUrl(
          '@test.user_name-123:matrix.org',
        ),
        'https://test.user_name-123-settings.twake.app/',
      );
    });

    test(
      'completedApplicationUrl handles very long usernames and homeservers',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl: 'https://{username}-settings.twake.app/',
        );
        expect(
          commonSettings.completedApplicationUrl(
            '@verylongusernamewithalotofcharacters:verylonghomeserverwithalotofcharacters.com',
          ),
          'https://verylongusernamewithalotofcharacters-settings.twake.app/',
        );
      },
    );

    test('completedApplicationUrl handles homeservers with subdomains', () {
      const commonSettings = CommonSettingsInformation(
        enabled: true,
        applicationUrl: 'https://{username}-settings.twake.app/',
      );
      expect(
        commonSettings.completedApplicationUrl(
          '@testuser:sub.domain.matrix.org',
        ),
        'https://testuser-settings.twake.app/',
      );
    });

    test(
      'completedApplicationUrl handles multiple occurrences of {username} in applicationUrl',
      () {
        const commonSettings = CommonSettingsInformation(
          enabled: true,
          applicationUrl:
              'https://{username}-settings.twake.app/{username}/dashboard',
        );
        expect(
          commonSettings.completedApplicationUrl('@testuser:matrix.org'),
          'https://testuser-settings.twake.app/testuser/dashboard',
        );
      },
    );
  });
}
