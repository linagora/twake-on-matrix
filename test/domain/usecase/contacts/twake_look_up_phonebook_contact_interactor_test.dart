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
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_argument.dart';
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_phonebook_contact_interactor.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/identity_lookup_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../fixtures/contact_fixtures.dart';
import 'twake_look_up_phonebook_contact_interactor_test.mocks.dart';

@GenerateMocks([
  PhonebookContactRepository,
  IdentityLookupManager,
  HiveContactRepository,
  SharedPreferencesContactCacheManager,
])
void main() {
  late MockPhonebookContactRepository mockRepository;
  late MockIdentityLookupManager mockIdentityLookupManager;
  late MockHiveContactRepository mockHiveContactRepository;
  late MockSharedPreferencesContactCacheManager
  mockSharedPreferencesContactCacheManager;
  late TwakeLookupPhonebookContactInteractor interactor;

  setUp(() {
    mockRepository = MockPhonebookContactRepository();
    mockIdentityLookupManager = MockIdentityLookupManager();
    mockHiveContactRepository = MockHiveContactRepository();
    mockSharedPreferencesContactCacheManager =
        MockSharedPreferencesContactCacheManager();

    final getIt = GetIt.instance;

    getIt.registerFactory<PhonebookContactRepository>(() => mockRepository);
    getIt.registerFactory<IdentityLookupManager>(
      () => mockIdentityLookupManager,
    );
    getIt.registerFactory<HiveContactRepository>(
      () => mockHiveContactRepository,
    );
    getIt.registerFactory<SharedPreferencesContactCacheManager>(
      () => mockSharedPreferencesContactCacheManager,
    );

    interactor = TwakeLookupPhonebookContactInteractor();
  });

  tearDown(() {
    getIt.reset();
  });

  group('TwakeLookupPhonebookContactInteractor', () {
    test(
      'Success case - emits loading, then success states with contacs size of one chunk',
      () async {
        // Arrange
        final contacts = [ContactFixtures.contact1, ContactFixtures.contact2];

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
              PhoneNumber(number: '(212)555-1234', matrixId: '@bob:matrix.org'),
            },
            emails: {Email(address: 'bob@gmail.com')},
          ),
        ];

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        );

        final argument = TwakeLookUpArgument(
          homeServerUrl: 'https://example.com',
          withAccessToken: 'token',
        );

        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);
        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: argument.homeServerUrl,
            registeredToken: argument.withAccessToken,
          ),
        ).thenAnswer((_) async => hashDetails);
        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: argument.homeServerUrl,
            request: anyNamed('request'),
            registeredToken: argument.withAccessToken,
          ),
        ).thenAnswer(
          (_) async => const FederationLookupMxidResponse(
            mappings: {
              '6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok':
                  '@alice:matrix.org',
              'WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM': '@bob:matrix.org',
            },
            inactiveMappings: {},
          ),
        );

        // Act
        final result = interactor.execute(argument: argument);

        // Assert
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

    test('Contacts in many chunks need to process all', () {
      final contacts = [
        ContactFixtures.contact1,
        ContactFixtures.contact2,
        ContactFixtures.contact3,
        ContactFixtures.contact4,
        ContactFixtures.contact5,
        ContactFixtures.contact6,
      ];

      final expectedContactsInSecondState = [
        Contact(
          id: 'id_1',
          displayName: 'Alice',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-6789', matrixId: '@alice:matrix.org'),
          },
          emails: {Email(address: 'alice@gmail.com')},
        ),
        Contact(
          id: 'id_2',
          displayName: 'Bob',
          phoneNumbers: {
            PhoneNumber(number: '(212)555-1234', matrixId: '@bob:matrix.org'),
          },
          emails: {Email(address: 'bob@gmail.com')},
        ),
      ];

      final expectedContactsInThirdState = [
        ...expectedContactsInSecondState,
        Contact(
          id: 'id_3',
          displayName: 'Charlie',
          phoneNumbers: {
            PhoneNumber(
              number: '(212)555-2345',
              matrixId: '@charlie:matrix.org',
            ),
          },
          emails: const {},
        ),
        Contact(
          id: 'id_4',
          displayName: 'Diana',
          emails: {Email(address: 'diana@gmail.com')},
          phoneNumbers: const {},
        ),
      ];

      final expectedContactsInLastState = [
        ...expectedContactsInThirdState,
        Contact(
          id: 'id_5',
          displayName: 'Eve',
          phoneNumbers: {PhoneNumber(number: '(212)555-4567')},
          emails: const {},
        ),
        Contact(
          id: 'id_6',
          displayName: 'Frank',
          phoneNumbers: const {},
          emails: {
            Email(address: 'frank@gmail.com', matrixId: '@frank:matrix.org'),
          },
        ),
      ];

      const hashDetails = FederationHashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'pepper',
      );
      final argument = TwakeLookUpArgument(
        homeServerUrl: 'https://example.com',
        withAccessToken: 'token',
      );
      when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);
      when(
        mockIdentityLookupManager.getHashDetails(
          federationUrl: argument.homeServerUrl,
          registeredToken: argument.withAccessToken,
        ),
      ).thenAnswer((_) async => hashDetails);

      int callCount = 0;
      when(
        mockIdentityLookupManager.lookupMxid(
          federationUrl: argument.homeServerUrl,
          request: anyNamed('request'),
          registeredToken: argument.withAccessToken,
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const FederationLookupMxidResponse(
            mappings: {
              '6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok':
                  '@alice:matrix.org',
              'WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM': '@bob:matrix.org',
            },
            inactiveMappings: {},
          );
        } else if (callCount == 2) {
          return const FederationLookupMxidResponse(
            mappings: {
              'fIlWJrJ7CeAiqVEtt2ySsyNyv-22zGa5TclJcmKBWeo':
                  '@charlie:matrix.org',
            },
            inactiveMappings: {},
          );
        } else {
          return const FederationLookupMxidResponse(
            mappings: {
              'irZfJc6e_28cwWqEi-gCODlx2FpZqiyTdbl-PNHTDr4':
                  '@frank:matrix.org',
            },
            inactiveMappings: {},
          );
        }
      });

      // Act
      final result = interactor.execute(argument: argument, lookupChunkSize: 2);

      // Assert
      expect(
        result,
        emitsInOrder(<dynamic>[
          const Right<Failure, Success>(GetPhonebookContactsLoading()),
          Right<Failure, Success>(
            GetPhonebookContactsSuccess(
              progress: 33,
              contacts: expectedContactsInSecondState,
            ),
          ),
          Right<Failure, Success>(
            GetPhonebookContactsSuccess(
              progress: 66,
              contacts: expectedContactsInThirdState,
            ),
          ),
          Right<Failure, Success>(
            GetPhonebookContactsSuccess(
              progress: 100,
              contacts: expectedContactsInLastState,
            ),
          ),
          Right<Failure, Success>(
            GetPhonebookContactsSuccess(
              progress: 100,
              contacts: expectedContactsInLastState,
            ),
          ),
        ]),
      );
    });

    // test('Contact also in inactiveMappings case', () async {
    //   // Arrange
    //   final contacts = [
    //     ContactFixtures.contact1,
    //     ContactFixtures.contact2,
    //   ];
    //
    //   final expectedContacts = [
    //     Contact(
    //       id: 'id_1',
    //       displayName: 'Alice',
    //       phoneNumbers: {
    //         PhoneNumber(
    //           number: '(212)555-6789',
    //           matrixId: '@alice:matrix.org',
    //           thirdPartyIdToHashMap: {
    //             "(212)555-6789": [
    //               "6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok",
    //             ],
    //           },
    //         ),
    //       },
    //       emails: {
    //         Email(
    //           address: 'alice@gmail.com',
    //           thirdPartyIdToHashMap: {
    //             "alice@gmail.com": [
    //               "0OWxtHmcUFS0KCHxRc2E8SrcU28Q-5EuRT5MJxnDdkg",
    //             ],
    //           },
    //         ),
    //       },
    //     ),
    //     Contact(
    //       id: 'id_2',
    //       displayName: 'Bob',
    //       phoneNumbers: {
    //         PhoneNumber(
    //           number: '(212)555-1234',
    //           matrixId: '@bob:matrix.org',
    //           thirdPartyIdToHashMap: {
    //             "(212)555-1234": [
    //               "WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM",
    //             ],
    //           },
    //         ),
    //       },
    //       emails: {
    //         Email(
    //           address: 'bob@gmail.com',
    //           thirdPartyIdToHashMap: {
    //             "bob@gmail.com": [
    //               "vd5fBacH_IoS6u1BuTJW5NYNdplO8pRrNBbUjCUiQ6M",
    //             ],
    //           },
    //         ),
    //       },
    //     ),
    //   ];
    //
    //   const hashDetails = FederationHashDetailsResponse(
    //     algorithms: {'sha256'},
    //     lookupPepper: 'pepper',
    //   );
    //
    //   final argument = TwakeLookUpArgument(
    //     homeServerUrl: 'https://example.com',
    //     withAccessToken: 'token',
    //   );
    //
    //   when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);
    //   when(
    //     mockIdentityLookupManager.getHashDetails(
    //       federationUrl: argument.homeServerUrl,
    //       registeredToken: argument.withAccessToken,
    //     ),
    //   ).thenAnswer((_) async => hashDetails);
    //   when(
    //     mockIdentityLookupManager.lookupMxid(
    //       federationUrl: argument.homeServerUrl,
    //       request: anyNamed('request'),
    //       registeredToken: argument.withAccessToken,
    //     ),
    //   ).thenAnswer(
    //     (_) async => const FederationLookupMxidResponse(
    //       mappings: {
    //         "6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok": '@alice:matrix.org',
    //       },
    //       inactiveMappings: {
    //         'WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM': '@bob:matrix.org',
    //       },
    //     ),
    //   );
    //
    //   // Act
    //   final result = interactor.execute(argument: argument);
    //
    //   // Assert
    //   expect(
    //     result,
    //     emitsInOrder(<dynamic>[
    //       const Right<Failure, Success>(GetPhonebookContactsLoading()),
    //       Right<Failure, Success>(
    //         GetPhonebookContactsSuccess(
    //           progress: 100,
    //           contacts: expectedContacts,
    //         ),
    //       ),
    //       Right<Failure, Success>(
    //         GetPhonebookContactsSuccess(
    //           progress: 100,
    //           contacts: expectedContacts,
    //         ),
    //       ),
    //     ]),
    //   );
    // });

    test('Empty contacts case - emits loading, then empty state', () async {
      // Arrange
      when(mockRepository.fetchContacts()).thenAnswer((_) async => []);

      // Act
      final result = interactor.execute(
        argument: TwakeLookUpArgument(
          homeServerUrl: 'https://example.com',
          withAccessToken: 'token',
        ),
      );

      // Assert
      expect(
        result,
        emitsInOrder(<dynamic>[
          const Right<Failure, Success>(GetPhonebookContactsLoading()),
          const Left<Failure, Success>(GetPhonebookContactsIsEmpty()),
        ]),
      );
    });

    test(
      'Error fetching contacts case - emits loading, then failure',
      () async {
        final expectedException = Exception('Error');
        // Arrange
        when(mockRepository.fetchContacts()).thenThrow(expectedException);

        // Act
        final result = interactor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: 'https://example.com',
            withAccessToken: 'token',
          ),
        );

        // Assert
        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Left<Failure, Success>(
              GetPhoneBookContactFailure(exception: expectedException),
            ),
          ]),
        );
      },
    );

    test(
      'Error getting hash details case - emits loading, then failure',
      () async {
        // Arrange
        final expectedException = Exception('Error');
        final contacts = [const Contact(id: '1', displayName: 'Test 1')];
        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);
        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: anyNamed('federationUrl'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenThrow(expectedException);

        // Act
        final result = interactor.execute(
          argument: TwakeLookUpArgument(
            homeServerUrl: 'https://example.com',
            withAccessToken: 'token',
          ),
        );

        // Assert
        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Left<Failure, Success>(
              GetHashDetailsFailure(exception: expectedException),
            ),
          ]),
        );
      },
    );

    test(
      'Error looking up MXIDs case - emits loading, then failure if all chunks failed',
      () async {
        // Arrange
        final exception = Exception("error");
        final expectedException = TwakeLookupChunkException(
          exception.toString(),
        );

        final contacts = [const Contact(id: '1', displayName: 'Test 1')];
        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        );
        final argument = TwakeLookUpArgument(
          homeServerUrl: 'https://example.com',
          withAccessToken: 'token',
        );
        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);
        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: argument.homeServerUrl,
            registeredToken: argument.withAccessToken,
          ),
        ).thenAnswer((_) async => hashDetails);
        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: argument.homeServerUrl,
            request: anyNamed('request'),
            registeredToken: argument.withAccessToken,
          ),
        ).thenThrow(exception);

        // Act
        final result = interactor.execute(argument: argument);

        // Assert
        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Left<Failure, Success>(
              LookUpPhonebookContactPartialFailed(
                exception: expectedException,
                contacts: contacts,
              ),
            ),
          ]),
        );
      },
    );

    test(
      'Error looking up MXIDs case - emits loading, then failure if the some chunks failed but still have chunk success',
      () async {
        // Arrange
        final exception = Exception("error");
        final expectedException = TwakeLookupChunkException(
          exception.toString(),
        );

        final contacts = [
          ContactFixtures.contact1,
          ContactFixtures.contact2,
          ContactFixtures.contact3,
          ContactFixtures.contact4,
        ];

        final expectedContactsInSecondState = [
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
              PhoneNumber(number: '(212)555-1234', matrixId: '@bob:matrix.org'),
            },
            emails: {Email(address: 'bob@gmail.com')},
          ),
        ];

        final expectedContactsInLastState = [
          ...expectedContactsInSecondState,
          ContactFixtures.contact3,
          ContactFixtures.contact4,
        ];

        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        );
        final argument = TwakeLookUpArgument(
          homeServerUrl: 'https://example.com',
          withAccessToken: 'token',
        );
        when(mockRepository.fetchContacts()).thenAnswer((_) async => contacts);
        when(
          mockIdentityLookupManager.getHashDetails(
            federationUrl: argument.homeServerUrl,
            registeredToken: argument.withAccessToken,
          ),
        ).thenAnswer((_) async => hashDetails);

        int callCount = 0;
        when(
          mockIdentityLookupManager.lookupMxid(
            federationUrl: argument.homeServerUrl,
            request: anyNamed('request'),
            registeredToken: argument.withAccessToken,
          ),
        ).thenAnswer((_) async {
          if (callCount == 0) {
            callCount++;
            return const FederationLookupMxidResponse(
              mappings: {
                '6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok':
                    '@alice:matrix.org',
                'WYOGPQyKEyY0iTxQoPTfk58eQvGi0_hpP2hI0S8cQeM':
                    '@bob:matrix.org',
              },
              inactiveMappings: {},
            );
          } else {
            throw exception;
          }
        });

        // Act
        final result = interactor.execute(
          argument: argument,
          lookupChunkSize: 2,
        );

        // Assert
        expect(
          result,
          emitsInOrder(<dynamic>[
            const Right<Failure, Success>(GetPhonebookContactsLoading()),
            Right<Failure, Success>(
              GetPhonebookContactsSuccess(
                progress: 50,
                contacts: expectedContactsInSecondState,
              ),
            ),
            Left<Failure, Success>(
              LookUpPhonebookContactPartialFailed(
                exception: expectedException,
                contacts: expectedContactsInLastState,
              ),
            ),
          ]),
        );
      },
    );
  });
}
