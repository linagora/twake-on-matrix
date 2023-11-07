import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';

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
}

extension ContactExtensionInPresentation on Contact {
  Set<PresentationContact> toPresentationContacts() {
    final listContacts = {
      PresentationContact(
        email: email,
        displayName: displayName,
        matrixId: matrixId,
        status: status,
      ),
    };

    if (email == null || email!.isEmpty) {
      listContacts.add(
        PresentationContact(
          email: null,
          displayName: displayName,
          matrixId: matrixId,
          status: status,
        ),
      );
    }

    return listContacts;
  }
}
