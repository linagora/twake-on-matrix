import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twake_chat/utils/client_manager.dart';
import 'package:twake_chat/utils/open_sqflite_db.dart';

import '../fake_keychain.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);

  final String dir;

  @override
  Future<String?> getApplicationSupportPath() async => dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late PathProviderPlatform originalPathProvider;
  late FakeKeychain keychain;

  setUp(() {
    (keychain = FakeKeychain()).install();
    root = Directory.systemTemp.createTempSync('client_manager_delete_storage');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(root.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    root.deleteSync(recursive: true);
  });

  test('a database key the keychain fails to delete leaves a warning in the '
      'logs', () async {
    final database = await MatrixSdkDatabase.init(
      'acc',
      database: await openSqfliteDb(name: 'acc'),
      sqfliteFactory: databaseFactoryFfi,
    );
    keychain.failDeletes = true;
    Logs().outputEvents.clear();

    await ClientManager.deleteClientStorage(database);

    expect(
      Logs().outputEvents.where((e) => e.level == Level.warning),
      isNotEmpty,
    );
  });
}
