import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/app_grid/get_app_grid_configuration_state.dart';
import 'package:fluffychat/domain/model/app_grid/linagora_applications.dart';
import 'package:fluffychat/domain/usecase/app_grid/get_app_grid_configuration_interactor.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class AppGridDashboard extends StatefulWidget {
  const AppGridDashboard({super.key});

  @override
  State<AppGridDashboard> createState() => AppGridDashboardController();
}

class AppGridDashboardController extends State<AppGridDashboard> {
  final _getAppGridConfigurationInteractor =
      getIt.get<GetAppGridConfigurationInteractor>();

  final isOpenAppGridDashboardNotifier = ValueNotifier<bool>(false);

  final linagoraApplications = ValueNotifier<LinagoraApplications?>(null);

  final hoverColorAppGrid = ValueNotifier<Color>(Colors.transparent);

  final hoverColorAppHelp = ValueNotifier<Color>(Colors.transparent);

  void _getAppGridConfiguration() {
    _getAppGridConfigurationInteractor
        .execute(
      appGridConfigurationPath: AppConfig.appGridConfigurationPath,
    )
        .listen((event) {
      event.fold(
        (failure) {
          if (failure is GetAppGridConfigurationFailure) {
            Logs().e(
              'AppGridDashboardController::_getAppGridConfiguration(): $failure',
            );
          }
        },
        (success) {
          if (success is GetAppGridConfigurationSuccess) {
            handleGetAppGridDashboardSuccess(success.linagoraApplications);
          }
        },
      );
    });
  }

  void handleGetAppGridDashboardSuccess(LinagoraApplications linagoraApps) {
    try {
      Logs().d(
        'AppGridDashboardController::handleGetAppGridDashboardSuccess(): $linagoraApps',
      );
      linagoraApplications.value = linagoraApps;
    } on FlutterError catch (e) {
      Logs().e(
        'AppGridDashboardController::handleShowAppDashboard(): $e',
      );
    }
  }

  void hideAppGridDashboard() {
    try {
      if (isOpenAppGridDashboardNotifier.value == false) return;
      isOpenAppGridDashboardNotifier.value = false;
    } on FlutterError catch (e) {
      Logs().e(
        'AppGridDashboardController::hideAppGridDashboard(): $e',
      );
    }
  }

  @override
  void initState() {
    _getAppGridConfiguration();
    super.initState();
  }

  @override
  void dispose() {
    isOpenAppGridDashboardNotifier.dispose();
    linagoraApplications.dispose();
    hoverColorAppGrid.dispose();
    hoverColorAppHelp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppGridDashboardView(
      controller: this,
    );
  }
}
