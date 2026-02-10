import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:fluffychat/data/model/federation_server/federation_configuration.dart';
import 'package:fluffychat/data/model/federation_server/federation_server_information.dart';
import 'package:fluffychat/data/network/interceptor/authorization_interceptor.dart';
import 'package:fluffychat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/app_state/contact/post_address_book_state.dart';
import 'package:fluffychat/domain/app_state/contact/try_get_synced_phone_book_contact_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/repository/contact/hive_contact_repository.dart';
import 'package:fluffychat/domain/repository/federation_configurations_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_argument.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_phonebook_contact_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/try_get_synced_phone_book_contact_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_argument.dart';
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_phonebook_contact_interactor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../fixtures/contact_fixtures.dart';
import 'contacts_manager_test.mocks.dart';

@GenerateMocks([
  GetTomContactsInteractor,
  AuthorizationInterceptor,
  DynamicUrlInterceptors,
  FederationConfigurationsRepository,
  FederationLookUpPhonebookContactInteractor,
  TryGetSyncedPhoneBookContactInteractor,
  TwakeLookupPhonebookContactInteractor,
  PostAddressBookInteractor,
  SharedPreferencesContactCacheManager,
  HiveContactRepository,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFederationLookUpPhonebookContactInteractor
  mockFederationLookUpPhonebookContactInteractor;
  late MockGetTomContactsInteractor mockGetTomContactsInteractor;
  late MockTryGetSyncedPhoneBookContactInteractor
  mockTryGetSyncedPhoneBookContactInteractor;
  late MockTwakeLookupPhonebookContactInteractor
  mockTwakeLookupPhonebookContactInteractor;
  late MockPostAddressBookInteractor mockPostAddressBookInteractor;
  late MockAuthorizationInterceptor mockAuthorizationInterceptor;
  late MockDynamicUrlInterceptors mockHomeServerDynamicUrlInterceptors;
  late MockDynamicUrlInterceptors mockIdentityServerDynamicUrlInterceptors;
  late MockFederationConfigurationsRepository
  mockFederationConfigurationsRepository;
  late ContactsManager contactsManager;
  late MockHiveContactRepository mockHiveContactRepository;
  late MockSharedPreferencesContactCacheManager
  mockSharedPreferencesContactCacheManager;
  late GetIt getIt;

  setUp(() {
    HiveCacheStore('${Directory.current.path}/test/data/file_store');

    mockFederationLookUpPhonebookContactInteractor =
        MockFederationLookUpPhonebookContactInteractor();
    mockGetTomContactsInteractor = MockGetTomContactsInteractor();
    mockTryGetSyncedPhoneBookContactInteractor =
        MockTryGetSyncedPhoneBookContactInteractor();
    mockTwakeLookupPhonebookContactInteractor =
        MockTwakeLookupPhonebookContactInteractor();
    mockPostAddressBookInteractor = MockPostAddressBookInteractor();
    mockAuthorizationInterceptor = MockAuthorizationInterceptor();
    mockHomeServerDynamicUrlInterceptors = MockDynamicUrlInterceptors();
    mockFederationConfigurationsRepository =
        MockFederationConfigurationsRepository();
    mockHiveContactRepository = MockHiveContactRepository();
    mockSharedPreferencesContactCacheManager =
        MockSharedPreferencesContactCacheManager();
    mockIdentityServerDynamicUrlInterceptors = MockDynamicUrlInterceptors();

    getIt = GetIt.instance;

    getIt.registerLazySingleton<AuthorizationInterceptor>(
      () => mockAuthorizationInterceptor,
    );
    getIt.registerLazySingleton<DynamicUrlInterceptors>(
      () => mockHomeServerDynamicUrlInterceptors,
      instanceName: NetworkDI.homeServerUrlInterceptorName,
    );

    getIt.registerLazySingleton<DynamicUrlInterceptors>(
      () => mockIdentityServerDynamicUrlInterceptors,
      instanceName: NetworkDI.identityServerUrlInterceptorName,
    );
    getIt.registerFactory<FederationConfigurationsRepository>(
      () => mockFederationConfigurationsRepository,
    );

    getIt.registerFactory<GetTomContactsInteractor>(
      () => mockGetTomContactsInteractor,
    );
    getIt.registerFactory<FederationLookUpPhonebookContactInteractor>(
      () => mockFederationLookUpPhonebookContactInteractor,
    );
    getIt.registerFactory<TryGetSyncedPhoneBookContactInteractor>(
      () => mockTryGetSyncedPhoneBookContactInteractor,
    );
    getIt.registerFactory<TwakeLookupPhonebookContactInteractor>(
      () => mockTwakeLookupPhonebookContactInteractor,
    );
    getIt.registerFactory<PostAddressBookInteractor>(
      () => mockPostAddressBookInteractor,
    );
    getIt.registerFactory<HiveContactRepository>(
      () => mockHiveContactRepository,
    );

    getIt.registerFactory<SharedPreferencesContactCacheManager>(
      () => mockSharedPreferencesContactCacheManager,
    );

    contactsManager = ContactsManager();
  });

  tearDown(() {
    getIt.reset();
  });

  group('ContactsManager Unit test - ENV: WEB', () {
    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND contactsNotifier return GetContactsIsEmpty.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
      'THEN list ToM contact SHOULD is empty.\n'
      'THEN list address book contact SHOULD is empty\n'
      'THEN federationLookUpPhonebookContactInteractor SHOULD not call\n'
      'THEN twakeLookupPhonebookContactInteractor SHOULD not call.\n',
      () async {
        final List<Failure> listTomContactsFailureState = [];

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: false,
          withMxId: 'mxId',
        );

        await Future.delayed(const Duration(seconds: 2));

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        verifyNever(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: null,
          ),
        );

        verifyNever(
          mockTwakeLookupPhonebookContactInteractor.execute(argument: null),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND contactsNotifier return GetContactsFailure.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsFailure state.\n'
      'THEN list ToM contact SHOULD is empty.\n'
      'THEN federationLookUpPhonebookContactInteractor SHOULD not call\n'
      'THEN twakeLookupPhonebookContactInteractor SHOULD not call.\n',
      () async {
        final List<Failure> listTomContactsFailureState = [];

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsFailure(keyword: '', exception: dynamic)),
          ]),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: false,
          withMxId: 'mxId',
        );

        await Future.delayed(const Duration(seconds: 2));

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [
          const GetContactsFailure(keyword: '', exception: dynamic),
        ]);

        verifyNever(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: null,
          ),
        );

        verifyNever(
          mockTwakeLookupPhonebookContactInteractor.execute(argument: null),
        );
      },
    );

    test(
      'WHEN it is not available get Phonebook contact.\n'
      'AND contactsNotifier return GetContactsSuccess.\n'
      'AND getAddressBookNotifier return GetAddressBookSuccessState.\n'
      'THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
      'THEN list ToM contact SHOULD not empty.\n'
      'THEN federationLookUpPhonebookContactInteractor SHOULD not call\n'
      'THEN twakeLookupPhonebookContactInteractor SHOULD not call.\n',
      () async {
        final List<Success> listTomContactsSuccessState = [];

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => null,
            (success) => listTomContactsSuccessState.add(success),
          );
        });

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(
              GetContactsSuccess(
                contacts: [ContactFixtures.contact1, ContactFixtures.contact2],
              ),
            ),
          ]),
        );

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: false,
          withMxId: 'mxId',
        );

        await Future.delayed(const Duration(seconds: 2));

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(listTomContactsSuccessState, [
          const ContactsLoading(),
          GetContactsSuccess(
            contacts: [ContactFixtures.contact1, ContactFixtures.contact2],
          ),
        ]);

        final tomContact = contactsManager
            .getContactsNotifier()
            .value
            .getSuccessOrNull<GetContactsSuccess>()
            ?.contacts;

        expect(tomContact?.length, 2);

        verifyNever(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: null,
          ),
        );

        verifyNever(
          mockTwakeLookupPhonebookContactInteractor.execute(argument: null),
        );
      },
    );
  });

  group('ContactsManager Unit test - ENV: Mobile - Supported Federation server', () {
    const mxId = 'mxId';

    const baseUrl = 'https://example.com';

    const accessToken = 'accessToken';

    final federationConfigurations = FederationConfigurations(
      fedServerInformation: FederationServerInformation(
        baseUrls: [Uri(scheme: 'https', host: 'federation')],
      ),
    );

    final contacts = [
      ContactFixtures.contact1,
      ContactFixtures.contact2,
      ContactFixtures.contact3,
    ];

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return RequestTokenFailure state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have RequestTokenFailure state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Left(RequestTokenFailure(exception: dynamic, contacts: contacts)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        RequestTokenFailure(exception: dynamic, contacts: contacts),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactSuccessState state.\n'
        'AND timeAvailableForSyncVault is false.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is not empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Success> listPhonebookContactsSuccessState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async => Right(
          GetSyncedPhoneBookContactSuccessState(
            contacts: contacts,
            timeAvailableForSyncVault: false,
          ),
        ),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => null,
          (success) => listPhonebookContactsSuccessState.add(success),
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      verifyNever(mockHomeServerDynamicUrlInterceptors.baseUrl);

      verifyNever(mockAuthorizationInterceptor.getAccessToken);

      verifyNever(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      );

      verifyNever(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      );

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsSuccessState.length, 1);

      expectLater(listPhonebookContactsSuccessState, [
        GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactSuccessState state.\n'
        'AND timeAvailableForSyncVault is true.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have RequestTokenFailure state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async => Right(
          GetSyncedPhoneBookContactSuccessState(
            contacts: contacts,
            timeAvailableForSyncVault: true,
          ),
        ),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Left(RequestTokenFailure(exception: dynamic, contacts: contacts)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      verify(mockHomeServerDynamicUrlInterceptors.baseUrl).called(1);

      verify(mockAuthorizationInterceptor.getAccessToken).called(1);

      verify(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).called(1);

      verify(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        RequestTokenFailure(exception: dynamic, contacts: contacts),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactSuccessState state.\n'
        'AND timeAvailableForSyncVault is true.\n'
        'AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is not empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Success> listPhonebookContactsSuccessState = [];

      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async => Right(
          GetSyncedPhoneBookContactSuccessState(
            contacts: contacts,
            timeAvailableForSyncVault: true,
          ),
        ),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Right(GetPhonebookContactsSuccess(contacts: contacts, progress: 100)),
        ]),
      );

      when(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(PostAddressBookLoading()),
          const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => null,
          (success) => listPhonebookContactsSuccessState.add(success),
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      verify(mockHomeServerDynamicUrlInterceptors.baseUrl).called(1);

      verify(mockAuthorizationInterceptor.getAccessToken).called(1);

      verify(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).called(1);

      verify(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsSuccessState.length, 2);

      expectLater(listPhonebookContactsSuccessState, [
        const GetPhonebookContactsLoading(),
        GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsSuccess with contacts not empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactSuccessState state.\n'
        'AND timeAvailableForSyncVault is true.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is not empty.\n', () async {
      final List<Success> listTomContactsSuccessState = [];

      final List<Success> listPhonebookContactsSuccessState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          Right(GetContactsSuccess(contacts: contacts)),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async => Right(
          GetSyncedPhoneBookContactSuccessState(
            contacts: contacts,
            timeAvailableForSyncVault: true,
          ),
        ),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Right(GetPhonebookContactsSuccess(contacts: contacts, progress: 100)),
        ]),
      );

      when(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(PostAddressBookLoading()),
          const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => null,
          (success) => listTomContactsSuccessState.add(success),
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => null,
          (success) => listPhonebookContactsSuccessState.add(success),
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      verify(mockHomeServerDynamicUrlInterceptors.baseUrl).called(1);

      verify(mockAuthorizationInterceptor.getAccessToken).called(1);

      verify(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).called(1);

      verify(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).called(1);

      expectLater(listTomContactsSuccessState.length, 2);

      expectLater(listTomContactsSuccessState, [
        const ContactsLoading(),
        GetContactsSuccess(contacts: contacts),
      ]);

      expectLater(listPhonebookContactsSuccessState.length, 2);

      expectLater(listPhonebookContactsSuccessState, [
        const GetPhonebookContactsLoading(),
        GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return RegisterTokenFailure state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have RegisterTokenFailure state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Left(RegisterTokenFailure(exception: dynamic, contacts: contacts)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        RegisterTokenFailure(exception: dynamic, contacts: contacts),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetPhonebookContactsIsEmpty()),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetPhonebookContactsIsEmpty(),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return GetPhoneBookContactFailure state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhoneBookContactFailure state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetPhoneBookContactFailure(exception: dynamic)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetPhoneBookContactFailure(exception: dynamic),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetHashDetailsFailure(exception: dynamic)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetHashDetailsFailure(exception: dynamic),
      ]);
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND call initialSynchronizeContacts.\n'
        'AND contactsNotifier is LoadingState.\n'
        'AND THEN call initialSynchronizeContacts again.\n'
        'AND contactsNotifier not call again\n'
        'AND federationLookUpPhonebookContactInteractor not call.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Left(RequestTokenFailure(exception: dynamic, contacts: contacts)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        RequestTokenFailure(exception: dynamic, contacts: contacts),
      ]);

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 5));

      verifyNever(mockGetTomContactsInteractor.execute());
    });

    test(
      'WHEN it is available get Phonebook contact.\n'
      'AND call initialSynchronizeContacts.\n'
      'AND contactsNotifier is LoadingState.\n'
      'AND THEN call initialSynchronizeContacts again with forceRun is true.\n'
      'AND contactsNotifier must call again\n'
      'AND federationLookUpPhonebookContactInteractor must call.\n',
      () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(
          mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
        ).thenAnswer(
          (_) async =>
              const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            Left(RequestTokenFailure(exception: dynamic, contacts: contacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        verify(
          mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
        ).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          RequestTokenFailure(exception: dynamic, contacts: contacts),
        ]);

        contactsManager.initialSynchronizeContacts(
          isAvailableSupportPhonebookContacts: true,
          forceRun: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 5));

        verify(mockGetTomContactsInteractor.execute()).called(1);
      },
    );

    test('[Account-A] WHEN it is available get Phonebook contact.\n'
        '[Account-A] AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
        '[Account-A] THEN list ToM contact SHOULD is empty.\n'
        '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
        'Trigger UI => switch to another account and call synchronize contacts.\n'
        '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
        '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
        '[Account-B] THEN list ToM contact SHOULD is empty.\n'
        '[Account-B] THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetHashDetailsFailure(exception: dynamic)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetHashDetailsFailure(exception: dynamic),
      ]);

      /// Trigger switch account
      contactsManager.reSyncContacts();

      contactsManager.cancelAllSubscriptions();

      listTomContactsFailureState.clear();

      listPhonebookContactsFailureState.clear();

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetHashDetailsFailure(exception: dynamic)),
        ]),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetHashDetailsFailure(exception: dynamic),
      ]);
    });

    test('[Account-A] WHEN it is available get Phonebook contact.\n'
        '[Account-A] AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
        '[Account-A] THEN list ToM contact SHOULD is empty.\n'
        '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
        'Trigger UI => switch to another account and call synchronize contacts.\n'
        '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
        '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
        '[Account-B] THEN list ToM contact SHOULD is empty.\n'
        '[Account-B] THEN list Phonebook contact SHOULD not empty.\n'
        '[Account-B] THEN call post addressbook success', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      final List<Success> listPhonebookContactsSuccessState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetHashDetailsFailure(exception: dynamic)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => listPhonebookContactsSuccessState.add(success),
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetHashDetailsFailure(exception: dynamic),
      ]);

      /// Trigger switch account
      contactsManager.reSyncContacts();

      contactsManager.cancelAllSubscriptions();

      listTomContactsFailureState.clear();

      listPhonebookContactsFailureState.clear();

      listPhonebookContactsSuccessState.clear();

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer((_) async => federationConfigurations);

      when(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: FederationLookUpArgument(
            homeServerUrl: baseUrl,
            federationUrl:
                federationConfigurations.fedServerInformation.baseUrls?.first
                    .toString() ??
                '',
            withMxId: mxId,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Right(GetPhonebookContactsSuccess(contacts: contacts, progress: 100)),
        ]),
      );

      when(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(PostAddressBookLoading()),
          const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
        ]),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 0);

      expectLater(listPhonebookContactsFailureState, []);

      expectLater(listPhonebookContactsSuccessState.length, 2);

      expectLater(listPhonebookContactsSuccessState, [
        const GetPhonebookContactsLoading(),
        GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
      ]);

      verify(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).called(1);
    });
  });

  group('ContactsManager Unit test - ENV: Mobile - Unsupported Federation server', () {
    const mxId = 'mxId';

    const baseUrl = 'https://example.com';

    const accessToken = 'accessToken';

    final contacts = [
      ContactFixtures.contact1,
      ContactFixtures.contact2,
      ContactFixtures.contact3,
    ];

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetPhonebookContactsIsEmpty()),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetPhonebookContactsIsEmpty(),
      ]);

      verify(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: anyNamed('argument'),
        ),
      ).called(1);

      verifyNever(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: anyNamed('argument'),
        ),
      );
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetHashDetailsFailure(exception: dynamic)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetHashDetailsFailure(exception: dynamic),
      ]);

      verify(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: anyNamed('argument'),
        ),
      ).called(1);

      verifyNever(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: anyNamed('argument'),
        ),
      );
    });

    test('WHEN it is available get Phonebook contact.\n'
        'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        'AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        'AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
        'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
        'THEN list ToM contact SHOULD is empty.\n'
        'THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Success> listPhonebookContactsSuccessState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Right(GetPhonebookContactsSuccess(contacts: contacts, progress: 100)),
        ]),
      );

      when(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(PostAddressBookLoading()),
          const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => null,
          (success) => listPhonebookContactsSuccessState.add(success),
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      verify(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsSuccessState.length, 2);

      expectLater(listPhonebookContactsSuccessState, [
        const GetPhonebookContactsLoading(),
        GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
      ]);

      verify(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: anyNamed('argument'),
        ),
      ).called(1);

      verifyNever(
        mockFederationLookUpPhonebookContactInteractor.execute(
          argument: anyNamed('argument'),
        ),
      );
    });

    test('[Account-A] WHEN it is available get Phonebook contact.\n'
        '[Account-A] AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
        '[Account-A] THEN list ToM contact SHOULD is empty.\n'
        '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
        'Trigger UI => switch to another account and call synchronize contacts.\n'
        '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
        '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
        '[Account-B] THEN list ToM contact SHOULD is empty.\n'
        '[Account-B] THEN list Phonebook contact SHOULD is empty.\n', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetPhonebookContactsIsEmpty()),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetPhonebookContactsIsEmpty(),
      ]);

      /// Trigger switch account
      contactsManager.reSyncContacts();

      contactsManager.cancelAllSubscriptions();

      listTomContactsFailureState.clear();

      listPhonebookContactsFailureState.clear();

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetPhonebookContactsIsEmpty()),
        ]),
      );
      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetPhonebookContactsIsEmpty()),
        ]),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetPhonebookContactsIsEmpty(),
      ]);
    });

    test('[Account-A] WHEN it is available get Phonebook contact.\n'
        '[Account-A] AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
        '[Account-A] THEN list ToM contact SHOULD is empty.\n'
        '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
        'Trigger UI => switch to another account and call synchronize contacts.\n'
        '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
        '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
        '[Account-B] THEN list ToM contact SHOULD is empty.\n'
        '[Account-B] THEN list Phonebook contact SHOULD not empty.\n'
        '[Account-B] THEN call post addressbook success', () async {
      final List<Failure> listTomContactsFailureState = [];

      final List<Failure> listPhonebookContactsFailureState = [];

      final List<Success> listPhonebookContactsSuccessState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );
      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          const Left(GetPhonebookContactsIsEmpty()),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) => null,
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => listPhonebookContactsSuccessState.add(success),
        );
      });

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 1);

      expectLater(listPhonebookContactsFailureState, [
        const GetPhonebookContactsIsEmpty(),
      ]);

      /// Trigger switch account
      contactsManager.reSyncContacts();

      contactsManager.cancelAllSubscriptions();

      listTomContactsFailureState.clear();

      listPhonebookContactsFailureState.clear();

      listPhonebookContactsSuccessState.clear();

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          const Left(GetContactsIsEmpty()),
        ]),
      );

      when(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).thenAnswer(
        (_) async =>
            const Left(GetSyncedPhoneBookContactFailure(exception: dynamic)),
      );

      when(
        mockFederationConfigurationsRepository.getFederationConfigurations(
          mxId,
        ),
      ).thenAnswer(
        (_) async => FederationConfigurations(
          fedServerInformation: FederationServerInformation(),
        ),
      );

      when(
        mockIdentityServerDynamicUrlInterceptors.baseUrl,
      ).thenReturn(baseUrl);

      when(mockAuthorizationInterceptor.getAccessToken).thenReturn(accessToken);

      when(
        mockTwakeLookupPhonebookContactInteractor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: baseUrl,
            withAccessToken: accessToken,
          ),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(GetPhonebookContactsLoading()),
          Right(GetPhonebookContactsSuccess(contacts: contacts, progress: 100)),
        ]),
      );

      when(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(PostAddressBookLoading()),
          const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
        ]),
      );

      contactsManager.initialSynchronizeContacts(
        isAvailableSupportPhonebookContacts: true,
        withMxId: mxId,
      );

      await Future.delayed(const Duration(seconds: 1));

      verify(mockGetTomContactsInteractor.execute()).called(1);

      verify(
        mockTryGetSyncedPhoneBookContactInteractor.execute(userId: mxId),
      ).called(1);

      expectLater(listTomContactsFailureState.length, 1);

      expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

      expectLater(listPhonebookContactsFailureState.length, 0);

      expectLater(listPhonebookContactsFailureState, []);

      expectLater(listPhonebookContactsSuccessState.length, 2);

      expectLater(listPhonebookContactsSuccessState, [
        const GetPhonebookContactsLoading(),
        GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
      ]);

      verify(
        mockPostAddressBookInteractor.execute(
          addressBooks: contacts.toSet().toAddressBooks().toList(),
        ),
      ).called(1);
    });

    test('[Account-A] WHEN it is available get Phonebook contact.\n'
        '[Account-A] AND contactsNotifier return GetContactsSuccess.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
        '[Account-A] THEN list ToM contact SHOULD is not empty.\n'
        'Trigger UI => switch to another account and call synchronize contacts.\n'
        '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
        '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
        '[Account-A] AND tryGetSyncedPhoneBookContactInteractor return GetSyncedPhoneBookContactFailure state.\n'
        '[Account-A] AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
        '[Account-B] THEN list ToM contact SHOULD is empty.\n'
        '[Account-B] THEN list Phonebook contact SHOULD not empty.\n'
        '[Account-B] THEN call post addressbook success', () async {
      final List<Success> listTomContactsSuccessState = [];
      final List<Failure> listTomContactsFailureState = [];
      final List<Failure> listPhonebookContactsFailureState = [];
      final List<Success> listPhonebookContactsSuccessState = [];

      when(mockGetTomContactsInteractor.execute()).thenAnswer(
        (_) => Stream.fromIterable([
          const Right(ContactsLoading()),
          Right(GetContactsSuccess(contacts: contacts)),
        ]),
      );

      contactsManager.getContactsNotifier().addListener(() {
        contactsManager.getContactsNotifier().value.fold(
          (failure) => listTomContactsFailureState.add(failure),
          (success) async {
            listTomContactsSuccessState.add(success);

            if (success is GetContactsSuccess) {
              expect(listTomContactsSuccessState.length, 2);

              expect(listTomContactsSuccessState, [
                const ContactsLoading(),
                GetContactsSuccess(contacts: contacts),
              ]);

              /// Trigger switch account
              contactsManager.cancelAllSubscriptions();

              when(mockGetTomContactsInteractor.execute()).thenAnswer(
                (_) => Stream.fromIterable([
                  const Right(ContactsLoading()),
                  const Left(GetContactsIsEmpty()),
                ]),
              );

              when(
                mockTryGetSyncedPhoneBookContactInteractor.execute(
                  userId: mxId,
                ),
              ).thenAnswer(
                (_) async => const Left(
                  GetSyncedPhoneBookContactFailure(exception: dynamic),
                ),
              );

              when(
                mockFederationConfigurationsRepository
                    .getFederationConfigurations(mxId),
              ).thenAnswer(
                (_) async => FederationConfigurations(
                  fedServerInformation: FederationServerInformation(),
                ),
              );

              when(
                mockIdentityServerDynamicUrlInterceptors.baseUrl,
              ).thenReturn(baseUrl);

              when(
                mockAuthorizationInterceptor.getAccessToken,
              ).thenReturn(accessToken);

              when(
                mockTwakeLookupPhonebookContactInteractor.execute(
                  argument: TwakeLookUpArgument(
                    homeServerUrl: baseUrl,
                    withAccessToken: accessToken,
                  ),
                ),
              ).thenAnswer(
                (_) => Stream.fromIterable([
                  const Right(GetPhonebookContactsLoading()),
                  Right(
                    GetPhonebookContactsSuccess(
                      contacts: contacts,
                      progress: 100,
                    ),
                  ),
                ]),
              );

              when(
                mockPostAddressBookInteractor.execute(
                  addressBooks: contacts.toSet().toAddressBooks().toList(),
                ),
              ).thenAnswer(
                (_) => Stream.fromIterable([
                  const Right(PostAddressBookLoading()),
                  const Right(
                    PostAddressBookSuccessState(updatedAddressBooks: []),
                  ),
                ]),
              );

              contactsManager.reSyncContacts();

              listTomContactsFailureState.clear();
              listTomContactsSuccessState.clear();
              listPhonebookContactsFailureState.clear();
              listPhonebookContactsSuccessState.clear();

              contactsManager.initialSynchronizeContacts(
                isAvailableSupportPhonebookContacts: true,
                withMxId: mxId,
              );

              await Future.delayed(const Duration(seconds: 1));

              verify(mockGetTomContactsInteractor.execute()).called(2);

              verify(
                mockTryGetSyncedPhoneBookContactInteractor.execute(
                  userId: mxId,
                ),
              ).called(1);

              expectLater(listTomContactsFailureState.length, 1);
              expectLater(listTomContactsFailureState, [
                const GetContactsIsEmpty(),
              ]);

              expectLater(listPhonebookContactsFailureState.length, 0);
              expectLater(listPhonebookContactsFailureState, []);

              expectLater(listPhonebookContactsSuccessState.length, 2);

              expectLater(listPhonebookContactsSuccessState, [
                const GetPhonebookContactsLoading(),
                GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
              ]);

              verify(
                mockPostAddressBookInteractor.execute(
                  addressBooks: contacts.toSet().toAddressBooks().toList(),
                ),
              ).called(1);
            }
          },
        );
      });

      contactsManager.getPhonebookContactsNotifier().addListener(() {
        contactsManager.getPhonebookContactsNotifier().value.fold(
          (failure) => listPhonebookContactsFailureState.add(failure),
          (success) => listPhonebookContactsSuccessState.add(success),
        );
      });
    });
  });

  group(
    'ContactsManager Unit test - ENV: Mobile - Open contact tab and Unsupported Federation server',
    () {
      const mxId = 'mxId';

      const baseUrl = 'https://example.com';

      const accessToken = 'accessToken';

      final contacts = [
        ContactFixtures.contact1,
        ContactFixtures.contact2,
        ContactFixtures.contact3,
      ];

      test('WHEN it is available get Phonebook contact.\n'
          'AND open the contact tab.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer(
          (_) async => FederationConfigurations(
            fedServerInformation: FederationServerInformation(),
          ),
        );

        when(
          mockIdentityServerDynamicUrlInterceptors.baseUrl,
        ).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: TwakeLookUpArgument(
              homeServerUrl: baseUrl,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            const Left(GetPhonebookContactsIsEmpty()),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          const GetPhonebookContactsIsEmpty(),
        ]);

        verify(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: anyNamed('argument'),
          ),
        ).called(1);

        verifyNever(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: anyNamed('argument'),
          ),
        );
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND open the contact tab.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer(
          (_) async => FederationConfigurations(
            fedServerInformation: FederationServerInformation(),
          ),
        );

        when(
          mockIdentityServerDynamicUrlInterceptors.baseUrl,
        ).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: TwakeLookUpArgument(
              homeServerUrl: baseUrl,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            const Left(GetHashDetailsFailure(exception: dynamic)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          const GetHashDetailsFailure(exception: dynamic),
        ]);

        verify(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: anyNamed('argument'),
          ),
        ).called(1);

        verifyNever(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: anyNamed('argument'),
          ),
        );
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND open the contact tab.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer(
          (_) async => FederationConfigurations(
            fedServerInformation: FederationServerInformation(),
          ),
        );

        when(
          mockIdentityServerDynamicUrlInterceptors.baseUrl,
        ).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: TwakeLookUpArgument(
              homeServerUrl: baseUrl,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            Right(
              GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
            ),
          ]),
        );

        when(
          mockPostAddressBookInteractor.execute(
            addressBooks: contacts.toSet().toAddressBooks().toList(),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(PostAddressBookLoading()),
            const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => null,
            (success) => listPhonebookContactsSuccessState.add(success),
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        verify(
          mockPostAddressBookInteractor.execute(
            addressBooks: contacts.toSet().toAddressBooks().toList(),
          ),
        ).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(listPhonebookContactsSuccessState, [
          const GetPhonebookContactsLoading(),
          GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
        ]);

        verify(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: anyNamed('argument'),
          ),
        ).called(1);

        verifyNever(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: anyNamed('argument'),
          ),
        );
      });
    },
  );

  group(
    'ContactsManager Unit test - ENV: Mobile - Open contact tab and supported Federation server',
    () {
      const mxId = 'mxId';

      const baseUrl = 'https://example.com';

      const accessToken = 'accessToken';

      final federationConfigurations = FederationConfigurations(
        fedServerInformation: FederationServerInformation(
          baseUrls: [Uri(scheme: 'https', host: 'federation')],
        ),
      );

      final contacts = [
        ContactFixtures.contact1,
        ContactFixtures.contact2,
        ContactFixtures.contact3,
      ];

      test('WHEN it is available get Phonebook contact.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND timeAvailableForSyncVault is true.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have RequestTokenFailure state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            Left(RequestTokenFailure(exception: dynamic, contacts: contacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        verify(mockHomeServerDynamicUrlInterceptors.baseUrl).called(1);

        verify(mockAuthorizationInterceptor.getAccessToken).called(1);

        verify(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).called(1);

        verify(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          RequestTokenFailure(exception: dynamic, contacts: contacts),
        ]);
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND timeAvailableForSyncVault is true.\n'
          'AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is not empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            Right(
              GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
            ),
          ]),
        );

        when(
          mockPostAddressBookInteractor.execute(
            addressBooks: contacts.toSet().toAddressBooks().toList(),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(PostAddressBookLoading()),
            const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => null,
            (success) => listPhonebookContactsSuccessState.add(success),
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        verify(mockHomeServerDynamicUrlInterceptors.baseUrl).called(1);

        verify(mockAuthorizationInterceptor.getAccessToken).called(1);

        verify(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).called(1);

        verify(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(listPhonebookContactsSuccessState, [
          const GetPhonebookContactsLoading(),
          GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
        ]);
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND contactsNotifier return GetContactsSuccess with contacts not empty.\n'
          'AND timeAvailableForSyncVault is true.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is not empty.\n', () async {
        final List<Success> listTomContactsSuccessState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: contacts)),
          ]),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            Right(
              GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
            ),
          ]),
        );

        when(
          mockPostAddressBookInteractor.execute(
            addressBooks: contacts.toSet().toAddressBooks().toList(),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(PostAddressBookLoading()),
            const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => null,
            (success) => listTomContactsSuccessState.add(success),
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => null,
            (success) => listPhonebookContactsSuccessState.add(success),
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        verify(mockHomeServerDynamicUrlInterceptors.baseUrl).called(1);

        verify(mockAuthorizationInterceptor.getAccessToken).called(1);

        verify(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).called(1);

        verify(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).called(1);

        expectLater(listTomContactsSuccessState.length, 2);

        expectLater(listTomContactsSuccessState, [
          const ContactsLoading(),
          GetContactsSuccess(contacts: contacts),
        ]);

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(listPhonebookContactsSuccessState, [
          const GetPhonebookContactsLoading(),
          GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
        ]);
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND phonebookContactNotifier return RegisterTokenFailure state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have RegisterTokenFailure state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            Left(RegisterTokenFailure(exception: dynamic, contacts: contacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          RegisterTokenFailure(exception: dynamic, contacts: contacts),
        ]);
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            const Left(GetPhonebookContactsIsEmpty()),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          const GetPhonebookContactsIsEmpty(),
        ]);
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND phonebookContactNotifier return GetPhoneBookContactFailure state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhoneBookContactFailure state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            const Left(GetPhoneBookContactFailure(exception: dynamic)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          const GetPhoneBookContactFailure(exception: dynamic),
        ]);
      });

      test('WHEN it is available get Phonebook contact.\n'
          'AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          'AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
          'THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          'THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
          'THEN list ToM contact SHOULD is empty.\n'
          'THEN list Phonebook contact SHOULD is empty.\n', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(mockHomeServerDynamicUrlInterceptors.baseUrl).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer((_) async => federationConfigurations);

        when(
          mockFederationLookUpPhonebookContactInteractor.execute(
            argument: FederationLookUpArgument(
              homeServerUrl: baseUrl,
              federationUrl:
                  federationConfigurations.fedServerInformation.baseUrls?.first
                      .toString() ??
                  '',
              withMxId: mxId,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            const Left(GetHashDetailsFailure(exception: dynamic)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          const GetHashDetailsFailure(exception: dynamic),
        ]);
      });

      test(
        'WHEN it is available get Phonebook contact.\n'
        'AND call initialSynchronizeContacts.\n'
        'AND contactsNotifier is LoadingState.\n'
        'AND THEN call initialSynchronizeContacts again.\n'
        'AND contactsNotifier not call again\n'
        'AND federationLookUpPhonebookContactInteractor not call.\n',
        () async {
          final List<Failure> listTomContactsFailureState = [];

          final List<Failure> listPhonebookContactsFailureState = [];

          when(mockGetTomContactsInteractor.execute()).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(ContactsLoading()),
              const Left(GetContactsIsEmpty()),
            ]),
          );

          contactsManager.getContactsNotifier().addListener(() {
            contactsManager.getContactsNotifier().value.fold(
              (failure) => listTomContactsFailureState.add(failure),
              (success) => null,
            );
          });

          contactsManager.getPhonebookContactsNotifier().addListener(() {
            contactsManager.getPhonebookContactsNotifier().value.fold(
              (failure) => listPhonebookContactsFailureState.add(failure),
              (success) => null,
            );
          });

          contactsManager.synchronizeContactsOnContactTab(
            isAvailableSupportPhonebookContacts: true,
            withMxId: mxId,
          );

          await Future.delayed(const Duration(seconds: 1));

          verify(mockGetTomContactsInteractor.execute()).called(1);

          contactsManager.initialSynchronizeContacts(
            isAvailableSupportPhonebookContacts: true,
            withMxId: mxId,
          );

          await Future.delayed(const Duration(seconds: 5));

          verifyNever(mockGetTomContactsInteractor.execute());

          verifyNever(
            mockFederationLookUpPhonebookContactInteractor.execute(
              argument: anyNamed('argument'),
            ),
          );
        },
      );

      test(
        'WHEN it is available get Phonebook contact.\n'
        'AND call synchronizeContactsOnContactTab.\n'
        'AND contactsNotifier is LoadingState.\n'
        'AND THEN call synchronizeContactsOnContactTab agian.\n'
        'AND contactsNotifier must call again\n'
        'AND federationLookUpPhonebookContactInteractor must call.\n',
        () async {
          final List<Failure> listTomContactsFailureState = [];

          final List<Failure> listPhonebookContactsFailureState = [];

          when(mockGetTomContactsInteractor.execute()).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(ContactsLoading()),
              const Left(GetContactsIsEmpty()),
            ]),
          );

          when(
            mockHomeServerDynamicUrlInterceptors.baseUrl,
          ).thenReturn(baseUrl);

          when(
            mockAuthorizationInterceptor.getAccessToken,
          ).thenReturn(accessToken);

          when(
            mockFederationConfigurationsRepository.getFederationConfigurations(
              mxId,
            ),
          ).thenAnswer((_) async => federationConfigurations);

          when(
            mockFederationLookUpPhonebookContactInteractor.execute(
              argument: FederationLookUpArgument(
                homeServerUrl: baseUrl,
                federationUrl:
                    federationConfigurations
                        .fedServerInformation
                        .baseUrls
                        ?.first
                        .toString() ??
                    '',
                withMxId: mxId,
                withAccessToken: accessToken,
              ),
            ),
          ).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(GetPhonebookContactsLoading()),
              Left(RequestTokenFailure(exception: dynamic, contacts: contacts)),
            ]),
          );

          contactsManager.getContactsNotifier().addListener(() {
            contactsManager.getContactsNotifier().value.fold(
              (failure) => listTomContactsFailureState.add(failure),
              (success) => null,
            );
          });

          contactsManager.getPhonebookContactsNotifier().addListener(() {
            contactsManager.getPhonebookContactsNotifier().value.fold(
              (failure) => listPhonebookContactsFailureState.add(failure),
              (success) => null,
            );
          });

          contactsManager.synchronizeContactsOnContactTab(
            isAvailableSupportPhonebookContacts: true,
            withMxId: mxId,
          );

          await Future.delayed(const Duration(seconds: 1));

          verify(mockGetTomContactsInteractor.execute()).called(1);

          expectLater(listTomContactsFailureState.length, 1);

          expectLater(listTomContactsFailureState, [
            const GetContactsIsEmpty(),
          ]);

          expectLater(listPhonebookContactsFailureState.length, 1);

          expectLater(listPhonebookContactsFailureState, [
            RequestTokenFailure(exception: dynamic, contacts: contacts),
          ]);

          contactsManager.synchronizeContactsOnContactTab(
            isAvailableSupportPhonebookContacts: true,
            withMxId: mxId,
          );

          await Future.delayed(const Duration(seconds: 5));

          verify(mockGetTomContactsInteractor.execute()).called(1);

          verify(
            mockFederationLookUpPhonebookContactInteractor.execute(
              argument: FederationLookUpArgument(
                homeServerUrl: baseUrl,
                federationUrl:
                    federationConfigurations
                        .fedServerInformation
                        .baseUrls
                        ?.first
                        .toString() ??
                    '',
                withMxId: mxId,
                withAccessToken: accessToken,
              ),
            ),
          ).called(2);
        },
      );
      test(
        '[Account-A] WHEN it is available get Phonebook contact.\n'
        '[Account-A] AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
        '[Account-A] open the contact tab.\n'
        '[Account-A] AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
        '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
        '[Account-A] THEN list ToM contact SHOULD is empty.\n'
        '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
        'Trigger UI => switch to another account and call synchronize contacts.\n'
        '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
        '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
        '[Account-B] open the contact tab.\n'
        '[Account-B] AND phonebookContactNotifier return GetPhonebookContactsIsEmpty state.\n'
        '[Account-B] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
        '[Account-B] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsIsEmpty state.\n'
        '[Account-B] THEN list ToM contact SHOULD is empty.\n'
        '[Account-B] THEN list Phonebook contact SHOULD is empty.\n',
        () async {
          final List<Failure> listTomContactsFailureState = [];

          final List<Failure> listPhonebookContactsFailureState = [];

          when(mockGetTomContactsInteractor.execute()).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(ContactsLoading()),
              const Left(GetContactsIsEmpty()),
            ]),
          );

          when(
            mockFederationConfigurationsRepository.getFederationConfigurations(
              mxId,
            ),
          ).thenAnswer(
            (_) async => FederationConfigurations(
              fedServerInformation: FederationServerInformation(),
            ),
          );

          when(
            mockIdentityServerDynamicUrlInterceptors.baseUrl,
          ).thenReturn(baseUrl);

          when(
            mockAuthorizationInterceptor.getAccessToken,
          ).thenReturn(accessToken);

          when(
            mockTwakeLookupPhonebookContactInteractor.execute(
              argument: TwakeLookUpArgument(
                homeServerUrl: baseUrl,
                withAccessToken: accessToken,
              ),
            ),
          ).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(GetPhonebookContactsLoading()),
              const Left(GetPhonebookContactsIsEmpty()),
            ]),
          );

          contactsManager.getContactsNotifier().addListener(() {
            contactsManager.getContactsNotifier().value.fold(
              (failure) => listTomContactsFailureState.add(failure),
              (success) => null,
            );
          });

          contactsManager.getPhonebookContactsNotifier().addListener(() {
            contactsManager.getPhonebookContactsNotifier().value.fold(
              (failure) => listPhonebookContactsFailureState.add(failure),
              (success) => null,
            );
          });

          contactsManager.synchronizeContactsOnContactTab(
            isAvailableSupportPhonebookContacts: true,
            withMxId: mxId,
          );

          await Future.delayed(const Duration(seconds: 1));

          verify(mockGetTomContactsInteractor.execute()).called(1);

          expectLater(listTomContactsFailureState.length, 1);

          expectLater(listTomContactsFailureState, [
            const GetContactsIsEmpty(),
          ]);

          expectLater(listPhonebookContactsFailureState.length, 1);

          expectLater(listPhonebookContactsFailureState, [
            const GetPhonebookContactsIsEmpty(),
          ]);

          /// Trigger switch account
          contactsManager.reSyncContacts();

          contactsManager.cancelAllSubscriptions();

          listTomContactsFailureState.clear();

          listPhonebookContactsFailureState.clear();

          when(mockGetTomContactsInteractor.execute()).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(ContactsLoading()),
              const Left(GetContactsIsEmpty()),
            ]),
          );

          when(
            mockFederationConfigurationsRepository.getFederationConfigurations(
              mxId,
            ),
          ).thenAnswer(
            (_) async => FederationConfigurations(
              fedServerInformation: FederationServerInformation(),
            ),
          );

          when(
            mockIdentityServerDynamicUrlInterceptors.baseUrl,
          ).thenReturn(baseUrl);

          when(
            mockAuthorizationInterceptor.getAccessToken,
          ).thenReturn(accessToken);

          when(
            mockTwakeLookupPhonebookContactInteractor.execute(
              argument: TwakeLookUpArgument(
                homeServerUrl: baseUrl,
                withAccessToken: accessToken,
              ),
            ),
          ).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(GetPhonebookContactsLoading()),
              const Left(GetPhonebookContactsIsEmpty()),
            ]),
          );
          when(
            mockFederationConfigurationsRepository.getFederationConfigurations(
              mxId,
            ),
          ).thenAnswer(
            (_) async => FederationConfigurations(
              fedServerInformation: FederationServerInformation(),
            ),
          );

          when(
            mockIdentityServerDynamicUrlInterceptors.baseUrl,
          ).thenReturn(baseUrl);

          when(
            mockAuthorizationInterceptor.getAccessToken,
          ).thenReturn(accessToken);

          when(
            mockTwakeLookupPhonebookContactInteractor.execute(
              argument: TwakeLookUpArgument(
                homeServerUrl: baseUrl,
                withAccessToken: accessToken,
              ),
            ),
          ).thenAnswer(
            (_) => Stream.fromIterable([
              const Right(GetPhonebookContactsLoading()),
              const Left(GetPhonebookContactsIsEmpty()),
            ]),
          );

          contactsManager.synchronizeContactsOnContactTab(
            isAvailableSupportPhonebookContacts: true,
            withMxId: mxId,
          );

          await Future.delayed(const Duration(seconds: 1));

          verify(mockGetTomContactsInteractor.execute()).called(1);

          expectLater(listTomContactsFailureState.length, 1);

          expectLater(listTomContactsFailureState, [
            const GetContactsIsEmpty(),
          ]);

          expectLater(listPhonebookContactsFailureState.length, 1);

          expectLater(listPhonebookContactsFailureState, [
            const GetPhonebookContactsIsEmpty(),
          ]);
        },
      );

      test('[Account-A] WHEN it is available get Phonebook contact.\n'
          '[Account-A] AND contactsNotifier return GetContactsIsEmpty with contacts is empty.\n'
          '[Account-A] open the contact tab.\n'
          '[Account-A] AND phonebookContactNotifier return GetHashDetailsFailure state.\n'
          '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          '[Account-A] THEN phonebookContactNotifier in ContactsManager SHOULD have GetHashDetailsFailure state.\n'
          '[Account-A] THEN list ToM contact SHOULD is empty.\n'
          '[Account-A] THEN list Phonebook contact SHOULD is empty.\n'
          'Trigger UI => switch to another account and call synchronize contacts.\n'
          '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
          '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
          '[Account-B] open the contact tab.\n'
          '[Account-B] AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
          '[Account-B] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          '[Account-B] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
          '[Account-B] THEN list ToM contact SHOULD is empty.\n'
          '[Account-B] THEN list Phonebook contact SHOULD not empty.\n'
          '[Account-B] THEN call post addressbook success', () async {
        final List<Failure> listTomContactsFailureState = [];

        final List<Failure> listPhonebookContactsFailureState = [];

        final List<Success> listPhonebookContactsSuccessState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer(
          (_) async => FederationConfigurations(
            fedServerInformation: FederationServerInformation(),
          ),
        );

        when(
          mockIdentityServerDynamicUrlInterceptors.baseUrl,
        ).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: TwakeLookUpArgument(
              homeServerUrl: baseUrl,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            const Left(GetPhonebookContactsIsEmpty()),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) => null,
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => listPhonebookContactsSuccessState.add(success),
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 1);

        expectLater(listPhonebookContactsFailureState, [
          const GetPhonebookContactsIsEmpty(),
        ]);

        /// Trigger switch account
        contactsManager.reSyncContacts();

        contactsManager.cancelAllSubscriptions();

        listTomContactsFailureState.clear();

        listPhonebookContactsFailureState.clear();

        listPhonebookContactsSuccessState.clear();

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            const Left(GetContactsIsEmpty()),
          ]),
        );

        when(
          mockFederationConfigurationsRepository.getFederationConfigurations(
            mxId,
          ),
        ).thenAnswer(
          (_) async => FederationConfigurations(
            fedServerInformation: FederationServerInformation(),
          ),
        );

        when(
          mockIdentityServerDynamicUrlInterceptors.baseUrl,
        ).thenReturn(baseUrl);

        when(
          mockAuthorizationInterceptor.getAccessToken,
        ).thenReturn(accessToken);

        when(
          mockTwakeLookupPhonebookContactInteractor.execute(
            argument: TwakeLookUpArgument(
              homeServerUrl: baseUrl,
              withAccessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(GetPhonebookContactsLoading()),
            Right(
              GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
            ),
          ]),
        );

        when(
          mockPostAddressBookInteractor.execute(
            addressBooks: contacts.toSet().toAddressBooks().toList(),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(PostAddressBookLoading()),
            const Right(PostAddressBookSuccessState(updatedAddressBooks: [])),
          ]),
        );

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );

        await Future.delayed(const Duration(seconds: 1));

        verify(mockGetTomContactsInteractor.execute()).called(1);

        expectLater(listTomContactsFailureState.length, 1);

        expectLater(listTomContactsFailureState, [const GetContactsIsEmpty()]);

        expectLater(listPhonebookContactsFailureState.length, 0);

        expectLater(listPhonebookContactsFailureState, []);

        expectLater(listPhonebookContactsSuccessState.length, 2);

        expectLater(listPhonebookContactsSuccessState, [
          const GetPhonebookContactsLoading(),
          GetPhonebookContactsSuccess(contacts: contacts, progress: 100),
        ]);

        verify(
          mockPostAddressBookInteractor.execute(
            addressBooks: contacts.toSet().toAddressBooks().toList(),
          ),
        ).called(1);
      });

      test('[Account-A] WHEN it is available get Phonebook contact.\n'
          '[Account-A] AND contactsNotifier return GetContactsSuccess.\n'
          '[Account-A] THEN contactsNotifier in ContactsManager SHOULD have GetContactsSuccess state.\n'
          '[Account-A] THEN list ToM contact SHOULD is not empty.\n'
          'Trigger UI => switch to another account and call synchronize contacts.\n'
          '[Account-B] AND contactsNotifier return GetContactsSuccess with contacts is empty.\n'
          '[Account-B] AND phonebookContactInteractor return GetPhonebookContactsSuccess with contacts is empty.\n'
          '[Account-B] open the contact tab.\n'
          '[Account-B] AND phonebookContactNotifier return GetPhonebookContactsSuccess state.\n'
          '[Account-B] THEN contactsNotifier in ContactsManager SHOULD have GetContactsIsEmpty state.\n'
          '[Account-B] THEN phonebookContactNotifier in ContactsManager SHOULD have GetPhonebookContactsSuccess state.\n'
          '[Account-B] THEN list ToM contact SHOULD is empty.\n'
          '[Account-B] THEN list Phonebook contact SHOULD not empty.\n'
          '[Account-B] THEN call post addressbook success', () async {
        final List<Success> listTomContactsSuccessState = [];
        final List<Failure> listTomContactsFailureState = [];
        final List<Failure> listPhonebookContactsFailureState = [];
        final List<Success> listPhonebookContactsSuccessState = [];

        when(mockGetTomContactsInteractor.execute()).thenAnswer(
          (_) => Stream.fromIterable([
            const Right(ContactsLoading()),
            Right(GetContactsSuccess(contacts: contacts)),
          ]),
        );

        contactsManager.getContactsNotifier().addListener(() {
          contactsManager.getContactsNotifier().value.fold(
            (failure) => listTomContactsFailureState.add(failure),
            (success) async {
              listTomContactsSuccessState.add(success);

              if (success is GetContactsSuccess) {
                expect(listTomContactsSuccessState.length, 2);

                expect(listTomContactsSuccessState, [
                  const ContactsLoading(),
                  GetContactsSuccess(contacts: contacts),
                ]);

                /// Trigger switch account
                contactsManager.cancelAllSubscriptions();

                when(mockGetTomContactsInteractor.execute()).thenAnswer(
                  (_) => Stream.fromIterable([
                    const Right(ContactsLoading()),
                    const Left(GetContactsIsEmpty()),
                  ]),
                );

                when(
                  mockFederationConfigurationsRepository
                      .getFederationConfigurations(mxId),
                ).thenAnswer(
                  (_) async => FederationConfigurations(
                    fedServerInformation: FederationServerInformation(),
                  ),
                );

                when(
                  mockIdentityServerDynamicUrlInterceptors.baseUrl,
                ).thenReturn(baseUrl);

                when(
                  mockAuthorizationInterceptor.getAccessToken,
                ).thenReturn(accessToken);

                when(
                  mockTwakeLookupPhonebookContactInteractor.execute(
                    argument: TwakeLookUpArgument(
                      homeServerUrl: baseUrl,
                      withAccessToken: accessToken,
                    ),
                  ),
                ).thenAnswer(
                  (_) => Stream.fromIterable([
                    const Right(GetPhonebookContactsLoading()),
                    Right(
                      GetPhonebookContactsSuccess(
                        contacts: contacts,
                        progress: 100,
                      ),
                    ),
                  ]),
                );

                when(
                  mockPostAddressBookInteractor.execute(
                    addressBooks: contacts.toSet().toAddressBooks().toList(),
                  ),
                ).thenAnswer(
                  (_) => Stream.fromIterable([
                    const Right(PostAddressBookLoading()),
                    const Right(
                      PostAddressBookSuccessState(updatedAddressBooks: []),
                    ),
                  ]),
                );

                contactsManager.reSyncContacts();

                listTomContactsFailureState.clear();
                listTomContactsSuccessState.clear();
                listPhonebookContactsFailureState.clear();
                listPhonebookContactsSuccessState.clear();

                contactsManager.synchronizeContactsOnContactTab(
                  isAvailableSupportPhonebookContacts: true,
                  withMxId: mxId,
                );

                await Future.delayed(const Duration(seconds: 1));

                verify(mockGetTomContactsInteractor.execute()).called(2);

                expectLater(listTomContactsFailureState.length, 1);
                expectLater(listTomContactsFailureState, [
                  const GetContactsIsEmpty(),
                ]);

                expectLater(listPhonebookContactsFailureState.length, 0);
                expectLater(listPhonebookContactsFailureState, []);

                expectLater(listPhonebookContactsSuccessState.length, 2);

                expectLater(listPhonebookContactsSuccessState, [
                  const GetPhonebookContactsLoading(),
                  GetPhonebookContactsSuccess(
                    contacts: contacts,
                    progress: 100,
                  ),
                ]);

                verify(
                  mockPostAddressBookInteractor.execute(
                    addressBooks: contacts.toSet().toAddressBooks().toList(),
                  ),
                ).called(1);
              }
            },
          );
        });

        contactsManager.getPhonebookContactsNotifier().addListener(() {
          contactsManager.getPhonebookContactsNotifier().value.fold(
            (failure) => listPhonebookContactsFailureState.add(failure),
            (success) => listPhonebookContactsSuccessState.add(success),
          );
        });

        contactsManager.synchronizeContactsOnContactTab(
          isAvailableSupportPhonebookContacts: true,
          withMxId: mxId,
        );
      });
    },
  );
}
