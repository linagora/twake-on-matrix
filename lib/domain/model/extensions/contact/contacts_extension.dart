import 'package:fluffychat/domain/model/contact/contact_new.dart';

extension ContactsExtension on Iterable<Contact> {
  Iterable<Contact> searchContacts(String keyword) {
    if (keyword.isEmpty) {
      return this;
    }
    final contactsMatched = where((contact) {
      final supportedFields = [
        contact.displayName,
        contact.id,
      ];
      final plainTextContains = supportedFields.any(
        (field) =>
            field?.toLowerCase().contains(keyword.toLowerCase()) ?? false,
      );
      final phoneNumberContains = contact.phoneNumbers?.any(
            (phoneNumber) => phoneNumber.number.contains(keyword),
          ) ??
          false;

      final emailContains = contact.emails?.any(
            (email) => email.address.contains(keyword),
          ) ??
          false;
      return plainTextContains ||
          phoneNumberContains ||
          emailContains ||
          contact.id.contains(keyword);
    });
    return contactsMatched;
  }
}
