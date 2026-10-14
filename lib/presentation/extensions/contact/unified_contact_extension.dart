import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/model/contact/contact.dart'
    show ThirdPartyIdType;
import 'package:twake_chat/domain/model/contact/contact_status.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';

extension UnifiedContactPresentationExtension on UnifiedContact {
  /// True when the contact belongs to the TOM address book (directory), as
  /// opposed to a room-member-only entry used for identity resolution.
  bool get isAddressBookContact => sources.any(
    (source) =>
        source.kind == ContactSourceKind.tomAddressBook ||
        source.kind == ContactSourceKind.tomUserInfo,
  );

  PresentationContact toPresentationContact() => PresentationContact(
    id: matrixId,
    displayName: resolvedDisplayName,
    matrixId: matrixId,
    status: active ? ContactStatus.active : ContactStatus.inactive,
    emails: emails
        .map(
          (email) => PresentationEmail(
            email: email,
            thirdPartyId: email,
            thirdPartyIdType: ThirdPartyIdType.email,
            matrixId: matrixId,
          ),
        )
        .toSet(),
    phoneNumbers: phones
        .map(
          (phone) => PresentationPhoneNumber(
            phoneNumber: phone,
            thirdPartyId: phone,
            thirdPartyIdType: ThirdPartyIdType.msisdn,
            matrixId: matrixId,
          ),
        )
        .toSet(),
  );
}
