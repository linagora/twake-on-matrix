import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:collection/collection.dart';

class PresentationContact extends Equatable {
  final Set<PresentationEmail>? emails;

  final Set<PresentationPhoneNumber>? phoneNumbers;

  final String? displayName;

  final String? matrixId;

  final bool expandInformation;

  final ContactStatus? status;

  final ContactType? type;

  final String? id;

  const PresentationContact({
    this.id,
    this.emails,
    this.phoneNumbers,
    this.displayName,
    this.matrixId,
    this.status,
    this.type,
    this.expandInformation = false,
  });

  PresentationContact get presentationContactEmpty => const PresentationContact(
    id: '',
    emails: {},
    displayName: '',
    matrixId: '',
    status: ContactStatus.inactive,
  );

  String get primaryEmail =>
      emails?.firstWhereOrNull((email) => email.email.isNotEmpty)?.email ?? '';

  String get primaryPhoneNumber =>
      phoneNumbers
          ?.firstWhereOrNull(
            (phoneNumber) => phoneNumber.phoneNumber.isNotEmpty,
          )
          ?.phoneNumber ??
      '';

  PresentationThirdPartyContact? get primaryContact {
    if (primaryPhoneNumber.isNotEmpty) {
      return phoneNumbers?.firstWhereOrNull(
        (phoneNumber) => phoneNumber.phoneNumber == primaryPhoneNumber,
      );
    }
    if (primaryEmail.isNotEmpty) {
      return emails?.firstWhereOrNull((email) => email.email == primaryEmail);
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    emails,
    phoneNumbers,
    displayName,
    matrixId,
    expandInformation,
    status,
    type,
  ];
}

abstract class PresentationThirdPartyContact with EquatableMixin {
  final String? matrixId;

  final String thirdPartyId;

  final ThirdPartyIdType thirdPartyIdType;

  final ThirdPartyStatus? status;

  PresentationThirdPartyContact({
    this.matrixId,
    required this.thirdPartyId,
    required this.thirdPartyIdType,
    this.status,
  });
}

class PresentationEmail extends PresentationThirdPartyContact {
  final String email;

  PresentationEmail({
    required this.email,
    super.matrixId,
    required super.thirdPartyId,
    required super.thirdPartyIdType,
    super.status,
  });

  @override
  List<Object?> get props => [
    email,
    matrixId,
    thirdPartyId,
    thirdPartyIdType,
    status,
  ];
}

class PresentationPhoneNumber extends PresentationThirdPartyContact {
  final String phoneNumber;

  PresentationPhoneNumber({
    required this.phoneNumber,
    super.matrixId,
    required super.thirdPartyId,
    required super.thirdPartyIdType,
    super.status,
  });

  @override
  List<Object?> get props => [
    phoneNumber,
    matrixId,
    thirdPartyId,
    thirdPartyIdType,
    status,
  ];
}
