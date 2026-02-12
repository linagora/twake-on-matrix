import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_visibility_state.dart';
import 'package:fluffychat/domain/repository/user_info/user_info_repository.dart';

class GetUserInfoVisibilityInteractor {
  const GetUserInfoVisibilityInteractor();

  Stream<Either<Failure, Success>> execute({required String userId}) async* {
    try {
      yield Right(GettingUserInfoVisibility());

      final result = await getIt.get<UserInfoRepository>().getUserVisibility(
        userId,
      );
      yield Right(GetUserInfoVisibilitySuccess(result));
    } catch (e) {
      yield Left(GetUserInfoVisibilityFailure(exception: e));
    }
  }
}
