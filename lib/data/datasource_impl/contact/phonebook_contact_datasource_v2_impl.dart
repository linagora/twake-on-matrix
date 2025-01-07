import 'package:fluffychat/domain/model/contact/contact_v2.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contact;
import 'package:fluffychat/data/datasource/contact/phonebook_datasource_v2.dart';

class PhonebookContactDatasourceV2Impl implements PhonebookContactDatasourceV2 {
  @override
  Future<List<Contact>> fetchContacts() async {
    final phonebookContacts =
        await flutter_contact.FlutterContacts.getContacts(withProperties: true);

    return mappingToContact(phonebookContacts);
  }

  List<Contact> mappingToContact(
    List<flutter_contact.Contact> phoneBookContacts,
  ) {
    final listAllContacts = phoneBookContacts.map((contact) {
      final phoneNumbers = contact.phones
          .map((phone) => PhoneNumber(number: phone.number))
          .toList();
      final emails =
          contact.emails.map((email) => Email(address: email.address)).toSet();

      return Contact(
        id: contact.id,
        displayName: contact.displayName,
        phoneNumbers: _removeDuplicatedPhoneNumbers(phoneNumbers).toSet(),
        emails: emails,
      );
    }).toList();

    return listAllContacts;
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
        final hasSameFilteredContact = _hasSameFilteredContact(
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

  bool _hasSameFilteredContact(
    List<PhoneNumber> filteredPhoneNumbers,
    String phoneNumberNormalized,
  ) {
    return filteredPhoneNumbers.any(
      (filteredContact) =>
          filteredContact.number.normalizePhoneNumber() ==
          phoneNumberNormalized,
    );
  }
}
