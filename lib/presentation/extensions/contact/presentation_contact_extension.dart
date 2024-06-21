import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';

extension PresentaionContactExtension on PresentationContact {
  bool matched({required bool Function(String) condition}) {
    if (displayName != null && condition(displayName!)) {
      return true;
    }

    if (matrixId != null && condition(matrixId!)) {
      return true;
    }

    if (email != null && condition(email!)) {
      return true;
    }

    if (status != null && condition(status.toString())) {
      return true;
    }

    return false;
  }

  Set<Contact> toContacts() {
    final listContacts = {
      Contact(
        email: email,
        displayName: displayName,
        matrixId: matrixId,
        status: status,
      ),
    };

    return listContacts;
  }

  Set<PresentationSearch> toPresentationSearch() {
    final listContacts = {
      ContactPresentationSearch(
        matrixId: matrixId,
        email: email,
        displayName: displayName,
      ),
    };
    return listContacts;
  }
}

extension ContactExtensionInPresentation on Contact {
  Set<PresentationContact> toPresentationContacts() {
    final listContacts = {
      PresentationContact(
        email: email,
        phoneNumber: phoneNumber,
        displayName: displayName,
        matrixId: matrixId,
        status: status,
      ),
    };

    return listContacts;
  }
}
