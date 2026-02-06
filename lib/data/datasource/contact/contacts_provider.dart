import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contact;

abstract class ContactsProvider {
  Future<List<flutter_contact.Contact>> getAll({
    dynamic properties,
  });
}

class FlutterContactsProviderImpl implements ContactsProvider {
  @override
  Future<List<flutter_contact.Contact>> getAll({
    dynamic properties,
  }) {
    return flutter_contact.FlutterContacts.getAll(
      properties: properties,
    );
  }
}
