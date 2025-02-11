import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/repository/federation_identity_lookup_repository.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';

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
        yield Left(
          FederationIdentityRegisterAccountFailure(
            identityServer: arguments.federationUrl,
          ),
        );
      }

      final hashDetails =
          await federationIdentityLookupRepository.getHashDetails(
        token: registerResponse.token!,
      );

      if (hashDetails.lookupPepper == null ||
          hashDetails.lookupPepper == null) {
        yield const Left(FederationIdentityGetHashDetailsFailure());
      }

      final Map<String, FederationContact> newContacts = {};

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

      if (lookupMxidResponse.mappings == null) {
        yield const Left(
          FederationIdentityLookupFailure(exception: 'No mappings found'),
        );
      }

      yield Right(
        FederationIdentityLookupSuccess(
          newContacts: newContacts,
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
    for (final contact in arguments.contactMaps.values) {
      final hashes = contact.calculateHashUsingAllPeppers(
        lookupPepper: hashDetails.lookupPepper ?? '',
        algorithms: hashDetails.algorithms ?? {},
      );
      addresses.addAll(hashes);
    }
    return addresses;
  }
}
