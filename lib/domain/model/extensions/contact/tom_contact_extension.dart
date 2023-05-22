import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/tom_contact.dart';
import 'package:fluffychat/utils/string_extension.dart';

extension TomContactExtension on TomContact {
  Contact toContact(ContactStatus status) {
    return Contact(
      emails: mail != null ? {mail!} : {},
      displayName: mxid,
      phoneNumber: phoneNumber,
      matrixId: mxid.toTomMatrixId(),
      status: status,
    );
  }
}
