import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/app_grid_config/app_config_loader.dart';
import 'package:twake_chat/config/app_grid_config/app_config_parser.dart';
import 'package:twake_chat/config/app_grid_config/app_grid_errors.dart';
import 'package:twake_chat/data/app_grid/repositories/app_grid_repository_impl.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_app.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';

class _FakeAppConfigLoader implements AppConfigLoader {
  _FakeAppConfigLoader({this.json, this.error});

  final String? json;
  final Object? error;
  final requestedPaths = <String>[];

  @override
  Future<T> load<T>(String fileName, AppConfigParser parser) async {
    requestedPaths.add(fileName);
    if (error != null) throw error!;
    return await parser.parse(json!);
  }

  @override
  Future<T> loadData<T>(String fileName, AppConfigParser parser) =>
      throw UnimplementedError();
}

void main() {
  const path = 'configurations/app_dashboard.json';

  test(
    'getConfiguration_whenTheFileIsValid_parsesItWithTheAppGridParser',
    () async {
      final loader = _FakeAppConfigLoader(
        json:
            '{"apps":[{"appName":"Twake Mail","icon":"ic_twake_mail.svg",'
            '"appLink":"https://mail"}]}',
      );

      final result = await AppGridRepositoryImpl(loader).getConfiguration(path);

      expect(
        result,
        LinagoraApplications([
          LinagoraApp(
            'Twake Mail',
            'ic_twake_mail.svg',
            Uri.parse('https://mail'),
          ),
        ]),
      );
      expect(loader.requestedPaths, [path]);
    },
  );

  test('getConfiguration_whenTheLoaderFails_rethrowsItsError', () async {
    final loader = _FakeAppConfigLoader(error: ConfigurationNotFoundError());

    await expectLater(
      AppGridRepositoryImpl(loader).getConfiguration(path),
      throwsA(isA<ConfigurationNotFoundError>()),
    );
  });

  test('getConfiguration_whenTheJsonIsInvalid_rethrowsTheParserError', () {
    final loader = _FakeAppConfigLoader(json: '{"apps": 3}');

    expect(
      AppGridRepositoryImpl(loader).getConfiguration(path),
      throwsA(isA<TypeError>()),
    );
  });
}
