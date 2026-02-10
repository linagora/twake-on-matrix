import 'package:dartz/dartz.dart';
import 'package:fluffychat/data/local/contact/enum/contacts_vault_error_enum.dart';
import 'package:fluffychat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/data/model/addressbook/address_book_request.dart';
import 'package:fluffychat/data/model/addressbook/address_book_response.dart';
import 'package:fluffychat/domain/app_state/contact/post_address_book_state.dart';
import 'package:fluffychat/domain/repository/contact/address_book_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'post_address_book_interactor_test.mocks.dart';

@GenerateMocks([AddressBookRepository, SharedPreferencesContactCacheManager])
void main() {
  late MockAddressBookRepository addressBookRepository;
  late MockSharedPreferencesContactCacheManager
  sharedPreferencesContactCacheManager;
  late PostAddressBookInteractor postAddressBookInteractor;
  late GetIt getIt;

  setUp(() {
    addressBookRepository = MockAddressBookRepository();
    sharedPreferencesContactCacheManager =
        MockSharedPreferencesContactCacheManager();

    getIt = GetIt.instance;

    getIt.registerFactory<AddressBookRepository>(() => addressBookRepository);
    getIt.registerFactory<SharedPreferencesContactCacheManager>(
      () => sharedPreferencesContactCacheManager,
    );

    postAddressBookInteractor = PostAddressBookInteractor();
  });

  tearDown(() {
    getIt.reset();
  });

  group('execute', () {
    test('should emit empty state when contacts is empty', () {
      final List<AddressBook> addressBooks = [];

      expectLater(
        postAddressBookInteractor.execute(addressBooks: addressBooks),
        emitsInOrder([
          const Right(PostAddressBookLoading()),
          const Left(PostAddressBookEmptyState()),
        ]),
      );
    });

    test('should emit failure when post address book fails', () async {
      final List<AddressBook> addressBooks = [
        AddressBook(
          id: 'id_1',
          mxid: '@mxid_1.com',
          displayName: 'Alice',
          active: true,
        ),
      ];

      final exception = Exception('Post address book failed');

      when(
        addressBookRepository.updateAddressBook(
          request: AddressBookRequest(addressBooks: addressBooks),
        ),
      ).thenThrow(exception);

      final result = postAddressBookInteractor.execute(
        addressBooks: addressBooks,
      );

      await expectLater(
        result,
        emitsInOrder([
          const Right(PostAddressBookLoading()),
          Left(PostAddressBookFailureState(exception: exception)),
        ]),
      );

      verify(
        sharedPreferencesContactCacheManager.storeContactsVaultError(
          ContactsVaultErrorEnum.uploadError,
        ),
      ).called(1);
    });

    test('should emit failure when response is null', () async {
      final List<AddressBook> addressBooks = [
        AddressBook(
          id: 'id_1',
          mxid: '@mxid_1.com',
          displayName: 'Alice',
          active: true,
        ),
      ];

      when(
        addressBookRepository.updateAddressBook(
          request: AddressBookRequest(addressBooks: addressBooks),
        ),
      ).thenAnswer((_) async => AddressbookResponse());

      final result = postAddressBookInteractor.execute(
        addressBooks: addressBooks,
      );

      await expectLater(
        result,
        emitsInOrder([
          const Right(PostAddressBookLoading()),
          const Left(PostAddressBookResponseIsNullState()),
        ]),
      );

      verify(
        sharedPreferencesContactCacheManager.storeContactsVaultError(
          ContactsVaultErrorEnum.responseIsNull,
        ),
      ).called(1);
    });

    test('should emit success when post address book success', () async {
      final List<AddressBook> addressBooks = [
        AddressBook(
          id: 'id_1',
          addressbookId: 'addressbook_id_1',
          mxid: '@mxid_1.com',
          displayName: 'Alice',
          active: true,
        ),
      ];

      final response = AddressbookResponse(
        id: 'id_1',
        owner: 'owner',
        addressBooks: addressBooks,
      );

      when(
        addressBookRepository.updateAddressBook(
          request: AddressBookRequest(addressBooks: addressBooks),
        ),
      ).thenAnswer((_) async => response);

      final result = postAddressBookInteractor.execute(
        addressBooks: addressBooks,
      );

      await expectLater(
        result,
        emitsInOrder([
          const Right(PostAddressBookLoading()),
          Right(PostAddressBookSuccessState(updatedAddressBooks: addressBooks)),
        ]),
      );

      verify(
        sharedPreferencesContactCacheManager.storeTimeLastSyncedVault(any),
      ).called(1);

      verify(
        sharedPreferencesContactCacheManager.deteleContactsVaultError(),
      ).called(1);
    });
  });
}
