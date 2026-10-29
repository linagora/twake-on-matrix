import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.dart';
import 'package:twake_chat/domain/app_grid/repositories/app_grid_repository.dart';
import 'package:twake_chat/domain/model/app_grid/app_grid_configuration_parser.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

class AppGridRepositoryImpl implements AppGridRepository {
  const AppGridRepositoryImpl(this._appConfigLoader);

  final AppConfigLoader _appConfigLoader;

  @override
  Future<LinagoraApplications> getConfiguration(String path) async {
    try {
      return await _appConfigLoader.load<LinagoraApplications>(
        path,
        AppGridConfigurationParser(),
      );
    } catch (e, s) {
      Logs().e('AppGridRepositoryImpl::getConfiguration()', e, s);
      rethrow;
    }
  }
}
