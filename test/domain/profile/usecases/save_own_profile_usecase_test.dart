import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/entities/avatar_upload.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/usecases/save_own_profile_usecase.dart';

import '../fake_profile_repository.dart';

void main() {
  final current = AccountProfile(
    userId: '@alice:server',
    displayName: 'Alice',
    avatarUrl: Uri.parse('mxc://server/old'),
  );
  final avatar = AvatarUpload.fromBytes(bytes: Uint8List(1), name: 'a.png');

  test('execute_withNameOnly_savesTheNameAndKeepsTheAvatar', () async {
    // Arrange
    final repository = FakeProfileRepository();

    // Act
    final saved = await SaveOwnProfileUseCase(
      repository,
    ).execute(current, displayName: 'Alicia');

    // Assert
    expect(repository.writes, ['Alicia']);
    expect(saved, current.copyWith(displayName: 'Alicia'));
    expect(repository.announced, [saved]);
  });

  test('execute_withAvatarAndName_uploadsThenSetsAvatarThenName', () async {
    // Arrange
    final repository = FakeProfileRepository();

    // Act
    final saved = await SaveOwnProfileUseCase(
      repository,
    ).execute(current, displayName: 'Alicia', avatar: avatar);

    // Assert
    expect(repository.writes, [avatar, repository.uploadedUri, 'Alicia']);
    expect(
      saved,
      current.copyWith(
        displayName: 'Alicia',
        avatarUrl: repository.uploadedUri,
      ),
    );
  });

  test('execute_whenAWriteFails_throwsSaveOwnProfileException', () async {
    // Arrange
    final error = Exception('M_FORBIDDEN');
    final repository = FakeProfileRepository()..writeError = error;

    // Act
    final result = SaveOwnProfileUseCase(
      repository,
    ).execute(current, displayName: 'Alicia');

    // Assert
    await expectLater(
      result,
      throwsA(
        isA<SaveOwnProfileException>().having((e) => e.cause, 'cause', error),
      ),
    );
    expect(repository.announced, isEmpty);
  });
}
