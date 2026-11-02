import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration_usecase.provider.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

part 'app_grid_dashboard_controller.g.dart';

/// The apps listed in the app grid.
@riverpod
class AppGridDashboardController extends _$AppGridDashboardController {
  @override
  Future<LinagoraApplications> build() async {
    try {
      // TODO: [transitional] The path is still read from the static AppConfig.
      return await ref
          .read(getAppGridConfigurationUseCaseProvider)
          .execute(AppConfig.appGridConfigurationPath);
    } catch (e, s) {
      Logs().e('AppGridDashboardController::build()', e, s);
      rethrow;
    }
  }
}
