import 'package:fluffychat/modules/federation_identity_lookup/domain/exceptions/federation_identity_lookup_exceptions.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/repository/federation_identity_lookup_repository.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/usecase/federation_identity_lookup_interactor.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../federation_contact_fixtures.dart';
import 'federation_identity_lookup_interactor_test.mocks.dart';

@GenerateMocks([FederationIdentityLookupRepository])
void main() {
  late FederationIdentityLookupInteractor interactor;
  late MockFederationIdentityLookupRepository mockRepository;

  const testToken = FederationTokenInformation(
    accessToken: 'test_token',
    tokenType: 'test',
  );

  setUp(() {
    mockRepository = MockFederationIdentityLookupRepository();
    interactor = FederationIdentityLookupInteractor(
      federationIdentityLookupRepository: mockRepository,
    );
  });

  group('Registration Failures', () {
    test('should handle registration exceptions', () async {
      when(
        mockRepository.register(tokenInformation: testToken),
      ).thenThrow(Exception('Network error'));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expect a failure'),
      );
      expect(failure, isA<FederationIdentityLookupFailure>());
    });
  });

  group('Hash Calculation', () {
    test('should handle empty contact list', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expect a failure'),
      );
      expect(failure, isA<FederationIdentityCalculationHashesEmpty>());
    });

    test('should handle mixed phone/email contacts', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {
            '6mWe5lBps9Rqabkqc_QIh0-jsdFogvcBi9EWs523fok': '@alice:matrix.com',
            '0OWxtHmcUFS0KCHxRc2E8SrcU28Q-5EuRT5MJxnDdkg':
                '@alice_mail:matrix.com',
          },
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      final contact = (success as FederationIdentityLookupSuccess)
          .newContacts[FederationContactFixtures.contact1.id]!;
      expect(contact.phoneNumbers?.first.matrixId, '@alice:matrix.com');
      expect(contact.emails?.first.matrixId, '@alice_mail:matrix.com');
    });
  });

  group('MXID Lookup', () {
    test('should handle partial mapping matches', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {
            'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM':
                '@alice_pepper1:matrix.com',
            'rJnCyQMaiAcZNw_qB5D5iCCjUdKUKF7Mzl18HMY6DjQ':
                '@alice_pepper2:matrix.com',
          },
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      expect(
        (success as FederationIdentityLookupSuccess)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.phoneNumbers
            ?.first
            .matrixId,
        '@alice_pepper1:matrix.com',
      );
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails
            ?.first
            .matrixId,
        '@alice_pepper2:matrix.com',
      );
    });

    test(
      'should handle partial mapping matches with multiple phone number',
      () async {
        when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
          (_) async => const FederationRegisterResponse(token: 'valid_token'),
        );
        when(
          mockRepository.getHashDetails(registeredToken: 'valid_token'),
        ).thenAnswer(
          (_) async => const FederationHashDetailsResponse(
            algorithms: {'sha256'},
            lookupPepper: 'pepper',
            altLookupPeppers: {'pepper1', 'pepper2'},
          ),
        );
        when(
          mockRepository.lookupMxid(
            request: anyNamed('request'),
            registeredToken: anyNamed('registeredToken'),
          ),
        ).thenAnswer(
          (_) async => const FederationLookupMxidResponse(
            mappings: {
              'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM':
                  '@alice_pepper1:matrix.com',
              'rJnCyQMaiAcZNw_qB5D5iCCjUdKUKF7Mzl18HMY6DjQ':
                  '@alice_pepper2:matrix.com',
            },
          ),
        );

        final contacts = {
          FederationContactFixtures.contact1.id: FederationContactFixtures
              .contact1
              .copyWith(
                phoneNumbers: {
                  FederationPhone(number: '(212)555-6789'),
                  FederationPhone(number: '(213)555-6789'),
                  FederationPhone(number: '(214)555-6789'),
                },
              ),
        };

        final result = await interactor.execute(
          arguments: FederationArguments(
            federationUrl: 'test.server',
            tokenInformation: testToken,
            contactMaps: contacts,
          ),
        );

        expect(result.isRight(), true);
        final success = result.getOrElse(
          () => throw Exception('Expected Success'),
        );
        expect(
          (success as FederationIdentityLookupSuccess)
              .newContacts[FederationContactFixtures.contact1.id]
              ?.phoneNumbers
              ?.length,
          equals(3),
        );
        expect(
          (success)
              .newContacts[FederationContactFixtures.contact1.id]
              ?.phoneNumbers
              ?.first
              .matrixId,
          '@alice_pepper1:matrix.com',
        );
        expect(
          (success)
              .newContacts[FederationContactFixtures.contact1.id]
              ?.emails
              ?.first
              .matrixId,
          '@alice_pepper2:matrix.com',
        );
      },
    );

    test('should handle partial mapping matches with multiple email', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {
            'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM':
                '@alice_pepper1:matrix.com',
            'pF6bycYytq3vJh73tKomRVIK4Npo72FKfemP8ShdMjw':
                '@alice_pepper2:matrix.com',
          },
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id: FederationContactFixtures
            .contact1
            .copyWith(
              emails: {
                FederationEmail(address: 'alice1@gmail.com'),
                FederationEmail(address: 'alice2@gmail.com'),
                FederationEmail(address: 'alice3@gmail.com'),
              },
            ),
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      expect(
        (success as FederationIdentityLookupSuccess)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails
            ?.length,
        equals(3),
      );
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.phoneNumbers
            ?.first
            .matrixId,
        '@alice_pepper1:matrix.com',
      );
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails
            ?.first
            .matrixId,
        '@alice_pepper2:matrix.com',
      );
    });

    test('should handle empty lookup response', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(mappings: {}),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception("Expected failure"),
      );
      expect(
        (failure as FederationIdentityLookupFailure).exception,
        isA<LookUpFederationIdentityNotFoundException>(),
      );
    });
  });

  group('Input Validation', () {
    test('should handle invalid federation URL', () async {
      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: '',
          tokenInformation: testToken,
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expect a failure'),
      );
      expect(failure, isA<NoFederationIdentityURL>());
    });

    test('should handle invalid token information', () async {
      when(
        mockRepository.register(tokenInformation: anyNamed('tokenInformation')),
      ).thenThrow(Exception("Can not register"));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: const FederationTokenInformation(
            accessToken: 'test',
            tokenType: '',
          ),
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expect an exception'),
      );
      expect(failure, isA<FederationIdentityLookupFailure>());
    });

    test('should handle invalid contact data', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
          altLookupPeppers: {'pepper1', 'pepper2'},
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(mappings: {}),
      );

      final Map<String, FederationContact> contacts = {};
      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception("Expected failure"),
      );
      expect(failure, isA<FederationIdentityCalculationHashesEmpty>());
    });
  });

  group('Hash Details', () {
    test('should handle unsupported hash algorithms', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'unsupported algorithm'},
          lookupPepper: 'pepper',
        ),
      );

      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {
            '2125556789 msisdn': '@alice_pepper1:matrix.com',
            'alice@gmail.com email': '@alice_pepper2:matrix.com',
          },
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      expect(
        (success as FederationIdentityLookupSuccess)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.phoneNumbers
            ?.first
            .matrixId,
        '@alice_pepper1:matrix.com',
      );
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails
            ?.first
            .matrixId,
        '@alice_pepper2:matrix.com',
      );
    });

    test('should handle missing lookup pepper', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: null,
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityGetHashDetailsFailure>());
    });

    test('should handle empty algorithms list', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {},
          lookupPepper: 'pepper',
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityGetHashDetailsFailure>());
    });
  });

  group('Registration Response', () {
    test('should handle empty token in registration response', () async {
      when(
        mockRepository.register(tokenInformation: testToken),
      ).thenAnswer((_) async => const FederationRegisterResponse(token: ''));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityRegisterAccountFailure>());
      expect(
        (failure as FederationIdentityRegisterAccountFailure).identityServer,
        'test.server',
      );
    });

    test('should handle null token in registration response', () async {
      when(
        mockRepository.register(tokenInformation: testToken),
      ).thenAnswer((_) async => const FederationRegisterResponse(token: null));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityRegisterAccountFailure>());
    });
  });

  group('Contact Processing', () {
    test('should handle contacts with only phone numbers', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {
            'fIlWJrJ7CeAiqVEtt2ySsyNyv-22zGa5TclJcmKBWeo':
                '@phone_only:matrix.com',
          },
        ),
      );

      final contacts = {
        FederationContactFixtures.contact3.id:
            FederationContactFixtures.contact3,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      expect(
        (success as FederationIdentityLookupSuccess)
            .newContacts[FederationContactFixtures.contact3.id]
            ?.phoneNumbers
            ?.first
            .matrixId,
        '@phone_only:matrix.com',
      );
    });

    test('should handle contacts with only emails', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {
            'UlFCGNN0GkdVtlrZRdhZpDx0vg_omO0PFvD6CB41zPc':
                '@email_only:matrix.com',
          },
        ),
      );

      final contacts = {
        FederationContactFixtures.contact4.id:
            FederationContactFixtures.contact4,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      expect(
        (success as FederationIdentityLookupSuccess)
            .newContacts[FederationContactFixtures.contact4.id]
            ?.emails
            ?.first
            .matrixId,
        '@email_only:matrix.com',
      );
    });

    test('should handle multiple contacts in a single request', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {'hash1': '@alice:matrix.com', 'hash2': '@bob:matrix.com'},
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
        FederationContactFixtures.contact2.id:
            FederationContactFixtures.contact2,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      expect(
        (success as FederationIdentityLookupSuccess).newContacts.length,
        equals(2),
      );
    });

    test('should handle partial matches with no matching hash', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenAnswer(
        (_) async => const FederationLookupMxidResponse(
          mappings: {'unrelated_hash': '@unrelated:matrix.com'},
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id:
            FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result.getOrElse(
        () => throw Exception('Expected Success'),
      );
      // The contact should be returned but without matrix IDs assigned
      expect(
        (success as FederationIdentityLookupSuccess)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.phoneNumbers
            ?.first
            .matrixId,
        isNull,
      );
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails
            ?.first
            .matrixId,
        isNull,
      );
    });
  });

  group('Helper Methods', () {
    test('replacePhoneNumber should handle null inputs', () async {
      final result = interactor.replacePhoneNumber(null, null);
      expect(result, isEmpty);
    });

    test('replacePhoneNumber should replace matching phone number', () async {
      final original = {
        FederationPhone(number: '123'),
        FederationPhone(number: '456'),
      };
      final updated = FederationPhone(
        number: '123',
        matrixId: '@user:matrix.org',
      );

      final result = interactor.replacePhoneNumber(original, updated);

      expect(result.length, 2);
      expect(
        result.firstWhere((p) => p.number == '123').matrixId,
        '@user:matrix.org',
      );
      expect(result.firstWhere((p) => p.number == '456').matrixId, isNull);
    });

    test('replaceEmail should handle null inputs', () async {
      final result = interactor.replaceEmail(null, null);
      expect(result, isEmpty);
    });

    test('replaceEmail should replace matching email', () async {
      final original = {
        FederationEmail(address: 'test@example.com'),
        FederationEmail(address: 'other@example.com'),
      };
      final updated = FederationEmail(
        address: 'test@example.com',
        matrixId: '@user:matrix.org',
      );

      final result = interactor.replaceEmail(original, updated);

      expect(result.length, 2);
      expect(
        result.firstWhere((e) => e.address == 'test@example.com').matrixId,
        '@user:matrix.org',
      );
      expect(
        result.firstWhere((e) => e.address == 'other@example.com').matrixId,
        isNull,
      );
    });

    test('updateContactWithHashes should correctly update contact', () async {
      final contact = FederationContactFixtures.contact1;
      final phoneToHashMap = {
        '(212)555-6789': ['phone_hash1', 'phone_hash2'],
      };
      final emailToHashMap = {
        'alice@gmail.com': ['email_hash1', 'email_hash2'],
      };

      final updatedContact = interactor.updateContactWithHashes(
        contact,
        phoneToHashMap,
        emailToHashMap,
      );

      expect(
        updatedContact.phoneNumbers?.first.thirdPartyIdToHashMap,
        isNotNull,
      );
      expect(
        updatedContact
            .phoneNumbers
            ?.first
            .thirdPartyIdToHashMap?['(212)555-6789'],
        contains('phone_hash1'),
      );
      expect(updatedContact.emails?.first.thirdPartyIdToHashMap, isNotNull);
      expect(
        updatedContact.emails?.first.thirdPartyIdToHashMap?['alice@gmail.com'],
        contains('email_hash1'),
      );
    });
  });

  group('Error Handling and Edge Cases', () {
    test('should handle getHashDetails exceptions', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenThrow(Exception('Network error'));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {
            FederationContactFixtures.contact1.id:
                FederationContactFixtures.contact1,
          },
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityLookupFailure>());
    });

    test('should handle lookupMxid exceptions', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );
      when(
        mockRepository.lookupMxid(
          request: anyNamed('request'),
          registeredToken: anyNamed('registeredToken'),
        ),
      ).thenThrow(Exception('Lookup failed'));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {
            FederationContactFixtures.contact1.id:
                FederationContactFixtures.contact1,
          },
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityLookupFailure>());
    });

    test('should handle contacts with no phone numbers or emails', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );

      final emptyContact = FederationContact(
        id: 'empty_id',
        name: 'Empty Contact',
        phoneNumbers: {},
        emails: {},
      );

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {'empty_id': emptyContact},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityCalculationHashesEmpty>());
    });

    test('should handle null phone numbers and emails in contact', () async {
      when(mockRepository.register(tokenInformation: testToken)).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(
        mockRepository.getHashDetails(registeredToken: 'valid_token'),
      ).thenAnswer(
        (_) async => const FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        ),
      );

      final nullContact = FederationContact(
        id: 'null_id',
        name: 'Null Contact',
        phoneNumbers: null,
        emails: null,
      );

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {'null_id': nullContact},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(
        () => throw Exception('Expected failure'),
      );
      expect(failure, isA<FederationIdentityCalculationHashesEmpty>());
    });
  });
}
