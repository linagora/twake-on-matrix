import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:collection/collection.dart';

extension PresentaionContactExtension on PresentationContact {
  Set<PresentationSearch> toPresentationSearch() {
    final listContacts = {
      ContactPresentationSearch(
        matrixId: matrixId,
        displayName: displayName,
      ),
    };
    return listContacts;
  }
}

extension ContactExtensionInPresentation on Contact {
  Set<PresentationContact> toPresentationContacts() {
    final phoneNumberHasMatrixId = phoneNumbers?.firstWhereOrNull(
      (phoneNumber) => phoneNumber.matrixId != null,
    );

    final emailHasMatrixId = emails?.firstWhereOrNull(
      (email) => email.matrixId != null,
    );

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
