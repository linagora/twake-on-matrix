import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/app_grid/exceptions/app_grid_exception.dart';
import 'package:twake_chat/domain/app_grid/repositories/app_grid_repository.dart';
import 'package:twake_chat/domain/app_grid/usecases/get_app_grid_configuration.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

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
  const path = 'configurations/app_dashboard.json';
  final applications = LinagoraApplications([
    LinagoraApp('Twake Mail', 'ic_twake_mail.svg', Uri.parse('https://mail')),
  ]);

  test('execute_whenTheConfigurationLoads_returnsItsApplications', () async {
    final repository = _FakeAppGridRepository(applications: applications);

    final result = await GetAppGridConfiguration(
      repository,
    ).execute(path: path);

    expect(result, applications);
    expect(repository.requestedPaths, [path]);
  });

  test(
    'execute_whenTheConfigurationFails_throwsAppGridConfigurationUnavailableException',
    () async {
      final cause = Exception('not found');
      final repository = _FakeAppGridRepository(error: cause);

      await expectLater(
        GetAppGridConfiguration(repository).execute(path: path),
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
