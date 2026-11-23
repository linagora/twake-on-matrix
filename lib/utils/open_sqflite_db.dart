import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database?> openSqfliteDb({String? name}) async {
  if (kIsWeb) return null;
  final databaseFactory = databaseFactoryFfi;
  final Directory baseDir = PlatformInfos.isMobile
      ? await getApplicationDocumentsDirectory()
      : await getApplicationSupportDirectory();
  final String dbPath = join(
    baseDir.path,
    "databases",
    "${name ?? AppConfig.applicationName}.db",
  );
  await Directory(dirname(dbPath)).create(recursive: true);
  final db = await databaseFactory.openDatabase(dbPath);
  return db;
}

Future<void> deleteSqfliteDb(String path) async {
  final databaseFactory = databaseFactoryFfi;
  await databaseFactory.deleteDatabase(path);
}
