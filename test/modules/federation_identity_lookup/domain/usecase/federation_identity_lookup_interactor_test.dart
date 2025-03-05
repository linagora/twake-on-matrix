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

  const testToken =
      FederationTokenInformation(accessToken: 'test_token', tokenType: 'test');

  setUp(() {
    mockRepository = MockFederationIdentityLookupRepository();
    interactor = FederationIdentityLookupInteractor(
      federationIdentityLookupRepository: mockRepository,
    );
  });

  group('Registration Failures', () {
    test('should handle registration exceptions', () async {
      when(mockRepository.register(
              tokenInformation: testToken,),)
          .thenThrow(Exception('Network error'));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(() => throw Exception('Expect a failure'));
      expect(failure, isA<FederationIdentityLookupFailure>());
    });
  });

  group('Hash Calculation', () {
    test('should handle empty contact list', () async {
      when(mockRepository.register(
              tokenInformation: testToken,),)
          .thenAnswer((_) async =>
              const FederationRegisterResponse(token: 'valid_token'),);
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer((_) async => const FederationHashDetailsResponse(
                algorithms: {'sha256'},
                lookupPepper: 'pepper',
              ),);

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap().getOrElse(() => throw Exception('Expect a failure'));
      expect(
          failure, isA<FederationIdentityCalculationHashesEmpty>(),);
    });

    test('should handle mixed phone/email contacts', () async {
      when(
        mockRepository.register(
          tokenInformation: testToken,
        ),
      ).thenAnswer(
        (_) async => const FederationRegisterResponse(token: 'valid_token'),
      );
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer(
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
            '0OWxtHmcUFS0KCHxRc2E8SrcU28Q-5EuRT5MJxnDdkg': '@alice_mail:matrix.com',
          },
        ),
      );

      final contacts = {
        FederationContactFixtures.contact1.id: FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success = result
          .getOrElse(() => throw Exception('Expected Success'));
      final contact = (success as FederationIdentityLookupSuccess)
          .newContacts[FederationContactFixtures.contact1.id]!;
      expect(contact.phoneNumbers?.first.matrixId, '@alice:matrix.com');
      expect(contact.emails?.first.matrixId, '@alice_mail:matrix.com');
    });
  });

  group('MXID Lookup', () {
    test('should handle partial mapping matches', () async {
      when(mockRepository.register(
              tokenInformation: testToken,),)
          .thenAnswer((_) async => const FederationRegisterResponse(token: 'valid_token'));
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer((_) async => const FederationHashDetailsResponse(
                algorithms: {'sha256'},
                lookupPepper: 'pepper',
                altLookupPeppers: {'pepper1', 'pepper2'},
              ),);
      when(mockRepository.lookupMxid(
        request: anyNamed('request'),
        registeredToken: anyNamed('registeredToken'),
      ),).thenAnswer((_) async => const FederationLookupMxidResponse(
          mappings: {
            'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM': '@alice_pepper1:matrix.com',
            'rJnCyQMaiAcZNw_qB5D5iCCjUdKUKF7Mzl18HMY6DjQ': '@alice_pepper2:matrix.com',
          },),);

      final contacts = {
        FederationContactFixtures.contact1.id: FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success =
          result.getOrElse(() => throw Exception('Expected Success'));
      expect(
          (success as FederationIdentityLookupSuccess)
              .newContacts[FederationContactFixtures.contact1.id]
              ?.phoneNumbers
              ?.first
              .matrixId,
          '@alice_pepper1:matrix.com',);
      expect(
          (success)
              .newContacts[FederationContactFixtures.contact1.id]
              ?.emails
              ?.first
              .matrixId,
          '@alice_pepper2:matrix.com',);
    });

    test('should handle partial mapping matches with multiple phone number', () async {
      when(mockRepository.register(
        tokenInformation: testToken,),)
          .thenAnswer((_) async => const FederationRegisterResponse(token: 'valid_token'));
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer((_) async => const FederationHashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'pepper',
        altLookupPeppers: {'pepper1', 'pepper2'},
      ),);
      when(mockRepository.lookupMxid(
        request: anyNamed('request'),
        registeredToken: anyNamed('registeredToken'),
      ),).thenAnswer((_) async => const FederationLookupMxidResponse(
        mappings: {
          'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM': '@alice_pepper1:matrix.com',
          'rJnCyQMaiAcZNw_qB5D5iCCjUdKUKF7Mzl18HMY6DjQ': '@alice_pepper2:matrix.com',
        },),);

      final contacts = {
        FederationContactFixtures.contact1.id: FederationContactFixtures.contact1
            .copyWith(phoneNumbers: {
              FederationPhone(
                number: '(212)555-6789',
              ),
              FederationPhone(
                number: '(213)555-6789',
              ),
              FederationPhone(
                number: '(214)555-6789',
              ),
            }
        ,),
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success =
      result.getOrElse(() => throw Exception('Expected Success'));
      expect(
        (success as FederationIdentityLookupSuccess)
          .newContacts[FederationContactFixtures.contact1.id]
          ?.phoneNumbers?.length, equals(3),);
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.phoneNumbers
            ?.first
            .matrixId,
        '@alice_pepper1:matrix.com',);
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails
            ?.first
            .matrixId,
        '@alice_pepper2:matrix.com',);
    });

    test('should handle partial mapping matches with multiple email', () async {
      when(mockRepository.register(
        tokenInformation: testToken,),)
          .thenAnswer((_) async => const FederationRegisterResponse(token: 'valid_token'));
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer((_) async => const FederationHashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'pepper',
        altLookupPeppers: {'pepper1', 'pepper2'},
      ),);
      when(mockRepository.lookupMxid(
        request: anyNamed('request'),
        registeredToken: anyNamed('registeredToken'),
      ),).thenAnswer((_) async => const FederationLookupMxidResponse(
        mappings: {
          'lWcTz7CJ9a9OqxlYWsl2MibzKep0abdGl6g3I3t7BPM': '@alice_pepper1:matrix.com',
          'pF6bycYytq3vJh73tKomRVIK4Npo72FKfemP8ShdMjw': '@alice_pepper2:matrix.com',
        },),);

      final contacts = {
        FederationContactFixtures.contact1.id: FederationContactFixtures.contact1
          .copyWith(emails: {
            FederationEmail(
              address: 'alice1@gmail.com',
            ),
            FederationEmail(
              address: 'alice2@gmail.com',
            ),
            FederationEmail(
              address: 'alice3@gmail.com',
            ),
          }
        ,),
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success =
      result.getOrElse(() => throw Exception('Expected Success'));
      expect(
        (success as FederationIdentityLookupSuccess)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails?.length, equals(3),);
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.phoneNumbers
            ?.first
            .matrixId,
        '@alice_pepper1:matrix.com',);
      expect(
        (success)
            .newContacts[FederationContactFixtures.contact1.id]
            ?.emails
            ?.first
            .matrixId,
        '@alice_pepper2:matrix.com',);
    });

    test('should handle empty lookup response', () async {
      when(mockRepository.register(
              tokenInformation: testToken,),)
          .thenAnswer((_) async => const FederationRegisterResponse(token: 'valid_token'));
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer((_) async => const FederationHashDetailsResponse(
                algorithms: {'sha256'},
                lookupPepper: 'pepper',
                altLookupPeppers: {'pepper1', 'pepper2'},
              ),);
      when(mockRepository.lookupMxid(
        request: anyNamed('request'),
        registeredToken: anyNamed('registeredToken'),
      ),).thenAnswer((_) async => const FederationLookupMxidResponse(mappings: {}));

      final contacts = {
        FederationContactFixtures.contact1.id: FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap()
          .getOrElse(() => throw Exception("Expected failure"));
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
      final failure = result.swap().getOrElse(() => throw Exception('Expect a failure'));
      expect(failure, isA<NoFederationIdentityURL>());
    });

    test('should handle invalid token information', () async {
      when(mockRepository.register(tokenInformation: anyNamed('tokenInformation')))
        .thenThrow(Exception("Can not register"));

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: const FederationTokenInformation(accessToken: 'test', tokenType: ''),
          contactMaps: {},
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap()
          .getOrElse(() => throw Exception('Expect an exception'));
      expect(failure, isA<FederationIdentityLookupFailure>());
    });

    test('should handle invalid contact data', () async {
      when(mockRepository.register(
              tokenInformation: testToken,),)
          .thenAnswer((_) async => const FederationRegisterResponse(token: 'valid_token'));
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer((_) async => const FederationHashDetailsResponse(
                algorithms: {'sha256'},
                lookupPepper: 'pepper',
                altLookupPeppers: {'pepper1', 'pepper2'},
              ),);
      when(mockRepository.lookupMxid(
        request: anyNamed('request'),
        registeredToken: anyNamed('registeredToken'),
      ),).thenAnswer((_) async => const FederationLookupMxidResponse(mappings: {}));

      final Map<String, FederationContact> contacts = {};
      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isLeft(), true);
      final failure = result.swap()
          .getOrElse(() => throw Exception("Expected failure"));
      expect(
        failure,
        isA<FederationIdentityCalculationHashesEmpty>(),
      );
    });
  });

  group('Hash Details', () {
    test('should handle unsupported hash algorithms', () async {
      when(mockRepository.register(
          tokenInformation: testToken,),)
          .thenAnswer((_) async => const FederationRegisterResponse(token: 'valid_token'));
      when(mockRepository.getHashDetails(registeredToken: 'valid_token'))
          .thenAnswer((_) async => const FederationHashDetailsResponse(
        algorithms: {'unsupported algorithm'},
        lookupPepper: 'pepper',
      ),);

      when(mockRepository.lookupMxid(
        request: anyNamed('request'),
        registeredToken: anyNamed('registeredToken'),
      ),).thenAnswer((_) async => const FederationLookupMxidResponse(
          mappings: {
            '2125556789 msisdn': '@alice_pepper1:matrix.com',
            'alice@gmail.com email': '@alice_pepper2:matrix.com',
          },),);

      final contacts = {
        FederationContactFixtures.contact1.id: FederationContactFixtures.contact1,
      };

      final result = await interactor.execute(
        arguments: FederationArguments(
          federationUrl: 'test.server',
          tokenInformation: testToken,
          contactMaps: contacts,
        ),
      );

      expect(result.isRight(), true);
      final success =
          result.getOrElse(() => throw Exception('Expected Success'));
      expect(
          (success as FederationIdentityLookupSuccess)
              .newContacts[FederationContactFixtures.contact1.id]
              ?.phoneNumbers
              ?.first
              .matrixId,
          '@alice_pepper1:matrix.com',);
      expect(
          (success)
              .newContacts[FederationContactFixtures.contact1.id]
              ?.emails
              ?.first
              .matrixId,
          '@alice_pepper2:matrix.com',);
    });
  });
}
