import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_usecase.dart';

import '../fake_user_info_repository.dart';

void main() {
  test('returns the user info of the user', () async {
    final result = await GetUserInfoUseCase(
      FakeUserInfoRepository(),
    ).execute('@bob:server');

    expect(result.uid, '@bob:server');
  });

  test('wraps a repository error in GetUserInfoException', () {
    final error = Exception('network');

    expect(
      GetUserInfoUseCase(
        FakeUserInfoRepository(error: error),
      ).execute('@bob:server'),
      throwsA(
        isA<GetUserInfoException>().having((e) => e.cause, 'cause', error),
      ),
    );
  });
}
