import 'package:twake_chat/domain/capabilities/exceptions/capabilities_exception.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';

class FetchProfileEditCapabilitiesUseCase {
  const FetchProfileEditCapabilitiesUseCase(this._repository);

  final ServerCapabilitiesRepository _repository;

  Future<ProfileEditCapabilities> execute() async {
    try {
      return await _repository.fetchProfileEditCapabilities();
    } on CapabilitiesException {
      rethrow;
    } on Exception catch (e, s) {
      Error.throwWithStackTrace(FetchProfileEditCapabilitiesException(e), s);
    }
  }
}
