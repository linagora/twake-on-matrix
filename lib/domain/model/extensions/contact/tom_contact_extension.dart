import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/tom_contact.dart';

extension TomContactExtension on TomContact {
  Contact toContact(ContactStatus status) {
    return Contact(
      emails: mail != null ? {mail!} : {},
      displayName: uid,
      phoneNumber: phoneNumber,
      matrixId: address,
      status: status,
    );
  }
}
