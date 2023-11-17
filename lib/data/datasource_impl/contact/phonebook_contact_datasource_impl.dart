import 'package:fluffychat/data/datasource/phonebook_datasouce.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;

class PhonebookContactDatasourceImpl implements PhonebookContactDatasource {
  @override
  Future<List<Contact>> fetchContacts() async {
    final phonebookContacts =
        await FlutterContacts.getContacts(withProperties: true);
    return phonebookContacts
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
  }

  @override
  void addListener(VoidCallback callback) {
    FlutterContacts.addListener(callback);
  }

  @override
  void removeListener(VoidCallback callback) {
    FlutterContacts.removeListener(callback);
  }
}
