import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/data/network/interceptor/authorization_interceptor.dart';
import 'package:fluffychat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/app_state/contact/get_address_book_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/app_state/contact/post_address_book_state.dart';
import 'package:fluffychat/domain/app_state/contact/try_get_synced_phone_book_contact_state.dart';
import 'package:fluffychat/domain/exception/federation_configuration_not_found.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/repository/federation_configurations_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_argument.dart';
import 'package:fluffychat/domain/usecase/contacts/get_address_book_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_phonebook_contact_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/try_get_synced_phone_book_contact_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_argument.dart';
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_phonebook_contact_interactor.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ContactsManager {
  static const int _lookupChunkSize = 10;

  final GetTomContactsInteractor getTomContactsInteractor =
      getIt.get<GetTomContactsInteractor>();

  final FederationLookUpPhonebookContactInteractor
      federationLookUpPhonebookContactInteractor =
      getIt.get<FederationLookUpPhonebookContactInteractor>();

  final TwakeLookupPhonebookContactInteractor
      twakeLookupPhonebookContactInteractor =
      getIt.get<TwakeLookupPhonebookContactInteractor>();

  final PostAddressBookInteractor postAddressBookInteractor =
      getIt.get<PostAddressBookInteractor>();

  final GetAddressBookInteractor getAddressBookInteractor =
      getIt.get<GetAddressBookInteractor>();

  final TryGetSyncedPhoneBookContactInteractor
      tryGetSyncedPhoneBookContactInteractor =
      getIt.get<TryGetSyncedPhoneBookContactInteractor>();

  StreamSubscription<Either<Failure, Success>>? tomContactsSubscription;

  StreamSubscription<Either<Failure, Success>>?
      federationPhonebookContactsSubscription;

  StreamSubscription<Either<Failure, Success>>?
      twakePhonebookContactsSubscription;

  StreamSubscription<Either<Failure, Success>>? getAddressBookSubscription;

  StreamSubscription<Either<Failure, Success>>? postAddressBookSubscription;

  bool _doNotShowWarningContactsBannerAgain = false;

  bool _doNotShowWarningContactsDialogAgain = false;

  final ValueNotifierCustom<Either<Failure, Success>> _contactsNotifier =
      ValueNotifierCustom(const Right(ContactsInitial()));

  final ValueNotifierCustom<Either<Failure, Success>>
      _phonebookContactsNotifier =
      ValueNotifierCustom(const Right(GetPhonebookContactsInitial()));

  final ValueNotifierCustom<Either<Failure, Success>> _getAddressBookNotifier =
      ValueNotifierCustom(const Right(GetAddressBookInitial()));

  final ValueNotifierCustom<Either<Failure, Success>> _postAddressBookNotifier =
      ValueNotifierCustom(const Right(PostAddressBookInitial()));

  final ValueNotifierCustom<int?> _progressPhoneBookState =
      ValueNotifierCustom(null);

  ValueNotifierCustom<Either<Failure, Success>> getContactsNotifier() =>
      _contactsNotifier;

  ValueNotifierCustom<Either<Failure, Success>>
      getPhonebookContactsNotifier() => _phonebookContactsNotifier;

  ValueNotifierCustom<Either<Failure, Success>> getAddressBookNotifier() =>
      _getAddressBookNotifier;

  ValueNotifierCustom<Either<Failure, Success>> postAddressBookNotifier() =>
      _postAddressBookNotifier;

  ValueNotifierCustom<int?> get progressPhoneBookState =>
      _progressPhoneBookState;

  bool _isSynchronizing = false;

  bool get _isSynchronizedTomContacts =>
      _contactsNotifier.value.getSuccessOrNull<ContactsInitial>() == null;

  bool get isDoNotShowWarningContactsBannerAgain =>
      _doNotShowWarningContactsBannerAgain;

  bool get isDoNotShowWarningContactsDialogAgain =>
      _doNotShowWarningContactsDialogAgain;

  set updateNotShowWarningContactsBannerAgain(bool value) {
    _doNotShowWarningContactsBannerAgain = value;
  }

  set updateNotShowWarningContactsDialogAgain(bool value) {
    _doNotShowWarningContactsDialogAgain = value;
  }

  Future<void> reSyncContacts() async {
    _contactsNotifier.value = const Right(ContactsInitial());
    _phonebookContactsNotifier.value =
        const Right(GetPhonebookContactsInitial());
  }

  /// This method performs the synchronization of all contacts.
  ///
  /// It fetches contacts from many sources: tom, federation or twake then
  /// updates the related notifiers.
  /// The synchronization will not proceed if it is already in progress
  /// or was run before, even if the `forceRun` flag is true.
  /// Otherwise, it checks the `forceRun` flag to determine whether to
  /// start the process.
  ///
  /// Parameters:
  /// - `isAvailableSupportPhonebookContacts`: Indicates whether access
  ///   to phonebook contacts is available.
  ///   For example, a mobile app has access to phonebook contacts,
  ///   whereas a web app does not.
  /// - `forceRun`: A boolean indicating whether to forcefully run
  ///   the synchronization process.
  /// - `withMxId`: A required string representing the Matrix ID to
  ///   be used for synchronization.
  Future<void> initialSynchronizeContacts({
    bool isAvailableSupportPhonebookContacts = false,
    bool forceRun = false,
    required String withMxId,
  }) async {
    Logs().d('ContactsManager::initialSynchronizeContacts');
    if (_isSynchronizing) {
      return;
    }

    if (_isSynchronizedTomContacts && !forceRun) {
      return;
    }

    _isSynchronizing = true;

    await _getAllContacts(
      isAvailableSupportPhonebookContacts: isAvailableSupportPhonebookContacts,
      withMxId: withMxId,
    );
  }

  Future<void> _getAllContacts({
    bool isAvailableSupportPhonebookContacts = false,
    required String withMxId,
  }) async {
    tomContactsSubscription = getTomContactsInteractor
        .execute(limit: AppConfig.maxFetchContacts)
        .listen(
      (event) {
        _contactsNotifier.value = event;
      },
    )
      ..onDone(() async {
        Logs().d('ContactsManager::_getAllContacts: done');
        await _lookUpPhonebookContacts(
          isAvailableSupportPhonebookContacts:
              isAvailableSupportPhonebookContacts,
          withMxId: withMxId,
        ).whenComplete(
          () => _isSynchronizing = false,
        );
      })
      ..onError((error) async {
        Logs().d('ContactsManager::_getAllContacts: error - $error');
        await _lookUpPhonebookContacts(
          isAvailableSupportPhonebookContacts:
              isAvailableSupportPhonebookContacts,
          withMxId: withMxId,
        ).whenComplete(
          () => _isSynchronizing = false,
        );
      });
  }

  Future<void> _lookUpPhonebookContacts({
    bool isAvailableSupportPhonebookContacts = false,
    required String withMxId,
  }) async {
    if (!isAvailableSupportPhonebookContacts) {
      _getAddressBook();
      return;
    }

    await _tryGetSyncedPhoneBookContact(withMxId: withMxId);
  }

  Future<void> _tryGetSyncedPhoneBookContact({
    required String withMxId,
  }) async {
    await tryGetSyncedPhoneBookContactInteractor
        .execute(
          userId: withMxId,
        )
        .then(
          (state) => state.fold(
            (failure) {
              _handleLookUpPhonebookContacts(withMxId: withMxId);
            },
            (success) {
              if (success is GetSyncedPhoneBookContactSuccessState) {
                _phonebookContactsNotifier.value = Right(
                  GetPhonebookContactsSuccess(
                    progress: 100,
                    contacts: success.contacts,
                  ),
                );
                if (success.timeAvailableForSyncVault) {
                  _postAddressBookOnMobile(
                    contacts: success.contacts,
                  );
                }
              }
            },
          ),
        );
  }

  void _getAddressBook() {
    getAddressBookSubscription = getAddressBookInteractor.execute().listen(
      (state) {
        _getAddressBookNotifier.value = state;
      },
    );
  }

  Future<void> _handleTwakeLookUpPhoneBookContacts() async {
    final authorizationInterceptor = getIt.get<AuthorizationInterceptor>();

    final identityServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.identityServerUrlInterceptorName,
    );
    twakePhonebookContactsSubscription = twakeLookupPhonebookContactInteractor
        .execute(
      argument: TwakeLookUpArgument(
        homeServerUrl: identityServerUrlInterceptor.baseUrl ?? '',
        withAccessToken: authorizationInterceptor.getAccessToken ?? '',
      ),
    )
        .listen(
      (state) {
        _phonebookContactsNotifier.value = state;
        state.fold(
          (failure) => _handleLookUpFailureState(failure),
          (success) => _handleLookUpSuccessState(success),
        );
      },
    );
  }

  Future<void> _handleLookUpPhonebookContacts({
    required String withMxId,
  }) async {
    try {
      final federationConfigurationRepository =
          getIt.get<FederationConfigurationsRepository>();
      final federationConfigurations = await federationConfigurationRepository
          .getFederationConfigurations(withMxId);
      if (!federationConfigurations.fedServerInformation.hasBaseUrls) {
        await _handleTwakeLookUpPhoneBookContacts();
        return;
      }

      final homeServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
        instanceName: NetworkDI.homeServerUrlInterceptorName,
      );

      final authorizationInterceptor = getIt.get<AuthorizationInterceptor>();

      federationPhonebookContactsSubscription =
          federationLookUpPhonebookContactInteractor
              .execute(
        lookupChunkSize: _lookupChunkSize,
        argument: FederationLookUpArgument(
          homeServerUrl: homeServerUrlInterceptor.baseUrl ?? '',
          federationUrl: federationConfigurations
                  .fedServerInformation.baseUrls?.first
                  .toString() ??
              '',
          withMxId: withMxId,
          withAccessToken: authorizationInterceptor.getAccessToken ?? '',
        ),
      )
              .listen(
        (state) {
          _phonebookContactsNotifier.value = state;
          state.fold(
            (failure) => _handleLookUpFailureState(failure),
            (success) => _handleLookUpSuccessState(success),
          );
        },
      );
    } catch (e) {
      Logs().e('ContactsManager::_handleLookUpPhonebookContacts', e);

      if (e is FederationConfigurationNotFound) {
        await _handleTwakeLookUpPhoneBookContacts();
      }
    }
  }

  void _handleLookUpFailureState(Failure failure) {
    Logs().e('ContactsManager::_handleLookUpFailureState', failure);
    if (failure is LookUpPhonebookContactPartialFailed) {
      _progressPhoneBookState.value = null;
      if (TwakeApp.router.routerDelegate.navigatorKey.currentContext != null) {
        TwakeSnackBar.show(
          TwakeApp.router.routerDelegate.navigatorKey.currentContext!,
          L10n.of(TwakeApp.router.routerDelegate.navigatorKey.currentContext!)!
              .contactLookupFailed,
        );
      }

      _postAddressBookOnMobile(
        contacts: failure.contacts,
      );
    }
  }

  void _handleLookUpSuccessState(Success success) {
    Logs().e('ContactsManager::_handleLookUpSuccessState', success);
    if (success is GetPhonebookContactsLoading) {
      _progressPhoneBookState.value = 0;
    }
    if (success is GetPhonebookContactsSuccess) {
      _progressPhoneBookState.value = success.progress;
      if (success.progress == 100) {
        _postAddressBookOnMobile(
          contacts: success.contacts,
        );
        _progressPhoneBookState.value = null;
      }
    }
  }

  void _postAddressBookOnMobile({
    required List<Contact> contacts,
  }) {
    if (PlatformInfos.isWeb) {
      return;
    }
    postAddressBookSubscription = postAddressBookInteractor
        .execute(
      addressBooks: contacts.toSet().toAddressBooks().toList(),
    )
        .listen(
      (state) {
        Logs().i('ContactsManager::_postAddressBook', state);
        _postAddressBookNotifier.value = state;
      },
    );
  }

  Future<void> cancelAllSubscriptions() async {
    if (tomContactsSubscription != null) {
      await tomContactsSubscription?.cancel();
    }
    if (federationPhonebookContactsSubscription != null) {
      await federationPhonebookContactsSubscription?.cancel();
    }
    if (twakePhonebookContactsSubscription != null) {
      await twakePhonebookContactsSubscription?.cancel();
    }
    if (getAddressBookSubscription != null) {
      await getAddressBookSubscription?.cancel();
    }
    if (postAddressBookSubscription != null) {
      await postAddressBookSubscription?.cancel();
    }
    if (_isSynchronizing) {
      _isSynchronizing = false;
    }
  }

  void synchronizePhonebookContacts({
    required String withMxId,
  }) =>
      _lookUpPhonebookContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: withMxId,
      );
}
