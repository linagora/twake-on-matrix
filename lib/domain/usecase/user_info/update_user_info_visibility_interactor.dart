import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/user_info/update_user_info_visibility_state.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

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
