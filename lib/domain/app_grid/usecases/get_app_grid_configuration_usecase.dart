import 'package:twake_chat/config/app_grid_config/app_config_loader.dart';
import 'package:twake_chat/domain/model/app_grid/app_grid_configuration_parser.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

/// Loads the apps shown in the app grid from [execute]'s asset path.
///
/// Throws the errors of [AppConfigLoader.load]: `ConfigurationNotFoundError`,
/// `EmptyConfiguration`, or the parser's error.
class GetAppGridConfigurationUseCase {
  const GetAppGridConfigurationUseCase(this._appConfigLoader);

  final AppConfigLoader _appConfigLoader;

  Future<LinagoraApplications> execute(String appGridConfigurationPath) =>
      _appConfigLoader.load<LinagoraApplications>(
        appGridConfigurationPath,
        AppGridConfigurationParser(),
      );
}
