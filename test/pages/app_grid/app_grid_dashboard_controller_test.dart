import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/app_grid_config/app_grid_errors.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration_usecase.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration_usecase.provider.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';
import 'package:twake_chat/pages/app_grid/app_grid_dashboard_controller.dart';

import '../../domain/app_grid/usecases/get_app_grid_configuration_usecase_test.dart';

void main() {
  final apps = LinagoraApplications([
    LinagoraApp('Mail', 'ic_mail', Uri.parse('https://mail.test/')),
  ]);

  ProviderContainer createContainer(FakeAppConfigLoader loader) =>
      ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          getAppGridConfigurationUseCaseProvider.overrideWithValue(
            GetAppGridConfigurationUseCase(loader),
          ),
        ],
      );

  test('loads the configured apps', () async {
    final container = createContainer(FakeAppConfigLoader(result: apps));

    final result = await container.read(
      appGridDashboardControllerProvider.future,
    );

    expect(result, apps);
  });

  test('exposes the loading error', () async {
    final container = createContainer(
      FakeAppConfigLoader(error: EmptyConfiguration()),
    );
    final subscription = container.listen(
      appGridDashboardControllerProvider,
      (_, _) {},
    );

    await expectLater(
      container.read(appGridDashboardControllerProvider.future),
      throwsA(isA<EmptyConfiguration>()),
    );
    expect(subscription.read().hasError, isTrue);
  });
}
