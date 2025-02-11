import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:matrix/encryption/utils/base64_unpadded.dart';

abstract class FederationThirdPartyContact with EquatableMixin {
  final String? matrixId;

  final String thirdPartyIdType;

  final String thirdPartyId;

  FederationThirdPartyContact({
    this.matrixId,
    required this.thirdPartyIdType,
    required this.thirdPartyId,
  });

  @override
  List<Object?> get props => [
        matrixId,
        thirdPartyIdType,
        thirdPartyId,
      ];

  String calculateHashWithAlgorithmSha256({
    required String pepper,
  }) {
    final input = [thirdPartyId, thirdPartyIdType, pepper].join(' ');
    final bytes = utf8.encode(input);
    final lookupHash =
        encodeBase64Unpadded(sha256.convert(bytes).bytes).urlSafeBase64;
    return lookupHash;
  }

  String calculateHashWithoutAlgorithm({
    required String pepper,
  }) {
    return [thirdPartyId, thirdPartyIdType].join(' ');
  }

  Set<String> calculateHashUsingAllPeppers({
    required FederationHashDetailsResponse hashDetails,
  }) {
    final Set<String> hashes = {};

    if (hashDetails.algorithms == null || hashDetails.algorithms!.isEmpty) {
      return hashes;
    }

    for (final algorithm in hashDetails.algorithms!) {
      final peppers = {
        hashDetails.lookupPepper,
      };

      for (final pepper in peppers) {
        if (algorithm == 'sha256') {
          final hash = calculateHashWithAlgorithmSha256(
            pepper: pepper ?? '',
          );
          hashes.add(hash);
        } else {
          final hash = calculateHashWithoutAlgorithm(
            pepper: pepper ?? '',
          );
          hashes.add(hash);
        }
      }
    }
    return hashes;
  }
}

class FederationPhone extends FederationThirdPartyContact {
  final String number;

  FederationPhone({
    required this.number,
    super.matrixId,
  }) : super(
          thirdPartyIdType: 'msisdn',
          thirdPartyId: number.msisdnSanitizer(),
        );

  @override
  List<Object?> get props => [
        matrixId,
        number,
        thirdPartyIdType,
      ];

  FederationPhone copyWith({
    String? matrixId,
  }) {
    return FederationPhone(
      matrixId: matrixId ?? this.matrixId,
      number: number,
    );
  }
}

class FederationEmail extends FederationThirdPartyContact {
  final String address;

  FederationEmail({
    super.matrixId,
    required this.address,
  }) : super(
          thirdPartyIdType: 'email',
          thirdPartyId: address,
        );

  @override
  List<Object?> get props => [
        address,
        matrixId,
        thirdPartyIdType,
      ];

  FederationEmail copyWith({
    String? matrixId,
  }) {
    return FederationEmail(
      matrixId: matrixId ?? this.matrixId,
      address: address,
    );
  }
}
