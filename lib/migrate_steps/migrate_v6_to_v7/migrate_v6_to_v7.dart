import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/data/hive/hive_collection_tom_database.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/migrate_steps/migrate_steps.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';
import 'package:matrix/matrix.dart';

class MigrateV6ToV7 extends MigrateSteps {
  @override
  Future<void> onMigrate(int currentVersion, int newVersion) async {
    Logs().d('MigrateV6ToV7::onMigrate() Starting migration from v6 to v7');
    await migrateHiveCollectionToMDatabase();
    await PersistedActiveAccountSource(getIt.get<Store>()).delete();
    Logs().d(
      'MigrateV6ToV7::onMigrate(): Delete persist active account success',
    );
  }

  Future<void> migrateHiveCollectionToMDatabase() async {
    try {
      final hiveCollectionToMDatabase = await getIt
          .getAsync<HiveCollectionToMDatabase>();
      await hiveCollectionToMDatabase.clear();
      Logs().d('MigrateV6ToV7::onMigrate(): Delete ToM database success');
    } catch (e) {
      Logs().e('MigrateV6ToV7::onMigrate(): Delete ToM database failed', e);
    }
  }
}
