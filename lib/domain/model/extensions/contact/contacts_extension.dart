import 'package:fluffychat/domain/model/contact/contact.dart';

extension ContactsExtension on List<Contact> {
  List<Contact> searchContacts(String keyword) {
    final contactMatched = where((contact) {
      final supportedFields = [
        contact.displayName,
        contact.matrixId,
        contact.email,
      ];
      return supportedFields.any(
        (field) =>
            field?.toLowerCase().contains(keyword.toLowerCase()) ?? false,
      );
    }).toList();
    return contactMatched;
  }
}
