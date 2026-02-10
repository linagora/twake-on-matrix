import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/exception/contacts/twake_lookup_exceptions.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/repository/contact/hive_contact_repository.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_argument.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_phonebook_contact_interactor.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/federation_identity_lookup_manager.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/identity_lookup_manager.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_request.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/state/federation_identity_request_token_state.dart';
import 'package:fluffychat/modules/federation_identity_request_token/manager/federation_identity_request_token_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../fixtures/contact_fixtures.dart';
import 'federation_look_up_phonebook_contact_interactor_test.mocks.dart';

@GenerateMocks([
  PhonebookContactRepository,
  IdentityLookupManager,
  FederationIdentityRequestTokenManager,
  FederationIdentityLookupManager,
  HiveContactRepository,
  SharedPreferencesContactCacheManager,
])
void main() {
  late FederationLookUpPhonebookContactInteractor interactor;
  late MockPhonebookContactRepository mockRepository;
  late MockFederationIdentityRequestTokenManager mockRequestTokenManager;
  late MockIdentityLookupManager mockIdentityLookupManager;
  late MockHiveContactRepository mockHiveContactRepository;
  late MockSharedPreferencesContactCacheManager
  mockSharedPreferencesContactCacheManager;

  late MockFederationIdentityLookupManager mockFederationIdentityLookupManager;

  const tokenInformation = FederationTokenInformation(
    accessToken: 'access-token',
    matrixServerName: 'matrix.domain',
  );

  const federationUrl = 'https://federation.example.com';
  const homeserverUrl = 'https://example.com';
  const matrixId = '@user:example.com';
  const accessToken = 'access-token';

  final testArgument = FederationLookUpArgument(
    homeServerUrl: homeserverUrl,
    withMxId: matrixId,
    withAccessToken: accessToken,
    federationUrl: federationUrl,
  );

  final testTokenRequest = FederationTokenRequest(
    homeserverUrl: '$homeserverUrl/',
    mxid: matrixId,
    accessToken: accessToken,
  );

  final testContacts = [ContactFixtures.contact1, ContactFixtures.contact2];

  setUp(() {
    mockRepository = MockPhonebookContactRepository();
    mockRequestTokenManager = MockFederationIdentityRequestTokenManager();
    mockIdentityLookupManager = MockIdentityLookupManager();
    mockFederationIdentityLookupManager = MockFederationIdentityLookupManager();
    mockHiveContactRepository = MockHiveContactRepository();
    mockSharedPreferencesContactCacheManager =
        MockSharedPreferencesContactCacheManager();

    final getIt = GetIt.instance;

    getIt.registerFactory<PhonebookContactRepository>(() => mockRepository);
    getIt.registerFactory<FederationIdentityRequestTokenManager>(
      () => mockRequestTokenManager,
    );
    getIt.registerFactory<IdentityLookupManager>(
      () => mockIdentityLookupManager,
    );
    getIt.registerFactory<FederationIdentityLookupManager>(
      () => mockFederationIdentityLookupManager,
    );
    getIt.registerFactory<HiveContactRepository>(
      () => mockHiveContactRepository,
    );
    getIt.registerFactory<SharedPreferencesContactCacheManager>(
      () => mockSharedPreferencesContactCacheManager,
    );

    interactor = FederationLookUpPhonebookContactInteractor();
  });

  tearDown(() {
    getIt.reset();
  });

  group('execute', () {
    group('error handling', () {
      test('should emit failure when register token request fails', () async {
        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => testContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenThrow(Exception('Register failed'));

        expectLater(
          interactor.execute(argument: testArgument),
          emitsInOrder([
            const Right(GetPhonebookContactsLoading()),
            Left(
              RegisterTokenFailure(
                exception: 'Register failed',
                contacts: testContacts,
              ),
            ),
          ]),
        );
      });

      test('should emit failure when hash details request fails', () async {
        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => testContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        final expectedException = Exception('Hash details failed');
        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenThrow(expectedException);

        expectLater(
          interactor.execute(argument: testArgument),
          emitsInOrder([
            const Right(GetPhonebookContactsLoading()),
            Left(GetHashDetailsFailure(exception: expectedException)),
          ]),
        );
      });

      test('should emit failure when lookup mxid request fails', () async {
        final exception = Exception('Lookup failed');

        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => testContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenThrow(exception);

        expectLater(
          interactor.execute(argument: testArgument),
          emitsInOrder([
            const Right(GetPhonebookContactsLoading()),
            Left(
              LookUpPhonebookContactPartialFailed(
                exception: TwakeLookupChunkException(exception.toString()),
                contacts: testContacts,
              ),
            ),
          ]),
        );
      });

      test('should emit failure when fetchContacts fails', () async {
        final expectedException = Exception('Failed to fetch contacts');

        when(mockRepository.fetchContacts()).thenThrow(expectedException);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        expectLater(
          interactor.execute(argument: testArgument),
          emitsInOrder([
            const Right(GetPhonebookContactsLoading()),
            Left(GetPhoneBookContactFailure(exception: expectedException)),
          ]),
        );
      });

      test('should emit empty state when contacts list is empty', () async {
        when(mockRepository.fetchContacts()).thenAnswer((_) async => []);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        expectLater(
          interactor.execute(argument: testArgument),
          emitsInOrder([
            const Right(GetPhonebookContactsLoading()),
            const Left(GetPhonebookContactsIsEmpty()),
          ]),
        );
      });

      test('should emit failure when token request fails', () async {
        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => testContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => Left<Failure, Success>(
            RequestTokenFailure(
              exception: 'Failed to get token',
              contacts: testContacts,
            ),
          ),
        );

        expectLater(
          interactor.execute(argument: testArgument),
          emitsInOrder([
            const Right(GetPhonebookContactsLoading()),
            Left(
              RequestTokenFailure(
                exception: 'Token is empty',
                contacts: testContacts,
              ),
            ),
          ]),
        );
      });

      test('should emit failure when hash details response is empty', () async {
        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => testContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        // Empty hash details response
        const emptyHashDetails = FederationHashDetailsResponse(
          algorithms: {},
          lookupPepper: '',
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => emptyHashDetails);

        expectLater(
          interactor.execute(argument: testArgument),
          emitsInOrder([
            const Right(GetPhonebookContactsLoading()),
            const Left(
              GetHashDetailsFailure(exception: 'Hash details is empty'),
            ),
          ]),
        );
      });
    });

    group('contact processing', () {
      test(
        'should process contacts with both phone and email but third party module has problem',
        () async {
          final expectedContacts = [
            Contact(
              id: 'id_1',
              displayName: 'Alice',
              phoneNumbers: {
                PhoneNumber(
                  number: '(212)555-6789',
                  matrixId: '@alice:matrix.org',
                ),
              },
              emails: {Email(address: 'alice@gmail.com')},
            ),
            Contact(
              id: 'id_2',
              displayName: 'Bob',
              phoneNumbers: {PhoneNumber(number: '(212)555-1234')},
              emails: {Email(address: 'bob@gmail.com')},
            ),
          ];

          when(
            mockRepository.fetchContacts(),
          ).thenAnswer((_) async => testContacts);

          when(
            mockRequestTokenManager.execute(
              federationTokenRequest: testTokenRequest,
            ),
          ).thenAnswer(
            (_) async => const Right<Failure, Success>(
              FederationIdentityRequestTokenSuccess(
                tokenInformation: tokenInformation,
              ),
            ),
          );

          when(
            mockIdentityLookupManager.register(
              federationUrl: federationUrl,
              tokenInformation: tokenInformation,
            ),
          ).thenAnswer(
            (_) async => const FederationRegisterResponse(
              token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
            ),
          );

          const hashDetails = FederationHashDetailsResponse(
            algorithms: {'sha256'},
            lookupPepper: 'pepper',
            altLookupPeppers: {'pepper1', 'pepper2'},
          );

          when(
            mockIdentityLookupManager.getHashDetails(
              federationUrl: anyNamed('federationUrl'),
              registeredToken: anyNamed('registeredToken'),
            ),
          ).thenAnswer((_) async => hashDetails);

          when(
            mockIdentityLookupManager.lookupMxid(
              federationUrl: anyNamed('federationUrl'),
              request: anyNamed('request'),
              registeredToken: anyNamed('registeredToken'),
            ),
          ).thenAnswer(
            (_) async => const FederationLookupMxidResponse(
              mappings: {
                '6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok':
                    '@alice:matrix.org',
              },
              thirdPartyMappings: {
                'tom.domain.com': {
                  'WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM',
                },
              },
            ),
          );

          final result = interactor.execute(argument: testArgument);

          expect(
            result,
            emitsInOrder(<dynamic>[
              const Right<Failure, Success>(GetPhonebookContactsLoading()),
              Right<Failure, Success>(
                GetPhonebookContactsSuccess(
                  progress: 100,
                  contacts: expectedContacts,
                ),
              ),
              Right<Failure, Success>(
                GetPhonebookContactsSuccess(
                  progress: 100,
                  contacts: expectedContacts,
                ),
              ),
            ]),
          );
        },
      );

      test('should process contacts with both phone and email', () async {
        final expectedContacts = [
          Contact(
            id: 'id_1',
            displayName: 'Alice',
            phoneNumbers: {
              PhoneNumber(
                number: '(212)555-6789',
                matrixId: '@alice:matrix.org',
              ),
            },
            emails: {Email(address: 'alice@gmail.com')},
          ),
          Contact(
            id: 'id_2',
            displayName: 'Bob',
            phoneNumbers: {
              PhoneNumber(matrixId: '@bob:matrix.com', number: '(212)555-1234'),
            },
            emails: {Email(address: 'bob@gmail.com')},
          ),
        ];

        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => testContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer(
          (_) async => const FederationLookupMxidResponse(
            mappings: {
              '6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok':
                  '@alice:matrix.org',
            },
            thirdPartyMappings: {
              'tom.domain.com': {'WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM'},
            },
          ),
        );

        // arrange third party module
        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: FederationTokenRequest(
              homeserverUrl: homeserverUrl,
              mxid: matrixId,
              accessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockFederationIdentityLookupManager.execute(
            arguments: anyNamed('arguments'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Success>(
            FederationIdentityLookupSuccess(
              newContacts: {
                ContactFixtures.contact2.id: FederationContact(
                  id: "id_2",
                  emails: {
                    FederationEmail(
                      address: "bob@gmail.com",
                      thirdPartyIdToHashMap: {
                        "bob@gmail.com": [
                          "vd5fBacH_IoS6u1BuTJW5NYNdplO8pRrNBbUjCUiQ6M",
                          "GBu5ur8lXU-2eAHYRUNUmYVDWe1IC2uOBw2icyNGwQY",
                          "2Z-nPbG4mJmL-f3tffnXfGS8X3nfYpn_oRND5wPVgHs",
                        ],
                      },
                    ),
                  },
                  name: "Bob",
                  phoneNumbers: {
                    FederationPhone(
                      number: "(212)555-1234",
                      matrixId: '@bob:matrix.com',
                      thirdPartyIdToHashMap: {
                        "(212)555-1234": [
                          "WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM",
                          "ZheHOgZYwWQUuvlfoVQoamDarSmqRmmGmkGZz9oVy-8",
                          "ni60knhw44PHn8JUYd1DkZzAnZaQhojuW_aE36MkeVs",
                        ],
                      },
                    ),
                  },
                ),
              },
            ),
          ),
        );

        final result = interactor.execute(argument: testArgument);

        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(
                progress: 100,
                contacts: expectedContacts,
              ),
            ),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(
                progress: 100,
                contacts: expectedContacts,
              ),
            ),
          ]),
        );
      });

      test('should handle contacts with only phone numbers', () async {
        final phoneOnlyContacts = [
          ContactFixtures.contact1
              .copyWith(emails: {})
              .copyWith(
                phoneNumbers: {
                  PhoneNumber(number: '(212)555-6789'),
                  PhoneNumber(number: '(252)555-1234'),
                  PhoneNumber(number: '(213)555-1234'),
                },
              ),
          ContactFixtures.contact2.copyWith(emails: {}),
        ];

        final expectedContacts = [
          Contact(
            id: 'id_1',
            displayName: 'Alice',
            phoneNumbers: {
              PhoneNumber(
                number: '(212)555-6789',
                matrixId: '@alice:matrix.org',
              ),
              PhoneNumber(number: '(252)555-1234'),
              PhoneNumber(number: '(213)555-1234'),
            },
            emails: const {},
          ),
          Contact(
            id: 'id_2',
            displayName: 'Bob',
            phoneNumbers: {PhoneNumber(number: '(212)555-1234')},
            emails: const {},
          ),
        ];

        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => phoneOnlyContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer(
          (_) async => const FederationLookupMxidResponse(
            mappings: {},
            thirdPartyMappings: {
              'tom.domain.com': {'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM'},
            },
          ),
        );

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: FederationTokenRequest(
              homeserverUrl: homeserverUrl,
              mxid: matrixId,
              accessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockFederationIdentityLookupManager.execute(
            arguments: anyNamed('arguments'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Success>(
            FederationIdentityLookupSuccess(
              newContacts: {
                ContactFixtures.contact1.id: FederationContact(
                  id: "id_1",
                  name: "Alice",
                  phoneNumbers: {
                    FederationPhone(
                      number: '(212)555-6789',
                      matrixId: '@alice:matrix.org',
                      thirdPartyIdToHashMap: {
                        "(212)555-6789": [
                          "lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM",
                        ],
                      },
                    ),
                    FederationPhone(
                      number: '(252)555-1234',
                      thirdPartyIdToHashMap: {
                        "(252)555-1234": [
                          "5cx7Oz_Q7jf7-Yn6pvCEyiM4HRrbLCk1DwbWaVUnOIc",
                          "vjn4z_ZK7sFMApBMSbWXuz1N1Agzq_9AwUDxoby0PXs",
                          "VVUJe124ZRn20P-tcSljopVNLDRPAZ3wYc9jhQ2LXng",
                        ],
                      },
                    ),
                  },
                ),
              },
            ),
          ),
        );

        final result = interactor.execute(argument: testArgument);

        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(
                progress: 100,
                contacts: expectedContacts,
              ),
            ),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(
                progress: 100,
                contacts: expectedContacts,
              ),
            ),
          ]),
        );
      });

      test('should handle contacts with only emails', () async {
        final emailOnlyContacts = [
          ContactFixtures.contact1
              .copyWith(phoneNumbers: {})
              .copyWith(
                emails: {
                  Email(address: 'alice1@mail.com'),
                  Email(address: 'alice2@mail.com'),
                  Email(address: 'alice3@mail.com'),
                },
              ),
          ContactFixtures.contact2.copyWith(phoneNumbers: {}),
        ];

        final expectedContacts = [
          Contact(
            id: 'id_1',
            displayName: 'Alice',
            emails: {
              Email(address: 'alice1@mail.com', matrixId: '@alice:matrix.org'),
              Email(address: 'alice2@mail.com', matrixId: '@alice2:matrix.com'),
              Email(address: 'alice3@mail.com'),
            },
            phoneNumbers: const {},
          ),
          Contact(
            id: 'id_2',
            displayName: 'Bob',
            emails: {Email(address: 'bob@gmail.com')},
            phoneNumbers: const {},
          ),
        ];

        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => emailOnlyContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer(
          (_) async => const FederationLookupMxidResponse(
            mappings: {},
            thirdPartyMappings: {
              'tom.domain.com': {'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM'},
            },
          ),
        );

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: FederationTokenRequest(
              homeserverUrl: homeserverUrl,
              mxid: matrixId,
              accessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockFederationIdentityLookupManager.execute(
            arguments: anyNamed('arguments'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Success>(
            FederationIdentityLookupSuccess(
              newContacts: {
                ContactFixtures.contact1.id: FederationContact(
                  id: "id_1",
                  name: "Alice",
                  emails: {
                    FederationEmail(
                      address: 'alice1@mail.com',
                      matrixId: '@alice:matrix.org',
                      thirdPartyIdToHashMap: {
                        "alice1@mail.com": [
                          "lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM",
                        ],
                      },
                    ),
                    FederationEmail(
                      matrixId: '@alice2:matrix.com',
                      address: 'alice2@mail.com',
                      thirdPartyIdToHashMap: {
                        "(252)555-1234": [
                          "5cx7Oz_Q7jf7-Yn6pvCEyiM4HRrbLCk1DwbWaVUnOIc",
                          "vjn4z_ZK7sFMApBMSbWXuz1N1Agzq_9AwUDxoby0PXs",
                          "VVUJe124ZRn20P-tcSljopVNLDRPAZ3wYc9jhQ2LXng",
                        ],
                      },
                    ),
                  },
                ),
              },
            ),
          ),
        );

        final result = interactor.execute(argument: testArgument);

        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(
                progress: 100,
                contacts: expectedContacts,
              ),
            ),
          ]),
        );
      });

      test('should handle different chunk sizes correctly', () async {
        when(
          mockRepository.fetchContacts(),
        ).thenAnswer((_) async => testContacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer(
          (_) async => const FederationLookupMxidResponse(
            mappings: {
              '6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok':
                  '@alice:matrix.org',
            },
            thirdPartyMappings: {},
          ),
        );

        // Test with chunk size of 1
        final result = interactor.execute(
          argument: testArgument,
          lookupChunkSize: 1,
        );

        // We should see progress updates for each chunk
        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            // First chunk (50% progress)
            isA<Right<Failure, Success>>().having(
              (r) => (r.value as GetPhonebookContactsSuccess).progress,
              'progress',
              50,
            ),
            // Second chunk (100% progress)
            isA<Right<Failure, Success>>().having(
              (r) => (r.value as GetPhonebookContactsSuccess).progress,
              'progress',
              100,
            ),
          ]),
        );
      });

      test('should handle partial failures in chunks', () async {
        final contacts = [
          ContactFixtures.contact1,
          ContactFixtures.contact2,
          ContactFixtures.contact3,
          ContactFixtures.contact4,
          ContactFixtures.contact5,
          ContactFixtures.contact6,
        ];

        final exception = Exception('Error');

        final expectedContacts = [
          ContactFixtures.contact1.copyWith(
            phoneNumbers: {
              PhoneNumber(
                number: '(212)555-6789',
                matrixId: '@alice:matrix.org',
              ),
            },
          ),
          ContactFixtures.contact2,
          ContactFixtures.contact3,
          ContactFixtures.contact4,
          ContactFixtures.contact5,
          ContactFixtures.contact6,
        ];

        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        int callCount = 0;
        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const FederationLookupMxidResponse(
              mappings: {},
              thirdPartyMappings: {
                'tom.domain.com': {
                  'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM',
                },
              },
            );
          } else {
            throw exception;
          }
        });

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: FederationTokenRequest(
              homeserverUrl: homeserverUrl,
              mxid: matrixId,
              accessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockFederationIdentityLookupManager.execute(
            arguments: anyNamed('arguments'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, Success>(
            FederationIdentityLookupSuccess(
              newContacts: {
                ContactFixtures.contact1.id: FederationContact(
                  id: "id_1",
                  name: "Alice",
                  phoneNumbers: {
                    FederationPhone(
                      number: '(212)555-6789',
                      matrixId: '@alice:matrix.org',
                      thirdPartyIdToHashMap: {
                        "(212)555-6789": [
                          "lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM",
                        ],
                      },
                    ),
                  },
                ),
              },
            ),
          ),
        );

        final result = interactor.execute(
          argument: testArgument,
          lookupChunkSize: 2,
        );

        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            // First chunk succeeds
            isA<Right<Failure, Success>>(),
            // Final result is a partial failure
            Left<Failure, Success>(
              LookUpPhonebookContactPartialFailed(
                exception: TwakeLookupChunkException(exception.toString()),
                contacts: expectedContacts,
              ),
            ),
          ]),
        );
      });

      test('should handle complete failure in all chunks', () async {
        final contacts = [
          ContactFixtures.contact1,
          ContactFixtures.contact2,
          ContactFixtures.contact3,
          ContactFixtures.contact4,
          ContactFixtures.contact5,
          ContactFixtures.contact6,
        ];

        final exception = Exception('Error');

        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => throw exception);

        final result = interactor.execute(
          argument: testArgument,
          lookupChunkSize: 2,
        );

        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            // Final result is a partial failure
            Left<Failure, Success>(
              LookUpPhonebookContactPartialFailed(
                exception: TwakeLookupChunkException(exception.toString()),
                contacts: contacts,
              ),
            ),
          ]),
        );
      });

      test('should handle third party mapping failures gracefully', () async {
        final contacts = [
          ContactFixtures.contact1,
          ContactFixtures.contact2,
          ContactFixtures.contact3,
          ContactFixtures.contact4,
          ContactFixtures.contact5,
          ContactFixtures.contact6,
        ];

        final exception = Exception('Error');

        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        int callCount = 0;
        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return const FederationLookupMxidResponse(
              mappings: {},
              thirdPartyMappings: {
                'tom.domain.com': {
                  'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM',
                },
              },
            );
          } else {
            throw exception;
          }
        });

        // Setup the third party lookup manager to fail
        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: FederationTokenRequest(
              homeserverUrl: homeserverUrl,
              mxid: matrixId,
              accessToken: accessToken,
            ),
          ),
        ).thenAnswer(
          (_) async => Left<Failure, Success>(
            RequestTokenFailure(
              exception: 'Third party token request failed',
              contacts: testContacts,
            ),
          ),
        );

        final result = interactor.execute(argument: testArgument);

        // The process should still complete successfully with the main mappings
        // even if third party mappings fail
        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
            ),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
            ),
          ]),
        );
      });

      test('should handle empty mappings in lookup response', () async {
        final contacts = [
          ContactFixtures.contact1,
          ContactFixtures.contact2,
          ContactFixtures.contact3,
          ContactFixtures.contact4,
          ContactFixtures.contact5,
          ContactFixtures.contact6,
        ];

        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);

        when(
          mockRequestTokenManager.execute(
            federationTokenRequest: testTokenRequest,
          ),
        ).thenAnswer(
          (_) async => const Right<Failure, Success>(
            FederationIdentityRequestTokenSuccess(
              tokenInformation: tokenInformation,
            ),
          ),
        );

        when(
          mockIdentityLookupManager.register(
            federationUrl: federationUrl,
            tokenInformation: tokenInformation,
          ),
        ).thenAnswer(
          (_) async => const FederationRegisterResponse(
            token: 'aB7c9Dz4EfGh5iJkLm3nOp==',
          ),
        );

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        );

        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer((_) async => hashDetails);

        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: anyNamed('federationUrl'),
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer(
          (_) async => const FederationLookupMxidResponse(
            mappings: {},
            thirdPartyMappings: {},
          ),
        );

        final result = interactor.execute(argument: testArgument);

        // The process should still complete successfully but without matrix IDs
        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
            ),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(progress: 100, contacts: contacts),
            ),
          ]),
        );
      });
    });
  });
}
