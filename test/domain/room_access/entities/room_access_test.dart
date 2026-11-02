import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';

void main() {
  const invite = RoomAccess(
    joinRule: JoinRuleChoice.invite,
    isListed: false,
    isEncrypted: false,
    canChange: true,
  );

  test('offeredJoinRules_unencryptedRoom_offersAllRules', () {
    // Act
    final rules = invite.offeredJoinRules;

    // Assert
    expect(rules, JoinRuleChoice.values);
    expect(invite.offersListing, isTrue);
  });

  test('offeredJoinRules_encryptedRoom_leavesOutPublicAndTheListing', () {
    // Arrange
    final access = invite.copyWith(isEncrypted: true);

    // Act
    final rules = access.offeredJoinRules;

    // Assert
    expect(rules, [JoinRuleChoice.invite, JoinRuleChoice.knock]);
    expect(access.offersListing, isFalse);
  });

  test('offeredJoinRules_encryptedPublicListedRoom_keepsThemToTakeThemOut', () {
    // Arrange
    final access = invite.copyWith(
      joinRule: JoinRuleChoice.public,
      isListed: true,
      isEncrypted: true,
    );

    // Act
    final rules = access.offeredJoinRules;

    // Assert
    expect(rules, JoinRuleChoice.values);
    expect(access.offersListing, isTrue);
  });

  test('offeredJoinRules_withPublicPage_offersOnlyPublic', () {
    // Arrange
    final access = invite.copyWith(
      joinRule: JoinRuleChoice.public,
      isListed: true,
      hasPublicPage: true,
    );

    // Act
    final rules = access.offeredJoinRules;

    // Assert
    expect(rules, [JoinRuleChoice.public]);
  });
}
