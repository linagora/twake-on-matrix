abstract class MultipleAccountRepository {
  Future<void> storePersistActiveAccount(String userId);

  Future<String?> getPersistActiveAccount();

  Future<void> deletePersistActiveAccount();
}
