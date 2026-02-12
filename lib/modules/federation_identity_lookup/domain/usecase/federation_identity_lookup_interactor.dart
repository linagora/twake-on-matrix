import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/exceptions/federation_identity_lookup_exceptions.dart';
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
      if (arguments.federationUrl.isEmpty) {
        return const Left(NoFederationIdentityURL());
      }

      final registerResponse = await federationIdentityLookupRepository
          .register(tokenInformation: arguments.tokenInformation);
      if (registerResponse.token == null || registerResponse.token!.isEmpty) {
        return Left(
          FederationIdentityRegisterAccountFailure(
            identityServer: arguments.federationUrl,
          ),
        );
      }

      final hashDetails = await federationIdentityLookupRepository
          .getHashDetails(registeredToken: registerResponse.token!);
      if (hashDetails.lookupPepper == null || hashDetails.algorithms == null) {
        return const Left(FederationIdentityGetHashDetailsFailure());
      }

      final Map<String, FederationContact> contactIdToHashMap = {};

      final Map<String, List<String>> contactIdToHashesMap = {};

      for (final contact in arguments.contactMaps.values) {
        final phoneToHashMap = <String, List<String>>{};

        final emailToHashMap = <String, List<String>>{};
        if (hashDetails.algorithms!.isEmpty) {
          return const Left(FederationIdentityGetHashDetailsFailure());
        }

        if (contact.phoneNumbers != null) {
          for (final phone in contact.phoneNumbers!) {
            final hashes = phone.calculateHashUsingAllPeppers(
              lookupPepper: hashDetails.lookupPepper,
              altLookupPeppers: hashDetails.altLookupPeppers,
              algorithms: hashDetails.algorithms,
            );

            phoneToHashMap.putIfAbsent(phone.number, () => []).addAll(hashes);

            contactIdToHashesMap
                .putIfAbsent(contact.id, () => [])
                .addAll(phoneToHashMap.values.expand((e) => e));
          }
        }

        if (contact.emails != null) {
          for (final email in contact.emails!) {
            final hashes = email.calculateHashUsingAllPeppers(
              lookupPepper: hashDetails.lookupPepper,
              altLookupPeppers: hashDetails.altLookupPeppers,
              algorithms: hashDetails.algorithms,
            );

            emailToHashMap.putIfAbsent(email.address, () => []).addAll(hashes);

            contactIdToHashesMap
                .putIfAbsent(contact.id, () => [])
                .addAll(emailToHashMap.values.expand((e) => e));
          }
        }

        final updatedContact = updateContactWithHashes(
          contact,
          phoneToHashMap,
          emailToHashMap,
        );

        contactIdToHashMap.putIfAbsent(contact.id, () => updatedContact);
      }

      final contactToHashMap = contactIdToHashesMap.values
          .expand((hash) => hash)
          .toSet();

      if (contactToHashMap.isEmpty) {
        return const Left(FederationIdentityCalculationHashesEmpty());
      }

      final lookupMxidResponse = await federationIdentityLookupRepository
          .lookupMxid(
            request: FederationLookupMxidRequest(
              addresses: contactToHashMap.toSet(),
              algorithm: hashDetails.algorithms?.firstOrNull,
              pepper: hashDetails.lookupPepper,
            ),
            registeredToken: registerResponse.token!,
          );

      if (lookupMxidResponse.mappings == null ||
          lookupMxidResponse.mappings!.isEmpty) {
        return Left(
          FederationIdentityLookupFailure(
            exception: LookUpFederationIdentityNotFoundException(
              'No mappings found',
            ),
          ),
        );
      }

      for (final mapping in lookupMxidResponse.mappings!.entries) {
        final contactId = contactIdToHashesMap.entries
            .firstWhereOrNull((entry) => entry.value.contains(mapping.key))
            ?.key;

        final contact = contactIdToHashMap[contactId];
        if (contact != null) {
          final updatedPhoneNumber = _updatePhoneNumber(contact, {
            mapping.key: mapping.value,
          });
          final updatedEmails = _updateEmail(contact, {
            mapping.key: mapping.value,
          });

          final updatedContact = contact.copyWith(
            phoneNumbers: replacePhoneNumber(
              contact.phoneNumbers,
              updatedPhoneNumber,
            ),
            emails: replaceEmail(contact.emails, updatedEmails),
          );

          contactIdToHashMap[contact.id] = updatedContact;
        }
      }

      return Right(
        FederationIdentityLookupSuccess(newContacts: contactIdToHashMap),
      );
    } catch (e) {
      return Left(FederationIdentityLookupFailure(exception: e));
    }
  }

  FederationContact updateContactWithHashes(
    FederationContact contact,
    Map<String, List<String>> phoneToHashMap,
    Map<String, List<String>> emailToHashMap,
  ) {
    final updatedPhoneNumbers = <FederationPhone>{};
    final updatedEmails = <FederationEmail>{};

    if (contact.phoneNumbers != null) {
      for (final phoneNumber in contact.phoneNumbers!) {
        final phone = phoneToHashMap.keys.firstWhereOrNull(
          (number) => number == phoneNumber.number,
        );
        if (phone != null) {
          final phoneNumberUpdated = phoneNumber.copyWith(
            thirdPartyIdToHashMap: {phoneNumber.number: phoneToHashMap[phone]!},
          );
          updatedPhoneNumbers.add(phoneNumberUpdated);
        }
      }
    }

    if (contact.emails != null) {
      for (final email in contact.emails!) {
        final address = emailToHashMap.keys.firstWhereOrNull(
          (address) => address == email.address,
        );

        if (address != null) {
          final emailUpdated = email.copyWith(
            thirdPartyIdToHashMap: {email.address: emailToHashMap[address]!},
          );
          updatedEmails.add(emailUpdated);
        }
      }
    }

    return contact.copyWith(
      phoneNumbers: updatedPhoneNumbers,
      emails: updatedEmails,
    );
  }

  FederationPhone? _updatePhoneNumber(
    FederationContact contact,
    Map<String, String> mappings,
  ) {
    for (final phoneNumber in contact.phoneNumbers!) {
      final thirdPartyIdToHashMap = phoneNumber.thirdPartyIdToHashMap ?? {};

      for (final mappingHash in thirdPartyIdToHashMap.values) {
        final foundHash = mappingHash.firstWhereOrNull(
          (hash) =>
              mappings.keys.firstWhereOrNull((key) => key == hash) != null,
        );
        if (foundHash != null) {
          final updatedPhoneNumber = phoneNumber.copyWith(
            matrixId: mappings[foundHash],
          );
          return updatedPhoneNumber;
        }
      }
    }

    return null;
  }

  FederationEmail? _updateEmail(
    FederationContact contact,
    Map<String, String> mappings,
  ) {
    for (final email in contact.emails!) {
      final thirdPartyIdToHashMap = email.thirdPartyIdToHashMap ?? {};
      for (final mappingHash in thirdPartyIdToHashMap.values) {
        final foundHash = mappingHash.firstWhereOrNull(
          (hash) =>
              mappings.keys.firstWhereOrNull((key) => key == hash) != null,
        );
        if (foundHash != null) {
          final updatedEmail = email.copyWith(matrixId: mappings[foundHash]);
          return updatedEmail;
        }
      }
    }
    return null;
  }

  Set<FederationPhone> replacePhoneNumber(
    Set<FederationPhone>? phoneNumbers,
    FederationPhone? updatedPhoneNumber,
  ) {
    if (phoneNumbers == null || updatedPhoneNumber == null) {
      return phoneNumbers ?? {};
    }

    return phoneNumbers.map((phone) {
      if (phone.number == updatedPhoneNumber.number) {
        return updatedPhoneNumber;
      }
      return phone;
    }).toSet();
  }

  Set<FederationEmail> replaceEmail(
    Set<FederationEmail>? emails,
    FederationEmail? updatedEmail,
  ) {
    if (emails == null || updatedEmail == null) {
      return emails ?? {};
    }

    return emails.map((email) {
      if (email.address == updatedEmail.address) {
        return updatedEmail;
      }
      return email;
    }).toSet();
  }
}
