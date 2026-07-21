import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';

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
  /// This method handles two scenarios:
  /// 1. If no emails exist but a Matrix ID is present, creates a synthetic
  ///    Email with an empty address field while preserving the Matrix ID.
  ///    This ensures Matrix IDs are stored correctly without displaying as
  ///    duplicate entries in the contacts UI.
  /// 2. If emails exist, maps each email string to an Email object with the
  ///    associated Matrix ID and status.
  ///
  /// Returns a Set of [Email] objects or null if no email or Matrix ID data
  /// is available.
  Set<Email>? toEmails() {
    final hasNoEmails = emails == null || emails!.isEmpty;

    if (hasNoEmails && mxid != null && mxid!.isNotEmpty) {
      return {Email(address: '', matrixId: mxid, status: addressBookStatus)};
    }

    return emails
        ?.map(
          (email) =>
              Email(address: email, matrixId: mxid, status: addressBookStatus),
        )
        .toSet();
  }

  /// Converts the AddressBook's phone information to a set of PhoneNumber
  /// objects.
  ///
  /// This method handles two scenarios:
  /// 1. If no phone numbers exist but a Matrix ID is present, creates a
  ///    synthetic PhoneNumber with an empty number field while preserving the
  ///    Matrix ID. This ensures Matrix IDs are stored correctly without
  ///    displaying as duplicate entries in the contacts UI.
  /// 2. If phone numbers exist, maps each phone string to a PhoneNumber object
  ///    with the associated Matrix ID and status.
  ///
  /// Returns a Set of [PhoneNumber] objects or null if no phone or Matrix ID
  /// data is available.
  Set<PhoneNumber>? toPhoneNumber() {
    final hasNoPhones = phones == null || phones!.isEmpty;

    if (hasNoPhones && mxid != null && mxid!.isNotEmpty) {
      return {
        PhoneNumber(number: '', matrixId: mxid, status: addressBookStatus),
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
  /// Contact model. It handles the conversion of email addresses, phone
  /// numbers, and Matrix IDs.
  ///
  /// The conversion uses [toEmails] and [toPhoneNumber] helper methods to
  /// properly handle Matrix ID storage. When no email or phone data exists,
  /// these methods create synthetic entries with empty address/number fields
  /// to preserve the Matrix ID without causing UI duplication.
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
