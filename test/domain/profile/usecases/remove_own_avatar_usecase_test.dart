import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/usecases/remove_own_avatar_usecase.dart';

import '../fake_profile_repository.dart';

void main() {
  final current = AccountProfile(
    userId: '@alice:server',
    displayName: 'Alice',
    avatarUrl: Uri.parse('mxc://server/old'),
  );

  test('execute_withAvatar_clearsItAndAnnouncesTheProfile', () async {
    // Arrange
    final repository = FakeProfileRepository();

    // Act
    final saved = await RemoveOwnAvatarUseCase(repository).execute(current);

    // Assert
    expect(repository.writes, [null]);
    expect(
      saved,
      const AccountProfile(userId: '@alice:server', displayName: 'Alice'),
    );
    expect(repository.announced, [saved]);
  });

  test('execute_whenTheServerFails_throwsRemoveOwnAvatarException', () async {
    // Arrange
    final error = Exception('network');
    final repository = FakeProfileRepository()..writeError = error;

    // Act
    final result = RemoveOwnAvatarUseCase(repository).execute(current);

    // Assert
    await expectLater(
      result,
      throwsA(
        isA<RemoveOwnAvatarException>().having((e) => e.cause, 'cause', error),
      ),
    );
  });
}
