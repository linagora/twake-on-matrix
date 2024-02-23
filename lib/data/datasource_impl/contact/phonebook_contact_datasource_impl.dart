import 'package:fluffychat/data/datasource/phonebook_datasouce.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;

class PhonebookContactDatasourceImpl implements PhonebookContactDatasource {
  @override
  Future<List<Contact>> fetchContacts() async {
    final phonebookContacts =
        await FlutterContacts.getContacts(withProperties: true);

    final listPhoneContacts = phonebookContacts
        .expand(
          (contact) => contact.phones.map(
            (phone) => Contact(
              phoneNumber: phone.number,
              displayName: contact.displayName,
            ),
          ),
        )
        .toList();

    final listEmailContacts = phonebookContacts
        .expand(
          (contact) => contact.emails.map(
            (email) => Contact(
              email: email.address,
              displayName: contact.displayName,
            ),
          ),
        )
        .toList();

    final listAllContacts = [
      ..._removeDuplicatedPhoneNumbers(listPhoneContacts),
      ...listEmailContacts,
    ];

    return listAllContacts;
  }

  List<Contact> _removeDuplicatedPhoneNumbers(List<Contact> listContacts) {
    final listVisitedPhoneNumbers = <String>[];
    final listFilteredContacts = <Contact>[];

    final listContactHasPhoneNumber =
        listContacts.where((contact) => contact.phoneNumber != null).toList();

    for (final contact in listContactHasPhoneNumber) {
      final phoneNumber = contact.phoneNumber;
      final normalizedPhoneNumber = phoneNumber!.normalizePhoneNumber();

      if (listVisitedPhoneNumbers.contains(normalizedPhoneNumber)) {
        final hasSameFilteredContact = _hasSameFilteredContact(
          listFilteredContacts,
          contact.displayName ?? '',
          normalizedPhoneNumber,
        );
        if (!hasSameFilteredContact) {
          listFilteredContacts.add(contact);
        }
      } else {
        listVisitedPhoneNumbers.add(normalizedPhoneNumber);
        listFilteredContacts.add(contact);
      }
    }

    return listFilteredContacts;
  }

  bool _hasSameFilteredContact(
    List<Contact> listFilteredContacts,
    String contactName,
    String phoneNumberNormalized,
  ) {
    return listFilteredContacts.any(
      (filteredContact) =>
          filteredContact.displayName == contactName &&
          filteredContact.phoneNumber?.normalizePhoneNumber() ==
              phoneNumberNormalized,
    );
  }
}
