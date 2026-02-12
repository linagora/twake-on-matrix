import 'dart:io';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database?> openSqfliteDb({String? name}) async {
  if (!PlatformInfos.isMobile) return null;
  final databaseFactory = databaseFactoryFfi;
  final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  final String dbPath = join(
    appDocumentsDir.path,
    "databases",
    "${name ?? AppConfig.applicationName}.db",
  );
  final db = await databaseFactory.openDatabase(dbPath);
  return db;
}

Future<void> deleteSqfliteDb(String path) async {
  final databaseFactory = databaseFactoryFfi;
  await databaseFactory.deleteDatabase(path);
}
