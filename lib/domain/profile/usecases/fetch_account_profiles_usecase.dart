import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/repositories/profile_repository.dart';

final class FetchAccountProfilesUseCase {
  const FetchAccountProfilesUseCase(this._repository);

  final ProfileRepository _repository;

  Future<List<AccountProfile>> execute() async {
    try {
      return await _repository.fetchAccountProfiles();
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(FetchAccountProfilesException(e), s);
    }
  }
}
