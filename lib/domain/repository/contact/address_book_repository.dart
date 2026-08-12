import 'package:twake_chat/data/model/addressbook/address_book_request.dart';
import 'package:twake_chat/data/model/addressbook/address_book_response.dart';

abstract class AddressBookRepository {
  Future<AddressbookResponse> updateAddressBook({
    required AddressBookRequest request,
  });

  Future<AddressbookResponse> getAddressBook();
}
