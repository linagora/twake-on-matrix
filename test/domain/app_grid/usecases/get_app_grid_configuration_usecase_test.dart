import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.provider.dart';
import 'package:twake_chat/config/app_grid_config/app_config_parser.dart';
import 'package:twake_chat/config/app_grid_config/app_grid_errors.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration_usecase.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration_usecase.provider.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

class FakeAppConfigLoader extends AppConfigLoader {
  FakeAppConfigLoader({this.result, this.error});

  final LinagoraApplications? result;
  final Object? error;
  final List<String> paths = [];

  @override
  Future<T> load<T>(String fileName, AppConfigParser parser) async {
    paths.add(fileName);
    if (error != null) throw error!;
    return result as T;
  }
}

void main() {
  const path = 'configurations/app_dashboard.json';
  final apps = LinagoraApplications([
    LinagoraApp('Mail', 'ic_mail', Uri.parse('https://mail.test/')),
  ]);

  group('GetAppGridConfigurationUseCase', () {
    test('returns the apps loaded from the path', () async {
      final loader = FakeAppConfigLoader(result: apps);

      final result = await GetAppGridConfigurationUseCase(loader).execute(path);

      expect(result, apps);
      expect(loader.paths, [path]);
    });

    test('lets the loader error bubble up', () async {
      final loader = FakeAppConfigLoader(error: ConfigurationNotFoundError());

      await expectLater(
        GetAppGridConfigurationUseCase(loader).execute(path),
        throwsA(isA<ConfigurationNotFoundError>()),
      );
    });
  });

  group('getAppGridConfigurationUseCaseProvider', () {
    test('uses the overridden loader', () async {
      final loader = FakeAppConfigLoader(result: apps);
      final container = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [appConfigLoaderProvider.overrideWithValue(loader)],
      );

      final result = await container
          .read(getAppGridConfigurationUseCaseProvider)
          .execute(path);

      expect(result, apps);
    });
  });
}
