import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/repository/federation_identity_lookup_repository.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:matrix/encryption/utils/base64_unpadded.dart';

class FederationIdentityLookupInteractor {
  final FederationIdentityLookupRepository federationIdentityLookupRepository;

  FederationIdentityLookupInteractor({
    required this.federationIdentityLookupRepository,
  });

  Stream<Either<Failure, Success>> execute({
    required FederationArguments arguments,
  }) async* {
    try {
      yield const Right(FederationIdentityLookupLoading());
      final registerResponse =
          await federationIdentityLookupRepository.register(
        tokenInformation: arguments.tokenInformation,
      );

      if (registerResponse.token == null && registerResponse.token!.isEmpty) {
        yield const Left(FederationIdentityGetTokenFailure());
      }

      final hashDetails =
          await federationIdentityLookupRepository.getHashDetails(
        token: registerResponse.token!,
      );

      final addresses = _calculateHashes(
        hashDetails: hashDetails,
        arguments: arguments,
      );

      if (addresses.isEmpty) {
        yield const Left(FederationIdentityCalculationHashesEmpty());
      }

      final lookupMxidResponse =
          await federationIdentityLookupRepository.lookupMxid(
        request: FederationLookupMxidRequest(
          addresses: addresses,
          algorithm: hashDetails.algorithms?.firstOrNull,
          pepper: hashDetails.lookupPepper,
        ),
        token: registerResponse.token!,
      );

      yield Right(
        FederationIdentityLookupSuccess(
          federationLookupMxidResponse: lookupMxidResponse,
        ),
      );
    } catch (e) {
      yield Left(FederationIdentityLookupFailure(exception: e));
    }
  }

  Set<String> _calculateHashes({
    required FederationHashDetailsResponse hashDetails,
    required FederationArguments arguments,
  }) {
    final addresses = <String>{};
    if (arguments.phoneNumbers != null && arguments.phoneNumbers!.isNotEmpty) {
      for (final phoneNumber in arguments.phoneNumbers!) {
        final hashes = calculateHashUsingAllPeppers(
          hashDetails: hashDetails,
          thirdPartyId: phoneNumber,
          thirdPartyIdType: 'msisdn',
        );
        addresses.addAll(hashes);
      }
    }

    if (arguments.emailAddresses != null &&
        arguments.emailAddresses!.isNotEmpty) {
      for (final email in arguments.emailAddresses!) {
        final hashes = calculateHashUsingAllPeppers(
          hashDetails: hashDetails,
          thirdPartyId: email,
          thirdPartyIdType: 'email',
        );
        addresses.addAll(hashes);
      }
    }
    return addresses;
  }

  String calculateHashWithAlgorithmSha256({
    required String pepper,
    required String thirdPartyId,
    required String thirdPartyIdType,
  }) {
    final input = [thirdPartyId, thirdPartyIdType, pepper].join(' ');
    final bytes = utf8.encode(input);
    final lookupHash =
        encodeBase64Unpadded(sha256.convert(bytes).bytes).urlSafeBase64;
    return lookupHash;
  }

  String calculateHashWithoutAlgorithm({
    required String pepper,
    required String thirdPartyId,
    required String thirdPartyIdType,
  }) {
    return [thirdPartyId, thirdPartyIdType].join(' ');
  }

  Set<String> calculateHashUsingAllPeppers({
    required FederationHashDetailsResponse hashDetails,
    required String thirdPartyId,
    required String thirdPartyIdType,
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
            thirdPartyId: '',
            thirdPartyIdType: '',
            pepper: pepper ?? '',
          );
          hashes.add(hash);
        } else {
          final hash = calculateHashWithoutAlgorithm(
            thirdPartyId: '',
            thirdPartyIdType: '',
            pepper: pepper ?? '',
          );
          hashes.add(hash);
        }
      }
    }
    return hashes;
  }
}
