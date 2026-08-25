import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/contact/try_get_synced_phone_book_contact_state.dart';
import 'package:twake_chat/domain/repository/contact/hive_contact_repository.dart';
import 'package:matrix/matrix.dart';

class TryGetSyncedPhoneBookContactInteractor {
  final SharedPreferencesContactCacheManager
  _sharedPreferencesContactCacheManager = getIt
      .get<SharedPreferencesContactCacheManager>();

  final HiveContactRepository _hiveContactRepository = getIt
      .get<HiveContactRepository>();

  Future<Either<Failure, Success>> execute({required String userId}) async {
    try {
      final hiveContacts = await _hiveContactRepository
          .getThirdPartyContactByUserId(userId);
      final errorHive = await _sharedPreferencesContactCacheManager
          .getContactsHiveError();

      final errorVault = await _sharedPreferencesContactCacheManager
          .getContactsVaultError();

      final chunkLookUpError = await _sharedPreferencesContactCacheManager
          .getChunkFederationLookUpError();

      final timeAvailableForSyncVault =
          await _sharedPreferencesContactCacheManager
              .timeAvailableForSyncVault();

      final noError =
          errorHive == null && errorVault == null && chunkLookUpError == null;

      if (hiveContacts.isNotEmpty) {
        if (noError) {
          return Right(
            GetSyncedPhoneBookContactSuccessState(
              contacts: hiveContacts,
              timeAvailableForSyncVault: timeAvailableForSyncVault,
            ),
          );
        } else if (errorHive != null) {
          return Left(HasErrorFromHiveState(exception: errorHive));
        } else if (errorVault != null) {
          return Left(HasErrorFromVaultState(exception: errorVault));
        } else if (chunkLookUpError != null) {
          return Left(HasErrorFromChunkState(exception: chunkLookUpError));
        }
        return Right(
          GetSyncedPhoneBookContactSuccessState(
            contacts: hiveContacts,
            timeAvailableForSyncVault: timeAvailableForSyncVault,
          ),
        );
      } else {
        return const Left(GetSyncedPhoneBookContactIsEmpty());
      }
    } catch (e) {
      Logs().e('TryGetSyncedPhoneBookContact::getThirdPartyContactByUserId', e);
      return Left(GetSyncedPhoneBookContactFailure(exception: e));
    }
  }
}
