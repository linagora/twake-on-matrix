import 'package:fluffychat/data/datasource/phonebook_datasouce.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;

class PhonebookContactDatasourceImpl implements PhonebookContactDatasource {
  @override
  Future<List<Contact>> fetchContacts() async {
    final phonebookContacts =
        await FlutterContacts.getContacts(withProperties: true);

    final listAllContacts = phonebookContacts
        .expand(
          (contact) => [
            ...contact.emails.map(
              (email) => Contact(
                email: email.address,
                displayName: contact.displayName,
              ),
            ),
            ...contact.phones.map(
              (phone) => Contact(
                phoneNumber: phone.number,
                displayName: contact.displayName,
              ),
            ),
          ],
        )
        .toList();

    return removeDuplicatedPhoneNumbers(listAllContacts);
  }

  List<Contact> removeDuplicatedPhoneNumbers(List<Contact> listContacts) {
    final listVisitedPhoneNumbers = <String>[];
    final listFilteredContacts = <Contact>[];

    for (final contact in listContacts) {
      final phoneNumber = contact.phoneNumber;
      if (phoneNumber != null) {
        final normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);
        if (listVisitedPhoneNumbers.contains(normalizedPhoneNumber)) {
          final contactsWithSamePhoneNumber =
              listFilteredContacts.where((filteredContact) {
            final filteredPhoneNumber = filteredContact.phoneNumber;
            if (filteredPhoneNumber != null) {
              return filteredContact.displayName == contact.displayName &&
                  normalizePhoneNumber(filteredPhoneNumber) ==
                      normalizedPhoneNumber;
            }
            return false;
          });
          if (contactsWithSamePhoneNumber.isEmpty) {
            listFilteredContacts.add(contact);
          } else {
            continue;
          }
        } else {
          listVisitedPhoneNumbers.add(normalizedPhoneNumber);
          listFilteredContacts.add(contact);
        }
      }
    }

    return listFilteredContacts;
  }

  String normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'\D'), '');
  }
}
