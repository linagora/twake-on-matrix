import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/domain/user_info/usecases/update_user_info_visibility_usecase.dart';

import '../fake_user_info_repository.dart';

void main() {
  final request = UserInfoVisibilityRequest(
    visibility: 'private',
    visibleFields: const [VisibleEnum.phone, VisibleEnum.email],
  );

  test('sends the request and returns the stored visibility', () async {
    final repository = FakeUserInfoRepository();

    final result = await UpdateUserInfoVisibilityUseCase(
      repository,
    ).execute(userId: '@me:server', request: request);

    expect(repository.updateCalls, [('@me:server', request)]);
    expect(result.visibility, 'private');
    expect(result.visibleFields, [VisibleEnum.phone, VisibleEnum.email]);
  });

  test('wraps a repository error in UpdateUserInfoVisibilityException', () {
    final error = Exception('network');
    final repository = FakeUserInfoRepository(error: error);

    expect(
      UpdateUserInfoVisibilityUseCase(
        repository,
      ).execute(userId: '@me:server', request: request),
      throwsA(
        isA<UpdateUserInfoVisibilityException>().having(
          (e) => e.cause,
          'cause',
          error,
        ),
      ),
    );
  });
}
