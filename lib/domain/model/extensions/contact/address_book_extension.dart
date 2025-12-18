import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
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

extension IterableAddressBookToContactExtension on Iterable<AddressBook> {
  /// Converts a list of AddressBook entries to a list of Contacts.
  List<Contact> toContacts() {
    return map((addressBook) => addressBook.toContact()).toList();
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

  /// Converts an AddressBook to a Contact.
  ///
  /// Since AddressBook primarily contains Matrix ID (mxid) information without
  /// email or phone number details, this creates a Contact with the mxid
  /// stored as matrixId and email is empty to preserve the Matrix ID association.
  Contact toContact() {
    final status = addressBookIsActive()
        ? ThirdPartyStatus.active
        : ThirdPartyStatus.inactive;

    // Use mxid as a pseudo-email to store the Matrix ID in the Contact structure
    // This allows the Contact to maintain the Matrix ID association
    final emails = mxid != null && mxid!.isNotEmpty
        ? {
            Email(
              address: '',
              matrixId: mxid,
              status: status,
            ),
          }
        : const <Email>{};

    return Contact(
      id: id ?? addressbookId ?? mxid ?? '',
      displayName: displayName,
      emails: emails,
      phoneNumbers: const {},
    );
  }
}
