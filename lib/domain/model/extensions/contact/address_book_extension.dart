import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';

extension IterableAddressBookExtension on Iterable<AddressBook> {
  Iterable<AddressBook> searchAddressBooks(String keyword) {
    if (keyword.isEmpty) {
      return this;
    }
    final contactsMatched = where((contact) {
      final supportedFields = [
        contact.displayName,
        contact.mxid,
      ];
      final plainTextContains = supportedFields.any(
        (field) =>
            field?.toLowerCase().contains(keyword.toLowerCase()) ?? false,
      );
      return plainTextContains || contact.mxid?.contains(keyword) == true;
    });
    return contactsMatched;
  }
}

extension AddressBookListExtension on Set<AddressBook> {
  Set<AddressBook> combineDuplicateAddressBooks() {
    final Map<String, AddressBook> uniqueAddressBooks = {};

    for (final addressBook in this) {
      if (addressBook.mxid != null) {
        final uniqueKey = '${addressBook.mxid}';
        if (uniqueKey.isNotEmpty) {
          uniqueAddressBooks[uniqueKey] = addressBook;
        }
      }
    }

    return uniqueAddressBooks.values.toSet();
  }
}

extension AddressBookExtension on AddressBook {
  Set<PresentationContact> toPresentationContact() {
    return {
      PresentationContact(
        id: id ?? '',
        displayName: displayName,
        matrixId: mxid,
        status: addressBookIsActive()
            ? ContactStatus.active
            : ContactStatus.inactive,
      ),
    };
  }
}
