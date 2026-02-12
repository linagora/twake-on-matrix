import 'package:fluffychat/data/hive/hive_collection_tom_database.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/repository/multiple_account/multiple_account_repository.dart';
import 'package:fluffychat/migrate_steps/migrate_steps.dart';
import 'package:matrix/matrix.dart';

class MigrateV6ToV7 extends MigrateSteps {
  @override
  Future<void> onMigrate(int currentVersion, int newVersion) async {
    Logs().d('MigrateV6ToV7::onMigrate() Starting migration from v6 to v7');
    await migrateHiveCollectionToMDatabase();
    final multipleAccountRepository = getIt.get<MultipleAccountRepository>();
    await multipleAccountRepository.deletePersistActiveAccount();
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
