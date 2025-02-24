import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';

extension ContactExtension on Contact {
  FederationContact toFederationContact() {
    return FederationContact(
      id: id,
      name: displayName ?? "",
      phoneNumbers: phoneNumbers?.map((phone) => phone.toFedPhone()).toSet(),
      emails: emails?.map((email) => email.toFedEmail()).toSet(),
    );
  }
}

extension IterableContactsExtension on Iterable<Contact> {
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

extension ContactsExtension on Map<String, Contact> {
  Map<String, FederationContact> toFederationContactMap() {
    return map(
      (key, value) => MapEntry(key, value.toFederationContact()),
    );
  }
}

extension PhoneNumberExtension on PhoneNumber {
  FederationPhone toFedPhone() {
    return FederationPhone(
      number: number,
    );
  }
}

extension EmailExtension on Email {
  FederationEmail toFedEmail() {
    return FederationEmail(
      address: address,
    );
  }
}

extension FederationContactExtension on FederationContact {
  Contact toContact() {
    return Contact(
      id: id,
      displayName: name,
      phoneNumbers: phoneNumbers?.map((phone) => phone.toPhoneNumber()).toSet(),
      emails: emails?.map((email) => email.toEmail()).toSet(),
    );
  }
}

extension FederationContactsMapExtension on Map<String, FederationContact> {
  List<Contact> toContacts() {
    return values.map((contact) => contact.toContact()).toList();
  }
}

extension FederationContactsExtension on List<FederationContact> {
  List<Contact> toContacts() {
    return map((contact) => contact.toContact()).toList();
  }
}

extension FederationPhoneExtension on FederationPhone {
  PhoneNumber toPhoneNumber() {
    return PhoneNumber(
      number: number,
      matrixId: matrixId,
    );
  }
}

extension FederationEmailExtension on FederationEmail {
  Email toEmail() {
    return Email(
      address: address,
      matrixId: matrixId,
    );
  }
}
