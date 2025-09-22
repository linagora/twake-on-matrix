import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/repository/user_info/user_info_repository.dart';
import 'package:fluffychat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_user_info_interactor_test.mocks.dart';

@GenerateNiceMocks([MockSpec<UserInfoRepository>()])
void main() {
  group('get user info interactor ', () {
    test('should encode userId', () async {
      // arrange
      const userId = 'userId';
      final repository = MockUserInfoRepository();
      const interactor = GetUserInfoInteractor();
      getIt.registerFactory<UserInfoRepository>(() => repository);
      when(repository.getUserInfo(userId))
          .thenAnswer((_) => Future.value(const UserInfo()));

      // act
      await interactor.execute(userId).last;

      // assert
      verify(repository.getUserInfo(Uri.encodeComponent(userId))).called(1);
    });
  });
}
