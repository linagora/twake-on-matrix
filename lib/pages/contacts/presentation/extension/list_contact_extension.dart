import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';

extension ListContactExtension on Set<Contact> {
  Set<PresentationContact> toPresentationContacts() {
    final Set<PresentationContact> results = {};
    for (final contact in this) {
      for (final email in contact.emails) {
        results.add(PresentationContact(displayName: contact.displayName, email: email));
      }
    }
    return results;
  }

  Set<Contact> filter({String? searchKey = ''}) {
    if (searchKey?.isEmpty != false) {
      return this;
    }

    final searchKeyLower = searchKey!.toLowerCase();
    final filteredContacts = <Contact>{};
    for (final contact in this) {
      if (contact.displayName.toLowerCase().contains(searchKeyLower)) {
        filteredContacts.add(contact);
        continue;
      }
      final filterEmails = <String>{};
      for (final email in contact.emails) {
        if (email.toLowerCase().contains(searchKeyLower)) {
          filterEmails.add(email);
        }
      }
      if (filterEmails.isNotEmpty) {
        filteredContacts.add(Contact(emails: filterEmails, displayName: contact.displayName));
      }
    }
    return filteredContacts;
  }
}