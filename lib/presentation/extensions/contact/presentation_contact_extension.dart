import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:collection/collection.dart';

extension PresentaionContactExtension on PresentationContact {
  Set<PresentationSearch> toPresentationSearch() {
    final listContacts = {
      ContactPresentationSearch(
        matrixId: matrixId,
        displayName: displayName,
        emails: emails,
        phoneNumbers: phoneNumbers,
      ),
    };
    return listContacts;
  }
}

extension ContactExtensionInPresentation on Contact {
  Set<PresentationContact> toPresentationContacts() {
    final phoneNumberHasMatrixId = phoneNumbers?.firstWhereOrNull(
      (phoneNumber) =>
          phoneNumber.matrixId != null && phoneNumber.matrixId!.isNotEmpty,
    );

    final emailHasMatrixId = emails?.firstWhereOrNull(
      (email) => email.matrixId != null && email.matrixId!.isNotEmpty,
    );

    final status =
        phoneNumberHasMatrixId?.status ??
        emailHasMatrixId?.status ??
        ThirdPartyStatus.active;

    final displayName = (this.displayName?.isNotEmpty == true)
        ? this.displayName
        : phoneNumberHasMatrixId?.number ??
              emailHasMatrixId?.address ??
              phoneNumbers?.firstOrNull?.number ??
              emails?.firstOrNull?.address;

    final contactMatrix = phoneNumberHasMatrixId ?? emailHasMatrixId;
    final listContacts = {
      PresentationContact(
        emails: emails?.map((email) => email.toPresentationEmails()).toSet(),
        phoneNumbers: phoneNumbers
            ?.map((phoneNumber) => phoneNumber.toPresentationPhoneNumbers())
            .toSet(),
        displayName: displayName,
        matrixId: contactMatrix?.matrixId ?? '',
        id: id,
        status: status == ThirdPartyStatus.inactive
            ? ContactStatus.inactive
            : ContactStatus.active,
      ),
    };

    return listContacts;
  }
}

extension EmailExtensionInPresentation on Email {
  PresentationEmail toPresentationEmails() {
    return PresentationEmail(
      email: address,
      thirdPartyId: thirdPartyId,
      thirdPartyIdType: thirdPartyIdType,
      status: status,
      matrixId: matrixId,
    );
  }
}

extension PhoneNumberExtensionInPresentation on PhoneNumber {
  PresentationPhoneNumber toPresentationPhoneNumbers() {
    return PresentationPhoneNumber(
      phoneNumber: number,
      thirdPartyId: thirdPartyId,
      thirdPartyIdType: thirdPartyIdType,
      status: status,
      matrixId: matrixId,
    );
  }
}

extension ListPresentationContact on List<PresentationContact> {
  List<PresentationContact> combineDuplicateContact({
    required List<PresentationContact> contacts,
  }) {
    final Map<String, PresentationContact> distinctContactsAndChatsMap = {};

    if (isEmpty) {
      return contacts;
    }

    for (final contact in this) {
      if (contact.matrixId != null) {
        distinctContactsAndChatsMap[contact.matrixId!] = contact;
      }
    }

    for (final contact in contacts) {
      final existingContact = distinctContactsAndChatsMap[contact.matrixId];

      if (existingContact == null) {
        distinctContactsAndChatsMap[contact.matrixId!] = contact;
      }
    }

    return distinctContactsAndChatsMap.values.toList();
  }
}
