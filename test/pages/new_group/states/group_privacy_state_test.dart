import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';

void main() {
  group('GroupPrivacyState', () {
    test('default_isPrivateAndUnencryptedWithBothOptionsAvailable', () {
      // Act
      const privacy = GroupPrivacyState();

      // Assert
      expect(privacy.canBePublic, isTrue);
      expect(privacy.canBeEncrypted, isTrue);
    });

    test('withEncryption_whenPrivate_encryptsAndBlocksPublic', () {
      // Act
      final privacy = const GroupPrivacyState().withEncryption(
        isEncrypted: true,
      );

      // Assert
      expect(privacy, const GroupPrivacyState(isEncrypted: true));
      expect(privacy.canBePublic, isFalse);
    });

    test('withPublic_whenPrivate_makesPublicAndBlocksEncryption', () {
      // Act
      final privacy = const GroupPrivacyState().withPublic(isPublic: true);

      // Assert
      expect(privacy, const GroupPrivacyState(isPublic: true));
      expect(privacy.canBeEncrypted, isFalse);
    });

    test('withPublic_whenEncrypted_isRefused', () {
      // Arrange
      const encrypted = GroupPrivacyState(isEncrypted: true);

      // Act
      final privacy = encrypted.withPublic(isPublic: true);

      // Assert
      expect(privacy, encrypted);
    });

    test('withEncryption_whenPublic_isRefused', () {
      // Arrange
      const public = GroupPrivacyState(isPublic: true);

      // Act
      final privacy = public.withEncryption(isEncrypted: true);

      // Assert
      expect(privacy, public);
    });

    test('withEncryption_whenTurnedOff_unblocksPublic', () {
      // Act
      final privacy = const GroupPrivacyState(
        isEncrypted: true,
      ).withEncryption(isEncrypted: false);

      // Assert
      expect(privacy, const GroupPrivacyState());
      expect(privacy.canBePublic, isTrue);
    });

    test('withPublic_whenTurnedOff_unblocksEncryption', () {
      // Arrange
      const public = GroupPrivacyState(isPublic: true);

      // Act
      final privacy = public.withPublic(isPublic: false);

      // Assert
      expect(privacy, const GroupPrivacyState());
      expect(privacy.canBeEncrypted, isTrue);
    });

    test('constructor_whenPublicAndEncrypted_throws', () {
      // Act
      GroupPrivacyState build() =>
          GroupPrivacyState(isPublic: true, isEncrypted: _true());

      // Assert
      expect(build, throwsAssertionError);
    });
  });
}

bool _true() => true;
