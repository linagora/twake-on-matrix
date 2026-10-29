import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';

class GetUserInfoUseCase {
  const GetUserInfoUseCase(this._repository);

  final UserInfoRepository _repository;

  Future<UserInfo> execute(String userId) async {
    try {
      return await _repository.getUserInfo(userId);
    } catch (e, s) {
      Error.throwWithStackTrace(GetUserInfoException(e), s);
    }
  }
}
