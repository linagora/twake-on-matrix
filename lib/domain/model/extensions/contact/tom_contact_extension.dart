import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/domain/model/contact/tom_contact.dart';

extension TomContactExtension on TomContact {
  Contact toContact(ContactStatus status) {
    return Contact(
      emails: mail != null || address != null
          ? {
              Email(
                address: mail ?? '',
                matrixId: address,
                status: status == ContactStatus.inactive
                    ? ThirdPartyStatus.inactive
                    : ThirdPartyStatus.active,
              ),
            }
          : {},
      displayName: displayName ?? uid,
      phoneNumbers: phoneNumber != null
          ? {
              PhoneNumber(
                number: phoneNumber ?? '',
                matrixId: address,
                status: status == ContactStatus.inactive
                    ? ThirdPartyStatus.inactive
                    : ThirdPartyStatus.active,
              ),
            }
          : {},
      id: address ?? uid,
    );
  }
}

extension TomContactsExtension on Set<TomContact> {
  Set<TomContact> removeUnknownTomContact() {
    return where(
      (tomContact) =>
          tomContact.mail != null ||
          tomContact.phoneNumber != null ||
          tomContact.address != null,
    ).map((contact) => contact).toSet();
  }
}
