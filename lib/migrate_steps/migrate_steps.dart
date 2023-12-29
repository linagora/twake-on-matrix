abstract class MigrateSteps {
  const MigrateSteps();

  Future<void> onMigrate(int currentVersion, int newVersion) async {}
}
