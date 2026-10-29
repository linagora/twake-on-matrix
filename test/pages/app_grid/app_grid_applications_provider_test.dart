import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/app_grid/repositories/app_grid_repository.provider.dart';
import 'package:twake_chat/domain/app_grid/exceptions/app_grid_exception.dart';
import 'package:twake_chat/domain/app_grid/repositories/app_grid_repository.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';
import 'package:twake_chat/pages/app_grid/app_grid_applications.provider.dart';

import 'app_grid_applications_provider_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AppGridRepository>()])
void main() {
  const path = AppConfig.appGridConfigurationPath;

  ProviderContainer createContainer(AppGridRepository repository) =>
      ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [appGridRepositoryProvider.overrideWithValue(repository)],
      );

  test(
    'appGridApplications_whenTheConfigurationLoads_exposesItsApplications',
    () async {
      // Arrange
      final applications = LinagoraApplications([
        LinagoraApp(
          'Twake Mail',
          'ic_twake_mail.svg',
          Uri.parse('https://mail'),
        ),
      ]);
      final repository = MockAppGridRepository();
      when(
        repository.getConfiguration(path),
      ).thenAnswer((_) async => applications);
      final container = createContainer(repository);

      // Act
      final result = await container.read(appGridApplicationsProvider.future);

      // Assert
      expect(result, applications);
    },
  );

  test(
    'appGridApplications_whenTheConfigurationFails_exposesATypedErrorWithoutRetrying',
    () async {
      // Arrange
      final repository = MockAppGridRepository();
      when(repository.getConfiguration(path)).thenThrow(Exception('missing'));
      final container = createContainer(repository);
      final subscription = container.listen(
        appGridApplicationsProvider,
        (_, _) {},
      );

      // Act
      final result = container.read(appGridApplicationsProvider.future);

      // Assert
      await expectLater(
        result,
        throwsA(isA<AppGridConfigurationUnavailableException>()),
      );
      expect(subscription.read().value, isNull);
      verify(repository.getConfiguration(path)).called(1);
    },
  );
}
