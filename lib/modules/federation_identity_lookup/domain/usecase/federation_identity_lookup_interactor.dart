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

      if (hashDetails.lookupPepper == null || hashDetails.algorithms == null) {
        yield const Left(FederationIdentityGetHashDetailsFailure());
      }

      final contactIdToHashMap = {
        for (final contact in arguments.contactMaps.values) contact.id: contact,
      };

      final Map<String, FederationContact> newContacts = {};

      final phoneToHashMap = <String, String>{};

      final emailToHashMap = <String, String>{};

      for (final contact in arguments.contactMaps.values) {
        if (hashDetails.algorithms!.isEmpty) {
          yield const Left(FederationIdentityGetHashDetailsFailure());
        }

        if (contact.phoneNumbers != null) {
          for (final phone in contact.phoneNumbers!) {
            final hash = phone.calculateHashWithAlgorithmSha256(
              pepper: hashDetails.lookupPepper!,
            );
            phoneToHashMap.putIfAbsent(phone.number, () => hash);
          }
        }

        if (contact.emails != null) {
          for (final email in contact.emails!) {
            final hash = email.calculateHashWithAlgorithmSha256(
              pepper: hashDetails.lookupPepper!,
            );

            emailToHashMap.putIfAbsent(email.address, () => hash);
          }
        }

        final updatedContact = updateContactWithHashes(
          contact,
          phoneToHashMap,
          emailToHashMap,
        );

        contactIdToHashMap.putIfAbsent(contact.id, () => updatedContact);
      }

      final contactToHashMap = {
        ...phoneToHashMap,
        ...emailToHashMap,
      };

      if (contactToHashMap.values.isEmpty) {
        yield const Left(FederationIdentityCalculationHashesEmpty());
      }

      final lookupMxidResponse =
          await federationIdentityLookupRepository.lookupMxid(
        request: FederationLookupMxidRequest(
          addresses: contactToHashMap.values.toSet(),
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

      for (final mapping in lookupMxidResponse.mappings!.entries) {
        final contact = contactIdToHashMap[mapping.key];
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

      yield Right(
        FederationIdentityLookupSuccess(
          newContacts: newContacts,
        ),
      );
    } catch (e) {
      yield Left(FederationIdentityLookupFailure(exception: e));
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

      if (thirdPartyIdToHashMap.values.contains(mappings.values.toString())) {
        final updatePhoneNumber = phoneNumber.copyWith(
          matrixId: mappings.keys.toString(),
        );
        updatedPhoneNumbers.add(updatePhoneNumber);
      }
    }
    return updatedPhoneNumbers;
  }

  Set<FederationEmail> _updateEmails(
    FederationContact contact,
    Map<String, String> mappings,
  ) {
    final updatedEmails = <FederationEmail>{};
    for (final email in contact.emails!) {
      final thirdPartyIdToHashMap = email.thirdPartyIdToHashMap ?? {};
      if (thirdPartyIdToHashMap.values.contains(mappings.values.toString())) {
        final updatedEmail = email.copyWith(
          matrixId: mappings.keys.toString(),
        );
        updatedEmails.add(updatedEmail);
      }
    }
    return updatedEmails;
  }
}
