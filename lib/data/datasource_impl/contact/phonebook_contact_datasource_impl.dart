import 'package:fluffychat/data/datasource/contact/contacts_provider.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contact;
import 'package:fluffychat/data/datasource/contact/phonebook_datasource.dart';

class PhonebookContactDatasourceImpl implements PhonebookContactDatasource {
  final ContactsProvider _contactsProvider;

  PhonebookContactDatasourceImpl(this._contactsProvider);

  @override
  Future<List<Contact>> fetchContacts() async {
    final phonebookContacts = await _contactsProvider.getAll(
      properties: flutter_contact.ContactProperties.all,
    );

    final contacts = mappingToContact(phonebookContacts);
    return _sortContactsByDisplayName(contacts);
  }

  List<Contact> mappingToContact(
    List<flutter_contact.Contact> phoneBookContacts,
  ) {
    final listAllContacts = phoneBookContacts.map((contact) {
      final phoneNumbers = contact.phones
          .map((phone) => PhoneNumber(number: phone.number))
          .toList();
      final emails =
          contact.emails.map((email) => Email(address: email.address)).toList();

      return Contact(
        id: contact.id ?? '${emails.hashCode}${phoneNumbers.hashCode}',
        displayName: contact.displayName,
        phoneNumbers: _removeDuplicatedPhoneNumbers(phoneNumbers).toSet(),
        emails: _removeDuplicatedEmails(emails).toSet(),
      );
    }).toList();

    final listFilteredContacts = listAllContacts.where((contact) {
      return contact.phoneNumbers?.isNotEmpty == true ||
          contact.emails?.isNotEmpty == true;
    }).toList();

    return listFilteredContacts;
  }

  List<Contact> _sortContactsByDisplayName(List<Contact> contacts) {
    contacts.sort(
      (pre, next) => (pre.displayName ?? '').compareTo(next.displayName ?? ''),
    );
    return contacts;
  }

  List<PhoneNumber> _removeDuplicatedPhoneNumbers(
    List<PhoneNumber> phoneNumbers,
  ) {
    final listVisitedPhoneNumbers = <String>[];
    final filteredPhoneNumbers = <PhoneNumber>[];

    for (final contact in phoneNumbers) {
      final phoneNumber = contact.number;
      final normalizedPhoneNumber = phoneNumber.normalizePhoneNumber();

      if (listVisitedPhoneNumbers.contains(normalizedPhoneNumber)) {
        final hasSameFilteredContact = _hasSameFilteredPhoneNumber(
          filteredPhoneNumbers,
          normalizedPhoneNumber,
        );
        if (!hasSameFilteredContact) {
          filteredPhoneNumbers.add(contact);
        }
      } else {
        listVisitedPhoneNumbers.add(normalizedPhoneNumber);
        filteredPhoneNumbers.add(contact);
      }
    }

    return filteredPhoneNumbers;
  }

  bool _hasSameFilteredPhoneNumber(
    List<PhoneNumber> filteredPhoneNumbers,
    String phoneNumberNormalized,
  ) {
    return filteredPhoneNumbers.any(
      (filteredContact) =>
          filteredContact.number.normalizePhoneNumber() ==
          phoneNumberNormalized,
    );
  }

  List<Email> _removeDuplicatedEmails(List<Email> emails) {
    final listVisitedEmails = <String>[];
    final filteredEmails = <Email>[];

    for (final email in emails) {
      final emailAddress = email.address;

      if (listVisitedEmails.contains(emailAddress)) {
        final hasSameFilteredEmail = _hasSameFilteredEmail(
          filteredEmails,
          emailAddress,
        );
        if (!hasSameFilteredEmail) {
          filteredEmails.add(email);
        }
      } else {
        listVisitedEmails.add(emailAddress);
        filteredEmails.add(email);
      }
    }

    return filteredEmails;
  }

  bool _hasSameFilteredEmail(
    List<Email> filteredEmails,
    String emailAddress,
  ) {
    return filteredEmails.any(
      (filteredEmail) => filteredEmail.address == emailAddress,
    );
  }
}
