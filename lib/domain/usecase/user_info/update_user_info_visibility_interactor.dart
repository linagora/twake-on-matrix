import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/user_info/update_user_info_visibility_state.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:fluffychat/domain/repository/user_info/user_info_repository.dart';

class UpdateUserInfoVisibilityInteractor {
  const UpdateUserInfoVisibilityInteractor();

  Stream<Either<Failure, Success>> execute({
    required String userId,
    required UserInfoVisibilityRequest body,
  }) async* {
    try {
      yield Right(UpdatingUserInfoVisibility());

      final result = await getIt
          .get<UserInfoRepository>()
          .updateUserInfoVisibility(userId, body);
      yield Right(UpdateUserInfoVisibilitySuccess(result));
    } catch (e) {
      yield Left(UpdateUserInfoVisibilityFailure(exception: e));
    }
  }
}
