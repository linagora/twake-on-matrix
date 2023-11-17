import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/utils/string_extension.dart';

extension ContactsExtension on Iterable<Contact> {
  Iterable<Contact> searchContacts(String keyword) {
    if (keyword.isEmpty) {
      return this;
    }
    final contactsMatched = where((contact) {
      final supportedFields = [
        contact.displayName,
        contact.matrixId,
        contact.email,
      ];
      final plainTextContains = supportedFields.any(
        (field) =>
            field?.toLowerCase().contains(keyword.toLowerCase()) ?? false,
      );
      final phoneNumberContains = contact.phoneNumber
              ?.msisdnSanitizer()
              .contains(keyword.msisdnSanitizer()) ??
          false;
      return plainTextContains || phoneNumberContains;
    });
    return contactsMatched;
  }
}
