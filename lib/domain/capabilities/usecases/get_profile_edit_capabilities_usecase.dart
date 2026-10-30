import 'package:twake_chat/domain/capabilities/exceptions/capabilities_exception.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';

class GetProfileEditCapabilitiesUseCase {
  const GetProfileEditCapabilitiesUseCase(this._repository);

  final ServerCapabilitiesRepository _repository;

  Future<ProfileEditCapabilities> execute() async {
    try {
      return await _repository.getProfileEditCapabilities();
    } catch (e, s) {
      Error.throwWithStackTrace(GetProfileEditCapabilitiesException(e), s);
    }
  }
}
