import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/local/contact/enum/chunk_federation_contact_error_enum.dart';
import 'package:fluffychat/data/local/contact/enum/contacts_hive_error_enum.dart';
import 'package:fluffychat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/exception/contacts/twake_lookup_exceptions.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/model/extensions/string_extension.dart';
import 'package:fluffychat/domain/repository/contact/hive_contact_repository.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_argument.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/federation_identity_lookup_manager.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/identity_lookup_manager.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_request.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/state/federation_identity_request_token_state.dart';
import 'package:fluffychat/modules/federation_identity_request_token/manager/federation_identity_request_token_manager.dart';
import 'package:matrix/matrix.dart' hide Contact;

class FederationLookUpPhonebookContactInteractor {
  final PhonebookContactRepository _phonebookContactRepository = getIt
      .get<PhonebookContactRepository>();
  final IdentityLookupManager _identityLookupManager = getIt
      .get<IdentityLookupManager>();
  final FederationIdentityRequestTokenManager
  _federationIdentityRequestTokenManager = getIt
      .get<FederationIdentityRequestTokenManager>();

  final HiveContactRepository _hiveContactRepository = getIt
      .get<HiveContactRepository>();

  final SharedPreferencesContactCacheManager
  _sharedPreferencesContactCacheManager = getIt
      .get<SharedPreferencesContactCacheManager>();

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 10,
    required FederationLookUpArgument argument,
  }) async* {
    Exception? chunkError;
    int progress = 0;
    final Set<Contact> updatedContact = {};

    try {
      yield const Right(GetPhonebookContactsLoading());

      FederationTokenInformation? federationIdentityRequestTokenRes;

      FederationRegisterResponse? federationRegisterToken;

      final List<Contact> contacts = [];

      try {
        final res = await _phonebookContactRepository.fetchContacts();

        if (res.isEmpty) {
          yield const Left(GetPhonebookContactsIsEmpty());
          return;
        }

        contacts.addAll(res);
      } catch (e) {
        Logs().e(
          'FederationLookUpPhonebookContactInteractor::execute: Register: $e',
        );
        yield Left(GetPhoneBookContactFailure(exception: e));
        return;
      }

      await _federationIdentityRequestTokenManager
          .execute(
            federationTokenRequest: FederationTokenRequest(
              homeserverUrl: '${argument.homeServerUrl}/',
              mxid: argument.withMxId,
              accessToken: argument.withAccessToken,
            ),
          )
          .then(
            (state) => state.fold((failure) {}, (success) {
              if (success is FederationIdentityRequestTokenSuccess) {
                federationIdentityRequestTokenRes = success.tokenInformation;
              }
            }),
          );

      Logs().d(
        'FederationLookUpPhonebookContactInteractor::execute: federationIdentityRequestTokenRes: $federationIdentityRequestTokenRes',
      );

      if (federationIdentityRequestTokenRes == null) {
        yield Left(
          RequestTokenFailure(exception: 'Token is empty', contacts: contacts),
        );
        return;
      }

      try {
        final res = await _identityLookupManager.register(
          federationUrl: argument.federationUrl,
          tokenInformation: federationIdentityRequestTokenRes!,
        );
        if (res.token == null || res.token!.isEmpty) {
          yield Left(
            RegisterTokenFailure(
              exception: 'Token is empty',
              contacts: contacts,
            ),
          );
          return;
        }

        federationRegisterToken = res;
      } catch (e) {
        Logs().e(
          'FederationLookUpPhonebookContactInteractor::execute: Register: $e',
        );
        yield Left(
          RegisterTokenFailure(
            exception: 'Register failed',
            contacts: contacts,
          ),
        );
        return;
      }

      Logs().d(
        'FederationLookUpPhonebookContactInteractor::execute: federationRegisterToken: $federationRegisterToken',
      );

      FederationHashDetailsResponse? hashDetails;
      try {
        final res = await _identityLookupManager.getHashDetails(
          federationUrl: argument.federationUrl,
          registeredToken: federationRegisterToken.token!,
        );

        Logs().d(
          'FederationLookUpPhonebookContactInteractor::execute: hashDetails: $hashDetails',
        );

        if (res.lookupPepper?.isEmpty == true &&
            res.algorithms?.isEmpty == true) {
          yield const Left(
            GetHashDetailsFailure(exception: 'Hash details is empty'),
          );
        }

        hashDetails = res;
      } catch (e) {
        Logs().e(
          'FederationLookUpPhonebookContactInteractor::execute: GetHashDetails: $e',
        );
        yield Left(GetHashDetailsFailure(exception: e));
      }

      final contactIdToHashMap = {
        for (final contact in contacts) contact.id: contact,
      };

      final chunks = contactIdToHashMap.values.slices(lookupChunkSize);

      for (final chunkContacts in chunks) {
        final Map<String, List<String>> hashToContactIdMappings = {};
        final Map<String, Contact> contactIdToHashMap = {};
        try {
          for (final chunkContact in chunkContacts) {
            final phoneToHashMap = <String, List<String>>{};
            final emailToHashMap = <String, List<String>>{};
            if (chunkContact.phoneNumbers != null &&
                chunkContact.phoneNumbers!.isNotEmpty) {
              phoneToHashMap.addAll(
                chunkContact.phoneNumbers!.calculateHashesForPhoneNumbers(
                  hashDetails,
                ),
              );

              hashToContactIdMappings
                  .putIfAbsent(chunkContact.id, () => [])
                  .addAll(phoneToHashMap.values.expand((hash) => hash));
            }

            if (chunkContact.emails != null &&
                chunkContact.emails!.isNotEmpty) {
              emailToHashMap.addAll(
                chunkContact.emails!.calculateHashesForEmails(hashDetails),
              );

              hashToContactIdMappings
                  .putIfAbsent(chunkContact.id, () => [])
                  .addAll(emailToHashMap.values.expand((hash) => hash));
            }

            final updatedContact = chunkContact.updateContactWithHashes(
              phoneToHashMap: phoneToHashMap,
              emailToHashMap: emailToHashMap,
            );

            contactIdToHashMap[chunkContact.id] = updatedContact;
          }

          final request = FederationLookupMxidRequest(
            addresses: hashToContactIdMappings.values
                .expand((hash) => hash)
                .toSet(),
            algorithm: hashDetails?.algorithms?.firstOrNull,
            pepper: hashDetails?.lookupPepper,
          );
          FederationLookupMxidResponse? response;
          response = await _identityLookupManager.lookupMxid(
            federationUrl: argument.federationUrl,
            request: request,
            registeredToken: federationRegisterToken.token!,
          );

          final Set<Contact> contactsFromMappings = {};

          final Set<Contact> contactsFromThirdParty = {};

          try {
            if (response.mappings != null && response.mappings!.isNotEmpty) {
              final updatedContact = contactIdToHashMap.values
                  .toSet()
                  .handleLookupMappings(
                    mappings: response.mappings ?? {},
                    hashToContactIdMappings: hashToContactIdMappings,
                  );

              contactsFromMappings.addAll(updatedContact);
            }
          } catch (e) {
            Logs().e(
              'FederationLookUpPhonebookContactInteractor::execute(): handle mappings failed',
              e,
            );
          }

          try {
            if (response.thirdPartyMappings != null &&
                response.thirdPartyMappings!.isNotEmpty) {
              final newContactsThirdParty = await _handleThirdPartyMappings(
                thirdPartyToHashes: response.thirdPartyMappings ?? {},
                hashToContactIdMappings: hashToContactIdMappings,
                newContacts: contactIdToHashMap.values.toList(),
                argument: argument,
              );

              Logs().d(
                'FederationLookUpPhonebookContactInteractor::execute: newContacts: $newContactsThirdParty',
              );

              contactsFromThirdParty.addAll(newContactsThirdParty);
            }
          } catch (e) {
            Logs().d(
              'FederationLookUpPhonebookContactInteractor::execute(): handle third party mappings failed',
            );
          }

          final combinedContacts = chunkContacts.toSet().combineContacts(
            contactsFromMappings: contactsFromMappings,
            contactsFromThirdParty: contactsFromThirdParty,
          );

          await _storeContactsInHive(
            contacts: combinedContacts,
            userId: argument.withMxId,
          );

          updatedContact.addAll(combinedContacts);

          progress++;

          final progressStep = (progress / chunks.length * 100).toInt();

          yield Right(
            GetPhonebookContactsSuccess(
              progress: progressStep,
              contacts: updatedContact.toList(),
            ),
          );
        } catch (e) {
          Logs().e(
            'FederationLookUpPhonebookContactInteractor::execute(): one chunk exception $e',
          );
          progress++;
          updatedContact.addAll(chunkContacts);
          chunkError = TwakeLookupChunkException(e.toString());
        }
      }
    } catch (e) {
      yield Left(
        GetPhonebookContactsFailure(
          exception: e,
          contacts: updatedContact.toList(),
        ),
      );
      return;
    }

    // finalize the process
    if (chunkError != null) {
      await _sharedPreferencesContactCacheManager
          .storeChunkFederationLookUpError(
            ChunkLookUpContactErrorEnum.chunkError,
          );
      yield Left(
        LookUpPhonebookContactPartialFailed(
          exception: chunkError,
          contacts: updatedContact.toList(),
        ),
      );
      return;
    } else {
      await _sharedPreferencesContactCacheManager
          .deleteChunkFederationLookUpError();
      yield Right(
        GetPhonebookContactsSuccess(
          progress: 100,
          contacts: updatedContact.toList(),
        ),
      );
    }
  }

  Future<List<Contact>> _handleThirdPartyMappings({
    required Map<String, Set<String>> thirdPartyToHashes,
    required Map<String, List<String>> hashToContactIdMappings,
    required List<Contact> newContacts,
    required FederationLookUpArgument argument,
  }) async {
    final List<Contact> updatedContact = [];
    for (final server in thirdPartyToHashes.keys) {
      final hashes = thirdPartyToHashes[server]!;
      final Map<String, Contact> contactsNeedToCalculate = {};
      for (final hash in hashes) {
        final contact = newContacts.toSet().findContactWithHash(
          hashToContactIdMappings: hashToContactIdMappings,
          hash: hash,
        );

        if (contact == null) {
          continue;
        }

        contactsNeedToCalculate[contact.id] = contact;
      }

      FederationTokenInformation? federationIdentityRequestTokenRes;

      await _federationIdentityRequestTokenManager
          .execute(
            federationTokenRequest: FederationTokenRequest(
              homeserverUrl: "${argument.homeServerUrl}/",
              mxid: argument.withMxId,
              accessToken: argument.withAccessToken,
            ),
          )
          .then(
            (state) => state.fold((failure) {}, (success) {
              if (success is FederationIdentityRequestTokenSuccess) {
                federationIdentityRequestTokenRes = success.tokenInformation;
              }
            }),
          );

      if (federationIdentityRequestTokenRes == null) {
        return [];
      }

      final arguments = FederationArguments(
        federationUrl: server.convertToHttps,
        tokenInformation: federationIdentityRequestTokenRes!,
        contactMaps: contactsNeedToCalculate.toFederationContactMap(),
      );
      final manager = getIt.get<FederationIdentityLookupManager>();
      final result = await manager.execute(arguments: arguments);
      result.fold(
        (failure) {
          Logs().e(
            'FederationLookUpPhonebookContactInteractor::_handleThirdPartyMappings: failure: $failure',
          );
        },
        (success) {
          Logs().d(
            'FederationLookUpPhonebookContactInteractor::_handleThirdPartyMappings: success: $success',
          );

          if (success is FederationIdentityLookupSuccess) {
            updatedContact.addAll(success.newContacts.toContacts());
          }
        },
      );
    }
    return updatedContact;
  }

  Future<void> _storeContactsInHive({
    required Set<Contact> contacts,
    required String userId,
  }) async {
    try {
      await _hiveContactRepository.saveThirdPartyContactsForUser(
        userId,
        contacts.toList(),
      );
      await _sharedPreferencesContactCacheManager.deleteContactsHiveError();
    } catch (e) {
      _sharedPreferencesContactCacheManager.storeContactsHiveError(
        ContactsHiveErrorEnum.storeError,
      );
      Logs().e(
        'FederationLookUpPhonebookContactInteractor::storeContactsInHive: $e',
      );
    }
  }
}
