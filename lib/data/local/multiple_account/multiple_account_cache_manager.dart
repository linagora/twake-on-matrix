import 'package:twake_chat/data/account/sources/persisted_active_account_source.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/famedlysdk_store.dart';

class MultipleAccountCacheManager {
  final pres = getIt.get<Store>();

  static const String persistActiveAccountKey =
      PersistedActiveAccountSource.key;

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
