import 'dart:io';

import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:hive/hive.dart';

bool hiveInitialized = false;

Future<HiveCollectionToMDatabase> getHiveCollectionsDatabase() async {
  final testHivePath = Directory.current.path;
  if (!hiveInitialized) {
    Directory(testHivePath).createSync(recursive: true);
    Hive.init(testHivePath);
  }
  final db = HiveCollectionToMDatabase('unit_test', testHivePath);
  await db.open();
  return db;
}
