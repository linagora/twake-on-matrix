import 'package:dartz/dartz.dart';
import 'package:matrix/matrix.dart' hide Contact;
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:twake_chat/domain/app_state/contact/post_address_book_state.dart';
import 'package:twake_chat/domain/app_state/contact/try_get_synced_phone_book_contact_state.dart';
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';
import 'package:twake_chat/data/model/federation_server/federation_configuration.dart';
import 'package:twake_chat/domain/exception/federation_configuration_not_found.dart';
import 'package:twake_chat/domain/model/contact/contact.dart';
import 'package:twake_chat/domain/model/extensions/contact/contact_extension.dart';
import 'package:twake_chat/domain/usecase/contacts/federation_look_up_argument.dart';
import 'package:twake_chat/domain/usecase/contacts/federation_look_up_phonebook_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/try_get_synced_phone_book_contact_interactor.dart';
import 'package:twake_chat/domain/usecase/contacts/twake_look_up_argument.dart';
import 'package:twake_chat/domain/usecase/contacts/twake_look_up_phonebook_contact_interactor.dart';

/// Endpoints and credentials of the account being resolved, read at call time
/// because the legacy network interceptors are reconfigured on account switch.
class PhonebookLookupEndpoints {
  const PhonebookLookupEndpoints({
    required this.homeServerUrl,
    required this.identityServerUrl,
    required this.accessToken,
  });

  final String Function() homeServerUrl;
  final String Function() identityServerUrl;
  final String Function() accessToken;
}

/// Phonebook lookup (formerly driven by the legacy `ContactsManager`): decide
/// whether the stored resolution is still valid, otherwise run the federation
/// (or Twake) lookup, then upload the resolved contacts to the ToM address book
/// and tell the other devices.
class PhonebookResolverImpl implements PhonebookResolver {
  PhonebookResolverImpl({
    required TryGetSyncedPhoneBookContactInteractor tryGetSynced,
    required FederationLookUpPhonebookContactInteractor federationLookUp,
    required TwakeLookupPhonebookContactInteractor twakeLookUp,
    required PostAddressBookInteractor postAddressBook,
    required Future<FederationConfigurations> Function(String userId)
    federationConfigurations,
    required PhonebookLookupEndpoints endpoints,
    required bool uploadsAddressBook,
    this.onPartialFailure,
    this.onAddressBookUploaded,
  }) : _tryGetSynced = tryGetSynced,
       _federationLookUp = federationLookUp,
       _twakeLookUp = twakeLookUp,
       _postAddressBook = postAddressBook,
       _federationConfigurations = federationConfigurations,
       _endpoints = endpoints,
       _uploadsAddressBook = uploadsAddressBook;

  static const int _lookupChunkSize = 10;

  final TryGetSyncedPhoneBookContactInteractor _tryGetSynced;
  final FederationLookUpPhonebookContactInteractor _federationLookUp;
  final TwakeLookupPhonebookContactInteractor _twakeLookUp;
  final PostAddressBookInteractor _postAddressBook;
  final Future<FederationConfigurations> Function(String userId)
  _federationConfigurations;
  final PhonebookLookupEndpoints _endpoints;

  /// The address book is only uploaded from mobile (the web has no phonebook).
  final bool _uploadsAddressBook;

  /// Some chunks of the lookup failed: the user should be told.
  final void Function()? onPartialFailure;

  /// The resolved contacts reached the ToM address book.
  final Future<void> Function()? onAddressBookUploaded;

  Future<void>? _running;
  int _generation = 0;

  @override
  Future<void> resolve(String userId) =>
      _running ??= _resolve(userId).whenComplete(() => _running = null);

  @override
  Future<void> cancel() async {
    _generation++;
  }

  Future<void> _resolve(String userId) async {
    final generation = _generation;
    try {
      if (!await _needsLookup(userId)) return;
      await _lookUp(userId, generation);
    } catch (exception, stackTrace) {
      Logs().e('PhonebookResolverImpl::resolve', exception, stackTrace);
    }
  }

  /// Hive already holds a resolution without error and the vault is not due
  /// for a new sync: keep it. Any other outcome triggers a lookup.
  Future<bool> _needsLookup(String userId) async {
    final state = await _tryGetSynced.execute(userId: userId);
    return state.fold(
      (_) => true,
      (success) =>
          success is GetSyncedPhoneBookContactSuccessState &&
          success.timeAvailableForSyncVault,
    );
  }

  Future<void> _lookUp(String userId, int generation) async {
    try {
      final configurations = await _federationConfigurations(userId);
      if (!configurations.fedServerInformation.hasBaseUrls) {
        await _twakeLookUpContacts(generation);
        return;
      }
      await _consume(
        _federationLookUp.execute(
          lookupChunkSize: _lookupChunkSize,
          argument: FederationLookUpArgument(
            homeServerUrl: _endpoints.homeServerUrl(),
            federationUrls:
                configurations.fedServerInformation.baseUrls
                    ?.map((url) => url.toString())
                    .toList() ??
                const <String>[],
            identityServerUrl: configurations.identityServerInformation?.baseUrl
                .toString(),
            withMxId: userId,
            withAccessToken: _endpoints.accessToken(),
          ),
        ),
        generation,
      );
    } on FederationConfigurationNotFound {
      await _twakeLookUpContacts(generation);
    }
  }

  Future<void> _twakeLookUpContacts(int generation) => _consume(
    _twakeLookUp.execute(
      argument: TwakeLookUpArgument(
        homeServerUrl: _endpoints.identityServerUrl(),
        withAccessToken: _endpoints.accessToken(),
      ),
    ),
    generation,
  );

  Future<void> _consume(
    Stream<Either<Failure, Success>> states,
    int generation,
  ) async {
    await for (final state in states) {
      if (generation != _generation) return;
      await state.fold(_onFailure, _onSuccess);
    }
  }

  Future<void> _onFailure(Failure failure) async {
    Logs().e('PhonebookResolverImpl::lookup failure', failure);
    if (failure is LookUpPhonebookContactPartialFailed) {
      onPartialFailure?.call();
      await _upload(failure.contacts);
    }
  }

  Future<void> _onSuccess(Success success) async {
    if (success is GetPhonebookContactsSuccess && success.progress == 100) {
      await _upload(success.contacts);
    }
  }

  Future<void> _upload(List<Contact> contacts) async {
    if (!_uploadsAddressBook) return;
    final state = await _postAddressBook
        .execute(addressBooks: contacts.toSet().toAddressBooks().toList())
        .last;
    Logs().i('PhonebookResolverImpl::upload', state);
    final uploaded = state.fold(
      (_) => false,
      (success) => success is PostAddressBookSuccessState,
    );
    if (uploaded) await onAddressBookUploaded?.call();
  }
}
