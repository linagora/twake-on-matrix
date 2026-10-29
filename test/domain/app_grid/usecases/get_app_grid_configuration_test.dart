import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/app_grid/exceptions/app_grid_exception.dart';
import 'package:twake_chat/domain/app_grid/repositories/app_grid_repository.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

import 'get_app_grid_configuration_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AppGridRepository>()])
void main() {
  const path = 'configurations/app_dashboard.json';
  final applications = LinagoraApplications([
    LinagoraApp('Twake Mail', 'ic_twake_mail.svg', Uri.parse('https://mail')),
  ]);

  test('execute_whenTheConfigurationLoads_returnsItsApplications', () async {
    // Arrange
    final repository = MockAppGridRepository();
    when(
      repository.getConfiguration(path),
    ).thenAnswer((_) async => applications);

    // Act
    final result = await GetAppGridConfigurationUseCase(
      repository,
    ).execute(path: path);

    // Assert
    expect(result, applications);
    verify(repository.getConfiguration(path)).called(1);
  });

  test(
    'execute_whenTheConfigurationFails_throwsAppGridConfigurationUnavailableException',
    () async {
      // Arrange
      final cause = Exception('not found');
      final repository = MockAppGridRepository();
      when(repository.getConfiguration(path)).thenThrow(cause);

      // Act
      final result = GetAppGridConfigurationUseCase(
        repository,
      ).execute(path: path);

      // Assert
      await expectLater(
        result,
        throwsA(
          isA<AppGridConfigurationUnavailableException>().having(
            (e) => e.cause,
            'cause',
            cause,
          ),
        ),
      );
    },
  );
}
