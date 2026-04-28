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

/// Setup state produced by the request-token → register → hash-details
/// sequence for a single server URL.
class _FederationServerSession {
  final String url;
  final FederationRegisterResponse registerToken;
  final FederationHashDetailsResponse hashDetails;

  const _FederationServerSession({
    required this.url,
    required this.registerToken,
    required this.hashDetails,
  });
}

/// Result of processing all federation sessions for a single chunk.
class _ChunkSessionResult {
  final Set<Contact> fromMappings;
  final Set<Contact> fromThirdParty;

  const _ChunkSessionResult({
    required this.fromMappings,
    required this.fromThirdParty,
  });
}

/// Hashed representation of a contact chunk tied to one server's pepper and
/// algorithms (which may differ between servers).
class _ContactHashing {
  final Map<String, List<String>> hashToContactIdMappings;
  final Map<String, Contact> contactIdToHashMap;

  const _ContactHashing({
    required this.hashToContactIdMappings,
    required this.contactIdToHashMap,
  });
}

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
          'FederationLookUpPhonebookContactInteractor::execute: fetchContacts',
          e,
        );
        yield Left(GetPhoneBookContactFailure(exception: e));
        return;
      }

      FederationTokenInformation? sharedTokenInfo;
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
                sharedTokenInfo = success.tokenInformation;
              }
            }),
          );

      if (sharedTokenInfo == null) {
        Logs().e(
          'FederationLookUpPhonebookContactInteractor::execute: '
          'shared token request returned null',
        );
        yield Left(
          RequestTokenFailure(exception: 'Token is empty', contacts: contacts),
        );
        return;
      }

      Failure? firstSetupFailure;
      final List<_FederationServerSession> sessions = [];

      for (final url in argument.federationUrls) {
        final session = await _setupSession(
          federationUrl: url,
          tokenInfo: sharedTokenInfo!,
          contacts: contacts,
          firstFailureRef: (f) => firstSetupFailure ??= f,
        );
        if (session != null) sessions.add(session);
      }

      // The identity server session is set up upfront. It is only queried
      // per-chunk when its URL has not yet appeared in any third_party_mappings
      // response (tracked globally across all chunks).
      _FederationServerSession? identitySession;
      if (argument.identityServerUrl != null) {
        identitySession = await _setupSession(
          federationUrl: argument.identityServerUrl!,
          tokenInfo: sharedTokenInfo!,
          contacts: contacts,
          firstFailureRef: (_) {},
        );
      }

      if (sessions.isEmpty && identitySession == null) {
        yield Left(
          firstSetupFailure ??
              RequestTokenFailure(
                exception: 'No federation servers available',
                contacts: contacts,
              ),
        );
        return;
      }

      final Set<String> globalSeenThirdPartyUrls = {};
      final chunks = contacts.slices(lookupChunkSize).toList();

      for (final chunkContacts in chunks) {
        try {
          _ChunkSessionResult? sessionsResult;
          Object? federationChunkError;
          StackTrace? federationChunkStackTrace;
          try {
            sessionsResult = await _processFederationSessionsForChunk(
              sessions: sessions,
              chunkContacts: chunkContacts,
              argument: argument,
              globalSeenThirdPartyUrls: globalSeenThirdPartyUrls,
              tokenInfo: sharedTokenInfo!,
            );
          } catch (e, s) {
            federationChunkError = e;
            federationChunkStackTrace = s;
          }

          final contactsFromIdentity = identitySession != null
              ? await _processIdentityServerForChunk(
                  identitySession: identitySession,
                  chunkContacts: chunkContacts,
                  globalSeenThirdPartyUrls: globalSeenThirdPartyUrls,
                )
              : const <Contact>{};

          if (federationChunkError != null && contactsFromIdentity.isEmpty) {
            Error.throwWithStackTrace(
              federationChunkError,
              federationChunkStackTrace!,
            );
          }

          final combinedContacts = chunkContacts.toSet().combineContacts(
            contactsFromMappings: {
              ...sessionsResult?.fromMappings ?? {},
              ...contactsFromIdentity,
            },
            contactsFromThirdParty: sessionsResult?.fromThirdParty ?? {},
          );

          await _storeContactsInHive(
            contacts: combinedContacts,
            userId: argument.withMxId,
          );

          updatedContact.addAll(combinedContacts);
          progress++;

          yield Right(
            GetPhonebookContactsSuccess(
              progress: (progress / chunks.length * 100).toInt(),
              contacts: updatedContact.toList(),
            ),
          );
        } catch (e) {
          Logs().e(
            'FederationLookUpPhonebookContactInteractor::execute: '
            'chunk exception',
            e,
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
    }

    await _sharedPreferencesContactCacheManager
        .deleteChunkFederationLookUpError();
    yield Right(
      GetPhonebookContactsSuccess(
        progress: 100,
        contacts: updatedContact.toList(),
      ),
    );
  }

  /// Processes all federation [sessions] for a single [chunkContacts] slice.
  /// Mutates [globalSeenThirdPartyUrls] with any third-party server URLs found.
  /// Returns the collected direct and third-party contacts.
  Future<_ChunkSessionResult> _processFederationSessionsForChunk({
    required List<_FederationServerSession> sessions,
    required List<Contact> chunkContacts,
    required FederationLookUpArgument argument,
    required Set<String> globalSeenThirdPartyUrls,
    required FederationTokenInformation tokenInfo,
  }) async {
    final Set<Contact> fromMappings = {};
    final Set<Contact> fromThirdParty = {};

    Object? firstLookupError;
    StackTrace? firstLookupStackTrace;
    var successfulLookups = 0;

    for (final session in sessions) {
      final hashing = _hashContacts(chunkContacts, session.hashDetails);
      late final FederationLookupMxidResponse response;
      try {
        response = await _identityLookupManager.lookupMxid(
          federationUrl: session.url,
          request: FederationLookupMxidRequest(
            addresses: hashing.hashToContactIdMappings.values
                .expand((h) => h)
                .toSet(),
            algorithm: session.hashDetails.algorithms?.firstOrNull,
            pepper: session.hashDetails.lookupPepper,
          ),
          registeredToken: session.registerToken.token!,
        );
        successfulLookups++;
      } catch (e, s) {
        if (firstLookupError == null) {
          firstLookupError = e;
          firstLookupStackTrace = s;
        }
        Logs().e(
          'FederationLookUpPhonebookContactInteractor::_processFederationSessionsForChunk: '
          'lookup failed for ${session.url}',
          e,
        );
        continue;
      }

      _collectMappings(
        response: response,
        hashing: hashing,
        target: fromMappings,
      );

      if (response.thirdPartyMappings != null &&
          response.thirdPartyMappings!.isNotEmpty) {
        globalSeenThirdPartyUrls.addAll(
          response.thirdPartyMappings!.keys.map(
            (k) => _normalizeUrl(k.convertToHttps),
          ),
        );
        try {
          final thirdPartyContacts = await _handleThirdPartyMappings(
            thirdPartyToHashes: response.thirdPartyMappings!,
            hashToContactIdMappings: hashing.hashToContactIdMappings,
            newContacts: hashing.contactIdToHashMap.values.toList(),
            argument: argument,
            tokenInfo: tokenInfo,
          );
          fromThirdParty.addAll(thirdPartyContacts);
        } catch (e) {
          Logs().d(
            'FederationLookUpPhonebookContactInteractor::_processFederationSessionsForChunk: '
            'third party mappings failed for ${session.url}',
          );
        }
      }
    }

    if (sessions.isNotEmpty &&
        successfulLookups == 0 &&
        firstLookupError != null) {
      Error.throwWithStackTrace(firstLookupError, firstLookupStackTrace!);
    }

    return _ChunkSessionResult(
      fromMappings: fromMappings,
      fromThirdParty: fromThirdParty,
    );
  }

  /// Queries the identity server for [chunkContacts] unless its URL is already
  /// covered by [globalSeenThirdPartyUrls]. Returns the matched contacts.
  Future<Set<Contact>> _processIdentityServerForChunk({
    required _FederationServerSession identitySession,
    required List<Contact> chunkContacts,
    required Set<String> globalSeenThirdPartyUrls,
  }) async {
    if (globalSeenThirdPartyUrls.contains(_normalizeUrl(identitySession.url))) {
      return const {};
    }
    final Set<Contact> result = {};
    try {
      final hashing = _hashContacts(chunkContacts, identitySession.hashDetails);
      final idResponse = await _identityLookupManager.lookupMxid(
        federationUrl: identitySession.url,
        request: FederationLookupMxidRequest(
          addresses: hashing.hashToContactIdMappings.values
              .expand((h) => h)
              .toSet(),
          algorithm: identitySession.hashDetails.algorithms?.firstOrNull,
          pepper: identitySession.hashDetails.lookupPepper,
        ),
        registeredToken: identitySession.registerToken.token!,
      );
      _collectMappings(response: idResponse, hashing: hashing, target: result);
    } catch (e) {
      Logs().e(
        'FederationLookUpPhonebookContactInteractor::_processIdentityServerForChunk: '
        'identity server lookup failed',
        e,
      );
    }
    return result;
  }

  /// Runs register → hash-details for [federationUrl] using a pre-fetched
  /// [tokenInfo]. Returns null if any step fails; [firstFailureRef] receives
  /// the first [Failure] encountered.
  Future<_FederationServerSession?> _setupSession({
    required String federationUrl,
    required FederationTokenInformation tokenInfo,
    required List<Contact> contacts,
    required void Function(Failure) firstFailureRef,
  }) async {
    FederationRegisterResponse? registerToken;
    try {
      final res = await _identityLookupManager.register(
        federationUrl: federationUrl,
        tokenInformation: tokenInfo,
      );
      if (res.token == null || res.token!.isEmpty) {
        firstFailureRef(
          RegisterTokenFailure(exception: 'Token is empty', contacts: contacts),
        );
        return null;
      }
      registerToken = res;
    } catch (e) {
      Logs().e(
        'FederationLookUpPhonebookContactInteractor::_setupSession: '
        'register failed for $federationUrl',
        e,
      );
      firstFailureRef(
        RegisterTokenFailure(exception: 'Register failed', contacts: contacts),
      );
      return null;
    }

    try {
      final hashDetails = await _identityLookupManager.getHashDetails(
        federationUrl: federationUrl,
        registeredToken: registerToken.token!,
      );

      if (hashDetails.lookupPepper == null ||
          hashDetails.lookupPepper!.isEmpty ||
          hashDetails.algorithms == null ||
          hashDetails.algorithms!.isEmpty) {
        firstFailureRef(
          const GetHashDetailsFailure(exception: 'Hash details is empty'),
        );
        return null;
      }

      return _FederationServerSession(
        url: federationUrl,
        registerToken: registerToken,
        hashDetails: hashDetails,
      );
    } catch (e) {
      Logs().e(
        'FederationLookUpPhonebookContactInteractor::_setupSession: '
        'hash details failed for $federationUrl',
        e,
      );
      firstFailureRef(GetHashDetailsFailure(exception: e));
      return null;
    }
  }

  _ContactHashing _hashContacts(
    List<Contact> chunkContacts,
    FederationHashDetailsResponse hashDetails,
  ) {
    final Map<String, List<String>> hashToContactIdMappings = {};
    final Map<String, Contact> contactIdToHashMap = {};

    for (final contact in chunkContacts) {
      final phoneToHashMap = <String, List<String>>{};
      final emailToHashMap = <String, List<String>>{};

      if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
        phoneToHashMap.addAll(
          contact.phoneNumbers!.calculateHashesForPhoneNumbers(hashDetails),
        );
        hashToContactIdMappings
            .putIfAbsent(contact.id, () => [])
            .addAll(phoneToHashMap.values.expand((h) => h));
      }

      if (contact.emails != null && contact.emails!.isNotEmpty) {
        emailToHashMap.addAll(
          contact.emails!.calculateHashesForEmails(hashDetails),
        );
        hashToContactIdMappings
            .putIfAbsent(contact.id, () => [])
            .addAll(emailToHashMap.values.expand((h) => h));
      }

      contactIdToHashMap[contact.id] = contact.updateContactWithHashes(
        phoneToHashMap: phoneToHashMap,
        emailToHashMap: emailToHashMap,
      );
    }

    return _ContactHashing(
      hashToContactIdMappings: hashToContactIdMappings,
      contactIdToHashMap: contactIdToHashMap,
    );
  }

  void _collectMappings({
    required FederationLookupMxidResponse response,
    required _ContactHashing hashing,
    required Set<Contact> target,
  }) {
    if (response.mappings == null || response.mappings!.isEmpty) return;
    try {
      final updated = hashing.contactIdToHashMap.values
          .toSet()
          .handleLookupMappings(
            mappings: response.mappings!,
            hashToContactIdMappings: hashing.hashToContactIdMappings,
          );
      target.addAll(updated);
    } catch (e) {
      Logs().e(
        'FederationLookUpPhonebookContactInteractor::_collectMappings: '
        'failed',
        e,
      );
    }
  }

  Future<List<Contact>> _handleThirdPartyMappings({
    required Map<String, Set<String>> thirdPartyToHashes,
    required Map<String, List<String>> hashToContactIdMappings,
    required List<Contact> newContacts,
    required FederationLookUpArgument argument,
    required FederationTokenInformation tokenInfo,
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
        if (contact == null) continue;
        contactsNeedToCalculate[contact.id] = contact;
      }

      final arguments = FederationArguments(
        federationUrl: server.convertToHttps,
        tokenInformation: tokenInfo,
        contactMaps: contactsNeedToCalculate.toFederationContactMap(),
      );
      final manager = getIt.get<FederationIdentityLookupManager>();
      final result = await manager.execute(arguments: arguments);
      result.fold(
        (failure) {
          Logs().e(
            'FederationLookUpPhonebookContactInteractor::_handleThirdPartyMappings: '
            'failure: $failure',
          );
        },
        (success) {
          Logs().d(
            'FederationLookUpPhonebookContactInteractor::_handleThirdPartyMappings: '
            'success: $success',
          );
          if (success is FederationIdentityLookupSuccess) {
            updatedContact.addAll(success.newContacts.toContacts());
          }
        },
      );
    }
    return updatedContact;
  }

  String _normalizeUrl(String url) {
    final trimmed = url.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;
    return '${uri.scheme}://${uri.host}:${uri.port}';
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
        'FederationLookUpPhonebookContactInteractor::_storeContactsInHive: $e',
      );
    }
  }
}
