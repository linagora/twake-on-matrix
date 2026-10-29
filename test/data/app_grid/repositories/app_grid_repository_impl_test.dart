import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.dart';
import 'package:twake_chat/config/app_grid_config/app_grid_errors.dart';
import 'package:twake_chat/data/app_grid/repositories/app_grid_repository_impl.dart';
import 'package:twake_chat/domain/model/app_grid/app_grid_configuration_parser.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

import 'app_grid_repository_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AppConfigLoader>()])
void main() {
  const path = 'configurations/app_dashboard.json';

  test(
    'getConfiguration_whenTheLoaderSucceeds_loadsThePathWithTheAppGridParser',
    () async {
      // Arrange
      final applications = LinagoraApplications([
        LinagoraApp(
          'Twake Mail',
          'ic_twake_mail.svg',
          Uri.parse('https://mail'),
        ),
      ]);
      final loader = MockAppConfigLoader();
      when(
        loader.load<LinagoraApplications>(path, any),
      ).thenAnswer((_) async => applications);

      // Act
      final result = await AppGridRepositoryImpl(loader).getConfiguration(path);

      // Assert
      expect(result, applications);
      verify(
        loader.load<LinagoraApplications>(
          path,
          argThat(isA<AppGridConfigurationParser>()),
        ),
      ).called(1);
    },
  );

  test('getConfiguration_whenTheLoaderFails_rethrowsItsError', () async {
    // Arrange
    final loader = MockAppConfigLoader();
    when(
      loader.load<LinagoraApplications>(path, any),
    ).thenThrow(ConfigurationNotFoundError());

    // Act
    final result = AppGridRepositoryImpl(loader).getConfiguration(path);

    // Assert
    await expectLater(result, throwsA(isA<ConfigurationNotFoundError>()));
  });
}
