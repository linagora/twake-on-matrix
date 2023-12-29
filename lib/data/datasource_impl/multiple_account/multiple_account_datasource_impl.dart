import 'package:fluffychat/data/datasource/multiple_account/multiple_account_datasource.dart';
import 'package:fluffychat/data/local/multiple_account/multiple_account_cache_manager.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';

class MultipleAccountDatasourceImpl implements MultipleAccountDatasource {
  final MultipleAccountCacheManager _multipleAccountCacheManager =
      getIt.get<MultipleAccountCacheManager>();

  @override
  Future<String?> getPersistActiveAccount() {
    return _multipleAccountCacheManager.getPersistActiveAccount();
  }

  @override
  Future<void> storePersistActiveAccount(String userId) {
    return _multipleAccountCacheManager.storePersistActiveAccount(userId);
  }

  @override
  Future<void> deletePersistActiveAccount() {
    return _multipleAccountCacheManager.deletePersistActiveAccount();
  }
}
