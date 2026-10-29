import 'package:twake_chat/domain/app_grid/exceptions/app_grid_exception.dart';
import 'package:twake_chat/domain/app_grid/repositories/app_grid_repository.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

class GetAppGridConfiguration {
  const GetAppGridConfiguration(this._repository);

  final AppGridRepository _repository;

  Future<LinagoraApplications> execute({required String path}) async {
    try {
      return await _repository.getConfiguration(path);
    } catch (e) {
      throw AppGridConfigurationUnavailableException(cause: e);
    }
  }
}
