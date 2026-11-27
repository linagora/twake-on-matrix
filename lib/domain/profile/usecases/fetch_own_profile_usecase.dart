import 'package:twake_chat/domain/profile/entities/account_profile.dart';
import 'package:twake_chat/domain/profile/exceptions/profile_exception.dart';
import 'package:twake_chat/domain/profile/repositories/profile_repository.dart';

final class FetchOwnProfileUseCase {
  const FetchOwnProfileUseCase(this._repository);

  final ProfileRepository _repository;

  /// Null when the lookup finds nothing; with [fresh], also when the server
  /// does not answer.
  Future<AccountProfile?> execute(String userId, {bool fresh = false}) async {
    try {
      return await _repository.fetchProfile(userId, fresh: fresh);
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(FetchOwnProfileException(e), s);
    }
  }
}
