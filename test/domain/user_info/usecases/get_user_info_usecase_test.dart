import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_usecase.dart';

import '../fake_user_info_repository.dart';

void main() {
  test('execute_withKnownUser_returnsTheUserInfo', () async {
    // Arrange
    final useCase = GetUserInfoUseCase(FakeUserInfoRepository());

    // Act
    final result = await useCase.execute('@me:server');

    // Assert
    expect(result.uid, '@me:server');
  });

  test('execute_whenTheRepositoryThrows_throwsGetUserInfoException', () {
    // Arrange
    final error = Exception('network');
    final useCase = GetUserInfoUseCase(FakeUserInfoRepository(error: error));

    // Act
    final result = useCase.execute('@me:server');

    // Assert
    expect(
      result,
      throwsA(
        isA<GetUserInfoException>().having((e) => e.cause, 'cause', error),
      ),
    );
  });
}
