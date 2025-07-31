import 'package:fluffychat/data/model/addressbook/address_book_request.dart';
import 'package:fluffychat/data/model/addressbook/address_book_response.dart';

abstract class AddressBookRepository {
  Future<AddressbookResponse> updateAddressBook({
    required AddressBookRequest request,
  });
}
