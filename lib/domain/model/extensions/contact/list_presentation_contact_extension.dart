import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';

extension ListPresentationContactExtension on Set<PresentationContact> {
  Set<Contact> toContacts () {
    final displayNameToEmails = <String, Set<String>>{};
    for (final presentationContact in this) {
      final tempSet = displayNameToEmails[presentationContact.displayName] ?? {};
      if (presentationContact.email != null) {
        tempSet.add(presentationContact.email!);
      }

      if (presentationContact.displayName != null) {
        displayNameToEmails[presentationContact.displayName!] = tempSet;
      }
    }
    
    return displayNameToEmails.entries
      .map<Contact>(
        (contact) => Contact(
          displayName: contact.key, 
          emails: displayNameToEmails[contact.key] ?? {}))
      .toSet();
  }
}