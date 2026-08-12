import 'package:twake_chat/data/datasource/contact/address_book_datasource.dart';
import 'package:twake_chat/data/model/addressbook/address_book_request.dart';
import 'package:twake_chat/data/model/addressbook/address_book_response.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/repository/contact/address_book_repository.dart';

class AddressBookRepositoryImpl extends AddressBookRepository {
  final AddressBookDatasource _addressBookDataSource = getIt
      .get<AddressBookDatasource>();

  @override
  Future<AddressbookResponse> updateAddressBook({
    required AddressBookRequest request,
  }) {
    return _addressBookDataSource.updateAddressBook(request: request);
  }

  @override
  Future<AddressbookResponse> getAddressBook() {
    return _addressBookDataSource.getAddressBook();
  }
}
