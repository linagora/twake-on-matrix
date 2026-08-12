import 'package:twake_chat/data/datasource/contact/address_book_datasource.dart';
import 'package:twake_chat/data/model/addressbook/address_book_request.dart';
import 'package:twake_chat/data/model/addressbook/address_book_response.dart';
import 'package:twake_chat/data/network/contact/address_book_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';

class AddressBookDatasourceImpl extends AddressBookDatasource {
  final AddressBookApi _addressBookApi = getIt.get<AddressBookApi>();

  @override
  Future<AddressbookResponse> updateAddressBook({
    required AddressBookRequest request,
  }) {
    return _addressBookApi.updateAddressBook(request: request);
  }

  @override
  Future<AddressbookResponse> getAddressBook() {
    return _addressBookApi.getAddressBook();
  }
}
