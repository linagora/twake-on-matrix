import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:crypto/crypto.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:matrix/encryption/utils/base64_unpadded.dart';

import 'contact_status.dart';

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
  final String? email;

  final String? displayName;

  final String? matrixId;

  final String? phoneNumber;

  final ContactStatus? status;

  const Contact({
    this.email,
    this.displayName,
    this.matrixId,
    this.phoneNumber,
    this.status,
  });

  @override
  List<Object?> get props =>
      [email, displayName, matrixId, phoneNumber, status];

  Contact copyWith({
    String? email,
    String? displayName,
    String? matrixId,
    String? phoneNumber,
    ContactStatus? status,
  }) {
    return Contact(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      matrixId: matrixId ?? this.matrixId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
    );
  }

  String? get thirdPartyId {
    if (phoneNumber != null) {
      return phoneNumber!.msisdnSanitizer();
    }
    return email;
  }

  ThirdPartyIdType? get thirdPartyIdType {
    if (phoneNumber != null) {
      return ThirdPartyIdType.msisdn;
    }
    if (email != null) {
      return ThirdPartyIdType.email;
    }
    return null;
  }

  String? calLookupAddress({required HashDetailsResponse hashDetails}) {
    if ((email == null && phoneNumber == null) || matrixId != null) {
      return null;
    }
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
}
