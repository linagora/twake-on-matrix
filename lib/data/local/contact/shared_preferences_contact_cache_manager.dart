import 'package:collection/collection.dart';
import 'package:fluffychat/data/local/contact/enum/chunk_federation_contact_error_enum.dart';
import 'package:fluffychat/data/local/contact/enum/contacts_hive_error_enum.dart';
import 'package:fluffychat/data/local/contact/enum/contacts_vault_error_enum.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/famedlysdk_store.dart';

class SharedPreferencesContactCacheManager {
  static SharedPreferencesContactCacheManager instance =
      SharedPreferencesContactCacheManager._internal();

  static const String keyContactsHiveError = 'contactsHiveError';

  static const String keyContactsVaultError = 'contactsVaultError';

  static const String keyTimeLastSyncedVault = 'timeLastSyncedVault';

  static const String keyChunkFederationLookUpError =
      'chunkFederationLookUpError';

  static const Duration timeToSyncVault = Duration(hours: 4);

  factory SharedPreferencesContactCacheManager() {
    return instance;
  }

  SharedPreferencesContactCacheManager._internal();

  final Store pres = getIt.get<Store>();

  Future<void> storeContactsHiveError(ContactsHiveErrorEnum error) async {
    await pres.setItem(keyContactsHiveError, error.message);
  }

  Future<ContactsHiveErrorEnum?> getContactsHiveError() async {
    final error = await pres.getItem(keyContactsHiveError);
    return ContactsHiveErrorEnum.values.firstWhereOrNull(
      (element) => element.message == error,
    );
  }

  Future<void> deleteContactsHiveError() async {
    await pres.deleteItem(keyContactsHiveError);
  }

  Future<void> storeContactsVaultError(ContactsVaultErrorEnum error) async {
    await pres.setItem(keyContactsVaultError, error.message);
  }

  Future<ContactsVaultErrorEnum?> getContactsVaultError() async {
    final error = await pres.getItem(keyContactsVaultError);
    return ContactsVaultErrorEnum.values.firstWhereOrNull(
      (element) => element.message == error,
    );
  }

  Future<void> deteleContactsVaultError() async {
    await pres.deleteItem(keyContactsVaultError);
  }

  Future<void> storeTimeLastSyncedVault(DateTime time) async {
    await pres.setItem(keyTimeLastSyncedVault, time.toIso8601String());
  }

  Future<bool> timeAvailableForSyncVault() async {
    final time = await pres.getItem(keyTimeLastSyncedVault);
    return time == null
        ? true
        : DateTime.now().difference(DateTime.parse(time)).inHours >
              timeToSyncVault.inHours;
  }

  Future<void> storeChunkFederationLookUpError(
    ChunkLookUpContactErrorEnum chunkFederationContactErrorEnum,
  ) async {
    await pres.setItem(
      keyChunkFederationLookUpError,
      chunkFederationContactErrorEnum.message,
    );
  }

  Future<ChunkLookUpContactErrorEnum?> getChunkFederationLookUpError() async {
    final error = await pres.getItem(keyChunkFederationLookUpError);
    return ChunkLookUpContactErrorEnum.values.firstWhereOrNull(
      (element) => element.message == error,
    );
  }

  Future<void> deleteChunkFederationLookUpError() async {
    await pres.deleteItem(keyChunkFederationLookUpError);
  }
}
