import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_draft.dart';

void main() {
  const saved = RoomAccess(
    joinRule: JoinRuleChoice.invite,
    isListed: false,
    isEncrypted: false,
    canChange: true,
    hasPublicPage: false,
  );

  test('choose_public_turnsTheListingOn', () {
    // Act
    final draft = const RoomAccessDraft().choose(JoinRuleChoice.public);

    // Assert
    expect(draft.joinRuleOn(saved), JoinRuleChoice.public);
    expect(draft.isListedOn(saved), isTrue);
    expect(draft.isDirtyOn(saved), isTrue);
  });

  test('choose_knockAfterPublic_keepsTheListing', () {
    // Act
    final draft = const RoomAccessDraft()
        .choose(JoinRuleChoice.public)
        .choose(JoinRuleChoice.knock);

    // Assert
    expect(draft.isListedOn(saved), isTrue);
  });

  test('isDirtyOn_backToTheSavedValues_isFalse', () {
    // Arrange
    final draft = const RoomAccessDraft()
        .choose(JoinRuleChoice.public)
        .choose(JoinRuleChoice.invite)
        .copyWith(isListed: false);

    // Act
    final isDirty = draft.isDirtyOn(saved);

    // Assert
    expect(isDirty, isFalse);
    expect(draft.changedJoinRuleOn(saved), isNull);
    expect(draft.changedIsListedOn(saved), isNull);
  });

  test('isDirtyOn_noSavedAccess_isFalse', () {
    // Act
    final isDirty = const RoomAccessDraft(
      joinRule: JoinRuleChoice.public,
    ).isDirtyOn(null);

    // Assert
    expect(isDirty, isFalse);
  });

  test('isDirtyOn_roomEncryptedAfterChoosingPublic_dropsTheChoices', () {
    // Arrange
    final draft = const RoomAccessDraft().choose(JoinRuleChoice.public);
    final encrypted = saved.copyWith(isEncrypted: true);

    // Act
    final isDirty = draft.isDirtyOn(encrypted);

    // Assert
    expect(isDirty, isFalse);
    expect(draft.joinRuleOn(encrypted), JoinRuleChoice.invite);
    expect(draft.isListedOn(encrypted), isFalse);
  });

  test('isDirtyOn_encryptedListedRoomUnlisted_keepsTheChoice', () {
    // Arrange
    const draft = RoomAccessDraft(isListed: false);
    final encryptedListed = saved.copyWith(isEncrypted: true, isListed: true);

    // Act
    final changed = draft.changedIsListedOn(encryptedListed);

    // Assert
    expect(changed, isFalse);
  });

  test('blocksEncryptionOn_publicChosenNotSaved_isTrue', () {
    // Act
    final blocks = const RoomAccessDraft(
      joinRule: JoinRuleChoice.public,
    ).blocksEncryptionOn(saved);

    // Assert
    expect(blocks, isTrue);
  });

  test('blocksEncryptionOn_savedPublicWithInviteChosen_isTrue', () {
    // Act
    final blocks = const RoomAccessDraft(
      joinRule: JoinRuleChoice.invite,
    ).blocksEncryptionOn(saved.copyWith(joinRule: JoinRuleChoice.public));

    // Assert
    expect(blocks, isTrue);
  });

  test('blocksEncryptionOn_inviteRoom_isFalse', () {
    // Act
    final blocks = const RoomAccessDraft().blocksEncryptionOn(saved);

    // Assert
    expect(blocks, isFalse);
  });

  test('isListedOn_withPublicPage_keepsTheSavedListing', () {
    // Arrange
    final withPage = saved.copyWith(
      joinRule: JoinRuleChoice.public,
      isListed: true,
      hasPublicPage: true,
    );
    final draft = const RoomAccessDraft(
      isListed: false,
    ).choose(JoinRuleChoice.invite);

    // Act
    final isDirty = draft.isDirtyOn(withPage);

    // Assert
    expect(isDirty, isFalse);
    expect(draft.isListedOn(withPage), isTrue);
  });

  test('joinRuleOn_roomRestrictedMeanwhile_dropsTheChoice', () {
    // Arrange
    final draft = const RoomAccessDraft().choose(JoinRuleChoice.public);
    final restricted = saved.copyWith(joinRule: null);

    // Act
    final changed = draft.changedJoinRuleOn(restricted);

    // Assert
    expect(changed, isNull);
    expect(draft.changedIsListedOn(restricted), isTrue);
  });
}
