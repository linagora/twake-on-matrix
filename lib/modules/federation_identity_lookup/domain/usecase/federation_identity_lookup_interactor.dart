import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/repository/federation_identity_lookup_repository.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';

class FederationIdentityLookupInteractor {
  final FederationIdentityLookupRepository federationIdentityLookupRepository;

  FederationIdentityLookupInteractor({
    required this.federationIdentityLookupRepository,
  });

  Future<Either<Failure, Success>> execute({
    required FederationArguments arguments,
  }) async {
    try {
      final registerResponse =
          await federationIdentityLookupRepository.register(
        tokenInformation: arguments.tokenInformation,
      );

      if (registerResponse.token == null && registerResponse.token!.isEmpty) {
        return Left(
          FederationIdentityRegisterAccountFailure(
            identityServer: arguments.federationUrl,
          ),
        );
      }

      final hashDetails =
          await federationIdentityLookupRepository.getHashDetails(
        token: registerResponse.token!,
      );

      if (hashDetails.lookupPepper == null || hashDetails.algorithms == null) {
        return const Left(FederationIdentityGetHashDetailsFailure());
      }

      final contactIdToHashMap = {};

      final Map<String, FederationContact> newContacts = {};

      final Map<String, List<String>> hashToContactIdMappings = {};

      for (final contact in arguments.contactMaps.values) {
        final phoneToHashMap = <String, String>{};

        final emailToHashMap = <String, String>{};
        if (hashDetails.algorithms!.isEmpty) {
          return const Left(FederationIdentityGetHashDetailsFailure());
        }

        if (contact.phoneNumbers != null) {
          for (final phone in contact.phoneNumbers!) {
            final hash = phone.calculateHashWithAlgorithmSha256(
              pepper: hashDetails.lookupPepper!,
            );
            phoneToHashMap.putIfAbsent(phone.number, () => hash);

            hashToContactIdMappings.putIfAbsent(contact.id, () => []).addAll(
                  phoneToHashMap.values,
                );
          }
        }

        if (contact.emails != null) {
          for (final email in contact.emails!) {
            final hash = email.calculateHashWithAlgorithmSha256(
              pepper: hashDetails.lookupPepper!,
            );

            emailToHashMap.putIfAbsent(email.address, () => hash);

            hashToContactIdMappings.putIfAbsent(contact.id, () => []).addAll(
                  emailToHashMap.values,
                );
          }
        }

        final updatedContact = updateContactWithHashes(
          contact,
          phoneToHashMap,
          emailToHashMap,
        );

        contactIdToHashMap.putIfAbsent(contact.id, () => updatedContact);
      }

      final contactToHashMap =
          hashToContactIdMappings.values.expand((hash) => hash).toSet();

      if (contactToHashMap.isEmpty) {
        return const Left(FederationIdentityCalculationHashesEmpty());
      }

      final lookupMxidResponse =
          await federationIdentityLookupRepository.lookupMxid(
        request: FederationLookupMxidRequest(
          addresses: contactToHashMap.toSet(),
          algorithm: hashDetails.algorithms?.firstOrNull,
          pepper: hashDetails.lookupPepper,
        ),
        token: registerResponse.token!,
      );

      if (lookupMxidResponse.mappings == null) {
        return const Left(
          FederationIdentityLookupFailure(exception: 'No mappings found'),
        );
      }

      for (final mapping in lookupMxidResponse.mappings!.entries) {
        final contactId = hashToContactIdMappings.entries
            .firstWhereOrNull((entry) => entry.value.contains(mapping.key))
            ?.key;

        final contact = contactIdToHashMap[contactId];
        if (contact != null) {
          final updatedPhoneNumbers = _updatePhoneNumbers(
            contact,
            {
              mapping.key: mapping.value,
            },
          );
          final updatedEmails = _updateEmails(
            contact,
            {
              mapping.key: mapping.value,
            },
          );

          final updatedContact = contact.copyWith(
            phoneNumbers: updatedPhoneNumbers,
            emails: updatedEmails,
          );

          newContacts.putIfAbsent(contact.id, () => updatedContact);
        }
      }

      return Right(
        FederationIdentityLookupSuccess(
          newContacts: newContacts,
        ),
      );
    } catch (e) {
      return Left(FederationIdentityLookupFailure(exception: e));
    }
  }

  FederationContact updateContactWithHashes(
    FederationContact contact,
    Map<String, String> phoneToHashMap,
    Map<String, String> emailToHashMap,
  ) {
    final updatedPhoneNumbers = <FederationPhone>{};
    final updatedEmails = <FederationEmail>{};

    for (final phoneNumber in contact.phoneNumbers!) {
      final hashes = phoneToHashMap[phoneNumber.number];
      if (hashes != null) {
        final updatedPhoneNumber = phoneNumber.copyWith(
          thirdPartyIdToHashMap: phoneToHashMap,
        );
        updatedPhoneNumbers.add(updatedPhoneNumber);
      }
    }

    for (final email in contact.emails!) {
      final hashes = emailToHashMap[email.address];

      if (hashes != null) {
        final emailUpdated = email.copyWith(
          thirdPartyIdToHashMap: emailToHashMap,
        );
        updatedEmails.add(emailUpdated);
      }
    }

    return contact.copyWith(
      phoneNumbers: updatedPhoneNumbers,
      emails: updatedEmails,
    );
  }

  Set<FederationPhone> _updatePhoneNumbers(
    FederationContact contact,
    Map<String, String> mappings,
  ) {
    final updatedPhoneNumbers = <FederationPhone>{};
    for (final phoneNumber in contact.phoneNumbers!) {
      final thirdPartyIdToHashMap = phoneNumber.thirdPartyIdToHashMap ?? {};

      for (final matrixId in thirdPartyIdToHashMap.values) {
        if (mappings.keys.contains(matrixId)) {
          final updatedPhoneNumber = phoneNumber.copyWith(
            matrixId: mappings.values.first,
          );
          updatedPhoneNumbers.add(updatedPhoneNumber);
        }
      }
    }
    return updatedPhoneNumbers.isNotEmpty
        ? updatedPhoneNumbers
        : contact.phoneNumbers!;
  }

  Set<FederationEmail> _updateEmails(
    FederationContact contact,
    Map<String, String> mappings,
  ) {
    final updatedEmails = <FederationEmail>{};
    for (final email in contact.emails!) {
      final thirdPartyIdToHashMap = email.thirdPartyIdToHashMap ?? {};
      for (final matrixId in thirdPartyIdToHashMap.values) {
        if (mappings.keys.contains(matrixId)) {
          final updatedEmail = email.copyWith(
            matrixId: mappings.values.first,
          );
          updatedEmails.add(updatedEmail);
        }
      }
    }
    return updatedEmails.isNotEmpty ? updatedEmails : contact.emails!;
  }
}
