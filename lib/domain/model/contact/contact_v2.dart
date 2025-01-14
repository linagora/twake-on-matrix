import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:crypto/crypto.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:matrix/encryption/utils/base64_unpadded.dart';

enum ThirdPartyIdType {
  email,
  msisdn;

  @override
  String toString() {
    switch (this) {
      case email:
        return 'email';
      case msisdn:
        return 'msisdn';
    }
  }
}

class Contact extends Equatable {
  final String id;

  final Set<Email>? emails;

  final String? displayName;

  final Set<PhoneNumber>? phoneNumbers;

  const Contact({
    required this.id,
    this.emails,
    this.displayName,
    this.phoneNumbers,
  });

  @override
  List<Object?> get props => [
        id,
        emails,
        displayName,
        phoneNumbers,
      ];

  Contact copyWith({
    String? displayName,
    Set<Email>? emails,
    Set<PhoneNumber>? phoneNumbers,
  }) {
    return Contact(
      id: id,
      displayName: displayName ?? this.displayName,
      emails: emails ?? this.emails,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
    );
  }
}

abstract class ThirdPartyContact with EquatableMixin {
  final String? matrixId;

  final String thirdPartyId;

  final ThirdPartyIdType thirdPartyIdType;

  final ThirdPartyStatus? status;

  ThirdPartyContact({
    required this.thirdPartyId,
    required this.thirdPartyIdType,
    this.matrixId,
    this.status,
  });

  String? calLookupAddress({required HashDetailsResponse hashDetails}) {
    final algorithm = hashDetails.algorithms?.firstOrNull ?? 'sha256';
    if (algorithm == 'sha256') {
      final pepper = hashDetails.lookupPepper ?? '';
      final input = [thirdPartyId, thirdPartyIdType, pepper].join(' ');
      final bytes = utf8.encode(input);
      final lookupHash =
          encodeBase64Unpadded(sha256.convert(bytes).bytes).urlSafeBase64;
      return lookupHash;
    } else {
      return [thirdPartyId, thirdPartyIdType].join(' ');
    }
  }

  @override
  List<Object?> get props => [
        thirdPartyId,
        thirdPartyIdType,
        matrixId,
        status,
      ];
}

class PhoneNumber extends ThirdPartyContact {
  final String number;

  PhoneNumber({
    required this.number,
    super.matrixId,
    super.status,
  }) : super(
          thirdPartyId: number.msisdnSanitizer(),
          thirdPartyIdType: ThirdPartyIdType.msisdn,
        );

  @override
  List<Object?> get props => [
        number,
        matrixId,
        status,
      ];

  PhoneNumber copyWith({
    String? matrixId,
    ThirdPartyStatus? status,
  }) {
    return PhoneNumber(
      number: number,
      matrixId: matrixId ?? this.matrixId,
      status: status ?? this.status,
    );
  }
}

class Email extends ThirdPartyContact {
  final String address;

  Email({
    required this.address,
    super.matrixId,
    super.status,
  }) : super(
          thirdPartyId: address,
          thirdPartyIdType: ThirdPartyIdType.email,
        );

  Email copyWith({
    String? matrixId,
    ThirdPartyStatus? status,
  }) {
    return Email(
      address: address,
      matrixId: matrixId ?? this.matrixId,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        address,
        matrixId,
        status,
      ];
}
