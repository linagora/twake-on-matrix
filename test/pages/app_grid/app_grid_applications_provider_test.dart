import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/data/app_grid/repositories/app_grid_repository.provider.dart';
import 'package:twake_chat/domain/app_grid/exceptions/app_grid_exception.dart';
import 'package:twake_chat/domain/app_grid/repositories/app_grid_repository.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';
import 'package:twake_chat/pages/app_grid/app_grid_applications.provider.dart';

class _FakeAppGridRepository implements AppGridRepository {
  _FakeAppGridRepository({this.applications, this.error});

  final LinagoraApplications? applications;
  final Object? error;
  final requestedPaths = <String>[];

  @override
  Future<LinagoraApplications> getConfiguration(String path) async {
    requestedPaths.add(path);
    if (error != null) throw error!;
    return applications!;
  }
}

void main() {
  final applications = LinagoraApplications([
    LinagoraApp('Twake Mail', 'ic_twake_mail.svg', Uri.parse('https://mail')),
  ]);

  ProviderContainer createContainer(AppGridRepository repository) =>
      ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [appGridRepositoryProvider.overrideWithValue(repository)],
      );

  test(
    'appGridApplications_whenTheConfigurationLoads_exposesItsApplications',
    () async {
      final repository = _FakeAppGridRepository(applications: applications);
      final container = createContainer(repository);

      final result = await container.read(appGridApplicationsProvider.future);

      expect(result, applications);
      expect(repository.requestedPaths, [AppConfig.appGridConfigurationPath]);
    },
  );

  test(
    'appGridApplications_whenTheConfigurationFails_exposesATypedErrorWithoutRetrying',
    () async {
      final repository = _FakeAppGridRepository(error: Exception('missing'));
      final container = createContainer(repository);
      final subscription = container.listen(
        appGridApplicationsProvider,
        (_, _) {},
      );

      await expectLater(
        container.read(appGridApplicationsProvider.future),
        throwsA(isA<AppGridConfigurationUnavailableException>()),
      );
      expect(subscription.read().value, isNull);
      expect(repository.requestedPaths, hasLength(1));
    },
  );
}
