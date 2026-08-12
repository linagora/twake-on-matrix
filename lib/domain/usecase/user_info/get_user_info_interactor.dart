import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';

class GetUserInfoInteractor {
  const GetUserInfoInteractor();

  Stream<Either<Failure, Success>> execute({String? userId}) async* {
    try {
      yield Right(GettingUserInfo());
      if (userId == null) {
        yield const Left(NoUserIdFailure());
        return;
      }

      final result = await getIt.get<UserInfoRepository>().getUserInfo(userId);
      yield Right(GetUserInfoSuccess(result));
    } catch (e) {
      yield Left(GetUserInfoFailure(exception: e));
    }
  }
}
