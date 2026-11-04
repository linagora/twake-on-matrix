import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility_request.dart';
import 'package:twake_chat/domain/repository/user_info/user_info_repository.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';

class UpdateUserInfoVisibilityUseCase {
  const UpdateUserInfoVisibilityUseCase(this._repository);

  final UserInfoRepository _repository;

  Future<UserInfoVisibility> execute({
    required String userId,
    required UserInfoVisibilityRequest request,
  }) async {
    try {
      return await _repository.updateUserInfoVisibility(userId, request);
    } catch (e, s) {
      Error.throwWithStackTrace(UpdateUserInfoVisibilityException(e), s);
    }
  }
}
