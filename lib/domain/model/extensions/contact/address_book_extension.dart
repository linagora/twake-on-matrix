import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';

/// Extension methods for searching and filtering collections of AddressBook
/// entries.
extension IterableAddressBookExtension on Iterable<AddressBook> {
  /// Searches address book entries by keyword.
  ///
  /// Performs a case-insensitive search across the following fields:
  /// - Display name
  /// - Matrix ID
  ///
  /// Returns all entries if [keyword] is empty, otherwise returns only
  /// matching entries.
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
      return plainTextContains;
    });
    return contactsMatched;
  }
}

/// Extension methods for deduplicating sets of AddressBook entries.
extension AddressBookListExtension on Set<AddressBook> {
  /// Removes duplicate AddressBook entries based on Matrix ID.
  ///
  /// Uses the [mxid] field as the unique key. If multiple AddressBook entries
  /// share the same Matrix ID, only the last one encountered is kept.
  ///
  /// Returns a new Set containing only unique AddressBook entries.
  Set<AddressBook> combineDuplicateAddressBooks() {
    final Map<String, AddressBook> uniqueAddressBooks = {};

    for (final addressBook in this) {
      if (addressBook.mxid != null) {
        if (addressBook.mxid!.isNotEmpty) {
          uniqueAddressBooks[addressBook.mxid!] = addressBook;
        }
      }
    }

    return uniqueAddressBooks.values.toSet();
  }
}

/// Extension methods for batch converting AddressBook entries to Contacts.
extension IterableAddressBookToContactExtension on Iterable<AddressBook> {
  /// Converts a collection of AddressBook entries to a list of Contact objects.
  ///
  /// Each AddressBook is transformed using the [AddressBook.toContact] method,
  /// which handles the conversion of emails, phone numbers, and Matrix IDs.
  ///
  /// Returns a List of [Contact] objects.
  List<Contact> toContacts() {
    return map((addressBook) => addressBook.toContact()).toList();
  }
}

/// Extension methods for converting AddressBook entries to various models.
extension AddressBookExtension on AddressBook {
  /// Converts an AddressBook entry to a PresentationContact for UI display.
  ///
  /// This method transforms the AddressBook data into a presentation model
  /// suitable for rendering in the user interface. It includes:
  /// - Contact status (active/inactive)
  /// - Email addresses with third-party identifiers
  /// - Phone numbers with third-party identifiers
  ///
  /// Returns a Set containing a single [PresentationContact] object.
  Set<PresentationContact> toPresentationContact() {
    return {
      PresentationContact(
        id: id ?? '',
        displayName: displayName,
        matrixId: mxid,
        status: addressBookIsActive()
            ? ContactStatus.active
            : ContactStatus.inactive,
        emails: emails
            ?.map(
              (email) => PresentationEmail(
                email: email,
                thirdPartyId: email,
                thirdPartyIdType: ThirdPartyIdType.email,
              ),
            )
            .toSet(),
        phoneNumbers: phones
            ?.map(
              (number) => PresentationPhoneNumber(
                phoneNumber: number,
                thirdPartyId: number,
                thirdPartyIdType: ThirdPartyIdType.msisdn,
              ),
            )
            .toSet(),
      ),
    };
  }

  /// Gets the third-party status based on the AddressBook's active state.
  ///
  /// Returns [ThirdPartyStatus.active] if the AddressBook is active,
  /// otherwise returns [ThirdPartyStatus.inactive].
  ThirdPartyStatus get addressBookStatus {
    return addressBookIsActive()
        ? ThirdPartyStatus.active
        : ThirdPartyStatus.inactive;
  }

  /// Converts the AddressBook's email information to a set of Email objects.
  ///
  /// This method handles three scenarios:
  /// 1. If both [emails] list and [mail] field are empty/null, creates a
  ///    synthetic Email with empty address but preserves the Matrix ID.
  ///    This prevents Matrix ID duplication in the UI while maintaining the
  ///    association.
  /// 2. If [emails] list exists, maps each email string to an Email object
  ///    with the appropriate status.
  /// 3. Returns null if no email information is available.
  ///
  /// Returns a Set of [Email] objects or null if no emails exist.
  Set<Email>? toEmails() {
    final hasNoEmails = emails == null || emails!.isEmpty;
    final hasNoMail = mail == null || mail!.isEmpty;

    if (hasNoEmails && hasNoMail && mxid != null && mxid!.isNotEmpty) {
      return {
        Email(
          address: '',
          matrixId: mxid,
          status: addressBookStatus,
        ),
      };
    }

    return emails
        ?.map(
          (email) => Email(
            address: email,
            matrixId: mxid,
            status: addressBookStatus,
          ),
        )
        .toSet();
  }

  /// Converts the AddressBook's phone information to a set of PhoneNumber
  /// objects.
  ///
  /// This method handles three scenarios:
  /// 1. If both [phones] list and [mobile] field are empty/null, creates a
  ///    synthetic PhoneNumber with empty number but preserves the Matrix ID.
  ///    This prevents Matrix ID duplication in the UI while maintaining the
  ///    association.
  /// 2. If [phones] list exists, maps each phone string to a PhoneNumber
  ///    object with the Matrix ID and appropriate status.
  /// 3. Returns null if no phone information is available.
  ///
  /// Returns a Set of [PhoneNumber] objects or null if no phones exist.
  Set<PhoneNumber>? toPhoneNumber() {
    final hasNoPhones = phones == null || phones!.isEmpty;
    final hasNoMobile = mobile == null || mobile!.isEmpty;

    if (hasNoPhones && hasNoMobile && mxid != null && mxid!.isNotEmpty) {
      return {
        PhoneNumber(
          number: '',
          matrixId: mxid,
          status: addressBookStatus,
        ),
      };
    }

    return phones
        ?.map(
          (number) => PhoneNumber(
            number: number,
            matrixId: mxid,
            status: addressBookStatus,
          ),
        )
        .toSet();
  }

  /// Converts an AddressBook entry to a Contact object.
  ///
  /// This method transforms server-side AddressBook data into the domain
  /// Contact model. It handles the conversion of:
  /// - Email addresses from the [emails] list or [mail] field
  /// - Phone numbers from the [phones] list or [mobile] field
  /// - Matrix IDs associated with the contact
  ///
  /// The conversion uses helper methods [toEmails] and [toPhoneNumber] to
  /// properly handle cases where Matrix IDs need to be preserved even when
  /// no actual email/phone data exists.
  ///
  /// Returns a [Contact] object with all available information from the
  /// AddressBook.
  Contact toContact() {
    return Contact(
      id: id ?? addressbookId ?? mxid ?? '',
      displayName: displayName,
      emails: toEmails(),
      phoneNumbers: toPhoneNumber(),
    );
  }
}
