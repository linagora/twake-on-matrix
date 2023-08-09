import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/base_di.dart';
import 'package:get_it/get_it.dart';

class HiveDI extends BaseDI {
  @override
  void setUp(GetIt get) {
    get.registerLazySingletonAsync<HiveCollectionToMDatabase>(
      () => HiveCollectionToMDatabase.databaseBuilder(),
    );
  }
}
