import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/data/network/interceptor/authorization_interceptor.dart';
import 'package:fluffychat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_argument.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/phonebook_contact_interactor.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';

class ContactsManager {
  static const int _lookupChunkSize = 10;

  final GetTomContactsInteractor getTomContactsInteractor;

  final PhonebookContactInteractor phonebookContactInteractor;

  bool _doNotShowWarningContactsBannerAgain = false;

  bool _doNotShowWarningContactsDialogAgain = false;

  final ValueNotifierCustom<Either<Failure, Success>> _contactsNotifier =
      ValueNotifierCustom(const Right(ContactsInitial()));

  final ValueNotifierCustom<Either<Failure, Success>>
      _phonebookContactsNotifier =
      ValueNotifierCustom(const Right(GetPhonebookContactsInitial()));

  ContactsManager({
    required this.getTomContactsInteractor,
    required this.phonebookContactInteractor,
  });

  ValueNotifierCustom<Either<Failure, Success>> getContactsNotifier() =>
      _contactsNotifier;

  ValueNotifierCustom<Either<Failure, Success>>
      getPhonebookContactsNotifier() => _phonebookContactsNotifier;

  bool get _isSynchronizedTomContacts =>
      _contactsNotifier.value.getSuccessOrNull<ContactsInitial>() != null;

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

  void initialSynchronizeContacts({
    bool isAvailableSupportPhonebookContacts = false,
    required String withMxId,
  }) async {
    if (!_isSynchronizedTomContacts) {
      return;
    }
    _getAllContacts(
      isAvailableSupportPhonebookContacts: isAvailableSupportPhonebookContacts,
      withMxId: withMxId,
    );
  }

  void _getAllContacts({
    bool isAvailableSupportPhonebookContacts = false,
    required String withMxId,
  }) {
    getTomContactsInteractor.execute(limit: AppConfig.maxFetchContacts).listen(
      (event) {
        _contactsNotifier.value = event;
      },
    ).onDone(
      () => _lookUpPhonebookContacts(
        isAvailableSupportPhonebookContacts:
            isAvailableSupportPhonebookContacts,
        withMxId: withMxId,
      ),
    );
  }

  void _lookUpPhonebookContacts({
    bool isAvailableSupportPhonebookContacts = false,
    required String withMxId,
  }) async {
    if (!isAvailableSupportPhonebookContacts) {
      return;
    }

    final authorizationInterceptor = getIt.get<AuthorizationInterceptor>();

    final homeServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
      instanceName: NetworkDI.homeServerUrlInterceptorName,
    );

    phonebookContactInteractor
        .execute(
      lookupChunkSize: _lookupChunkSize,
      argument: FederationLookUpArgument(
        federationUrl: homeServerUrlInterceptor.baseUrl ?? '',
        withMxId: withMxId,
        withAccessToken: authorizationInterceptor.getAccessToken ?? '',
      ),
    )
        .listen(
      (event) {
        _phonebookContactsNotifier.value = event;
      },
    );
  }

  void synchronizePhonebookContacts({
    required String withMxId,
  }) =>
      _lookUpPhonebookContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: withMxId,
      );
}
