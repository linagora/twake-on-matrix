import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:fluffychat/domain/repository/contact/address_book_repository.dart';

class GetTomContactsInteractor {
  final AddressBookRepository addressBookRepository = getIt
      .get<AddressBookRepository>();

  GetTomContactsInteractor();

  Stream<Either<Failure, Success>> execute() async* {
    try {
      yield const Right(ContactsLoading());
      final response = await addressBookRepository.getAddressBook();

      final contacts = response.addressBooks?.toContacts() ?? [];

      if (contacts.isEmpty) {
        yield const Left(GetContactsIsEmpty());
      } else {
        yield Right(GetContactsSuccess(contacts: contacts));
      }
    } catch (e) {
      yield Left(GetContactsFailure(keyword: '', exception: e));
    }
  }
}
