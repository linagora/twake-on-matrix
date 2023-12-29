abstract class MultipleAccountDatasource {
  Future<void> storePersistActiveAccount(String userId);

  Future<String?> getPersistActiveAccount();

  Future<void> deletePersistActiveAccount();
}
