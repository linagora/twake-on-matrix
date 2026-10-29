import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/user_info_repository.provider.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/providers/user_info_provider.dart';

import '../domain/user_info/fake_user_info_repository.dart';

void main() {
  ProviderContainer createContainer(FakeUserInfoRepository repository) =>
      ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [userInfoRepositoryProvider.overrideWithValue(repository)],
      );

  test('loads the user info of the requested user', () async {
    final container = createContainer(FakeUserInfoRepository());

    final userInfo = await container.read(
      userInfoProvider('@bob:server').future,
    );

    expect(userInfo.uid, '@bob:server');
  });

  test('exposes a typed error when the fetch fails', () async {
    final container = createContainer(
      FakeUserInfoRepository(error: Exception('network')),
    );
    container.listen(userInfoProvider('@bob:server'), (_, _) {});

    await expectLater(
      container.read(userInfoProvider('@bob:server').future),
      throwsA(isA<GetUserInfoException>()),
    );
    expect(container.read(userInfoProvider('@bob:server')).hasError, isTrue);
  });
}
