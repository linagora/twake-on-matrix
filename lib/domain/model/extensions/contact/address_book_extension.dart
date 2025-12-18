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
  /// AddressBook entries from the server contain Matrix IDs (mxid) but no
  /// third-party identifiers like email addresses or phone numbers.
  ///
  /// To preserve the Matrix ID in the Contact model, this method creates an
  /// Email object with:
  /// - `address`: Empty string (no actual email address available)
  /// - `matrixId`: The Matrix ID from the AddressBook
  /// - `status`: Active/inactive based on the AddressBook's active flag
  ///
  /// Note: This creates a synthetic Email entry solely to store the Matrix ID,
  /// as the Contact model doesn't have a dedicated matrixId field. The empty
  /// address allows the matrixId to be preserved without displaying duplicate
  /// Matrix IDs in the UI.
  Contact toContact() {
    final status = addressBookIsActive()
        ? ThirdPartyStatus.active
        : ThirdPartyStatus.inactive;

    // Create an Email object with empty address to store the Matrix ID.
    // The Email.matrixId field stores the association while the empty address
    // prevents the Matrix ID from being displayed twice in the UI
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
