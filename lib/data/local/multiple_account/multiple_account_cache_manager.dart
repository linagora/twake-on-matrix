import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/famedlysdk_store.dart';

class MultipleAccountCacheManager {
  final pres = getIt.get<Store>();

  static const String persistActiveAccountKey = 'persist_active_account_key';

  Future<void> storePersistActiveAccount(String userId) async {
    await pres.setItem(persistActiveAccountKey, userId);
  }

  Future<String?> getPersistActiveAccount() async {
    return await pres.getItem(persistActiveAccountKey);
  }

  Future<void> deletePersistActiveAccount() async {
    await pres.deleteItem(persistActiveAccountKey);
  }
}
