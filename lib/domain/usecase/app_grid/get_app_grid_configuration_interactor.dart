import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_grid_config/app_config_loader.dart';
import 'package:fluffychat/domain/app_state/app_grid/get_app_grid_configuration_state.dart';
import 'package:fluffychat/domain/model/app_grid/app_grid_configuration_parser.dart';
import 'package:fluffychat/domain/model/app_grid/linagora_applications.dart';
import 'package:matrix/matrix.dart';

class GetAppGridConfigurationInteractor {
  final AppConfigLoader _appConfigLoader;

  GetAppGridConfigurationInteractor(this._appConfigLoader);

  Stream<Either<Failure, Success>> execute({
    required String appGridConfigurationPath,
  }) async* {
    try {
      yield Right(LoadingAppGridConfiguration());

      final linagoraApps = await _appConfigLoader.load<LinagoraApplications>(
        appGridConfigurationPath,
        AppGridConfigurationParser(),
      );

      yield Right(GetAppGridConfigurationSuccess(linagoraApps));
    } catch (e) {
      Logs().e('GetAppGridConfigurationInteractor::execute(): $e');
      yield Left(GetAppGridConfigurationFailure(exception: e));
    }
  }
}
