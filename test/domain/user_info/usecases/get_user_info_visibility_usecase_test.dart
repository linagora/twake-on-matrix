import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_visibility_usecase.dart';

import '../fake_user_info_repository.dart';

void main() {
  test('returns the visibility of the user', () async {
    final visibility = UserInfoVisibility(
      matrixId: '@me:server',
      visibility: 'public',
      visibleFields: const [VisibleEnum.email],
    );
    final repository = FakeUserInfoRepository(visibility: visibility);

    final result = await GetUserInfoVisibilityUseCase(
      repository,
    ).execute('@me:server');

    expect(result, visibility);
    expect(repository.getVisibilityCalls, ['@me:server']);
  });

  test('wraps a repository error in GetUserInfoVisibilityException', () {
    final error = Exception('network');
    final repository = FakeUserInfoRepository(error: error);

    expect(
      GetUserInfoVisibilityUseCase(repository).execute('@me:server'),
      throwsA(
        isA<GetUserInfoVisibilityException>().having(
          (e) => e.cause,
          'cause',
          error,
        ),
      ),
    );
  });
}
