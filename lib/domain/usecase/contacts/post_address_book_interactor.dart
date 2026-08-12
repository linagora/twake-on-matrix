import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/data/local/contact/enum/contacts_vault_error_enum.dart';
import 'package:twake_chat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:twake_chat/data/model/addressbook/address_book.dart';
import 'package:twake_chat/data/model/addressbook/address_book_request.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/contact/post_address_book_state.dart';
import 'package:twake_chat/domain/repository/contact/address_book_repository.dart';
import 'package:matrix/matrix.dart';

class PostAddressBookInteractor {
  final AddressBookRepository _addressBookRepository = getIt
      .get<AddressBookRepository>();

  final SharedPreferencesContactCacheManager
  _sharedPreferencesContactCacheManager = getIt
      .get<SharedPreferencesContactCacheManager>();

  Stream<Either<Failure, Success>> execute({
    required List<AddressBook> addressBooks,
  }) async* {
    try {
      yield const Right(PostAddressBookLoading());
      if (addressBooks.isEmpty) {
        yield const Left(PostAddressBookEmptyState());
        return;
      }
      final response = await _addressBookRepository.updateAddressBook(
        request: AddressBookRequest(addressBooks: addressBooks),
      );

      if (response.addressBooks == null) {
        await _sharedPreferencesContactCacheManager.storeContactsVaultError(
          ContactsVaultErrorEnum.responseIsNull,
        );
        yield const Left(PostAddressBookResponseIsNullState());
        return;
      }

      await _sharedPreferencesContactCacheManager.storeTimeLastSyncedVault(
        DateTime.now(),
      );

      await _sharedPreferencesContactCacheManager.deteleContactsVaultError();

      yield Right(
        PostAddressBookSuccessState(
          updatedAddressBooks: response.addressBooks!,
        ),
      );
    } catch (e) {
      Logs().e('PostAddressBookInteractor::execute', e);
      _sharedPreferencesContactCacheManager.storeContactsVaultError(
        ContactsVaultErrorEnum.uploadError,
      );
      yield Left(PostAddressBookFailureState(exception: e));
    }
  }
}
