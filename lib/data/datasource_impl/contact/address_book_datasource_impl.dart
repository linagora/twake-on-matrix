import 'package:fluffychat/data/datasource/contact/address_book_datasource.dart';
import 'package:fluffychat/data/model/addressbook/address_book_request.dart';
import 'package:fluffychat/data/model/addressbook/address_book_response.dart';
import 'package:fluffychat/data/network/contact/address_book_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';

class AddressBookDatasourceImpl extends AddressBookDatasource {
  final AddressBookApi _addressBookApi = getIt.get<AddressBookApi>();

  @override
  Future<AddressbookResponse> updateAddressBook({
    required AddressBookRequest request,
  }) {
    return _addressBookApi.updateAddressBook(request: request);
  }
}
