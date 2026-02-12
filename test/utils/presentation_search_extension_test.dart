import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/extension/presentation_search_extension.dart';

void main() {
  group('doesMatchKeyword test with Display name', () {
    test('WHEN displayName is null'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: null,
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN displayName does not match keyword'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: 'hi',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN displayName matches keyword'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('matrix_u'), true);
    });

    test('WHEN keyword is empty'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword(''), true);
    });
  });

  group('doesMatchKeyword test with email', () {
    test('WHEN email is null'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: null,
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN email does not match keyword'
        'THEN returns false', () {
      final search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        emails: {
          PresentationEmail(
            email: 'email1@gmail.com',
            thirdPartyId: 'third_party_id',
            thirdPartyIdType: ThirdPartyIdType.email,
          ),
        },
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN email matches keyword'
        'THEN returns true', () {
      final search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        emails: {
          PresentationEmail(
            email: 'email1@gmail.com',
            thirdPartyId: 'third_party_id',
            thirdPartyIdType: ThirdPartyIdType.email,
          ),
          PresentationEmail(
            email: 'email1@gmail.com',
            thirdPartyId: 'third_party_id',
            thirdPartyIdType: ThirdPartyIdType.email,
          ),
        },
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('email1'), true);
    });

    test('WHEN keyword is empty'
        'THEN returns true', () {
      final search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        emails: {
          PresentationEmail(
            email: 'email1@gmail.com',
            thirdPartyId: 'third_party_id',
            thirdPartyIdType: ThirdPartyIdType.email,
          ),
        },
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword(''), true);
    });
  });

  group('doesMatchKeyword test with phone', () {
    test('WHEN email is null'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: null,
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN email does not match keyword'
        'THEN returns false', () {
      final search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        phoneNumbers: {
          PresentationPhoneNumber(
            phoneNumber: '123456789',
            thirdPartyId: 'third_party_id',
            thirdPartyIdType: ThirdPartyIdType.msisdn,
          ),
        },
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN email matches keyword'
        'THEN returns true', () {
      final search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        phoneNumbers: {
          PresentationPhoneNumber(
            phoneNumber: '123456789',
            thirdPartyId: 'third_party_id',
            thirdPartyIdType: ThirdPartyIdType.msisdn,
          ),
        },
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('12345'), true);
    });

    test('WHEN keyword is empty'
        'THEN returns true', () {
      final search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        phoneNumbers: {
          PresentationPhoneNumber(
            phoneNumber: '123456789',
            thirdPartyId: 'third_party_id',
            thirdPartyIdType: ThirdPartyIdType.msisdn,
          ),
        },
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword(''), true);
    });
  });

  group('doesMatchKeyword test with matrixId', () {
    test('WHEN matrixId is null'
        'THEN returns false', () {
      const search = ContactPresentationSearch(displayName: 'matrix_user');
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN matrixId does not match keyword'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test('WHEN matrixId matches keyword'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('matrix_'), true);
    });

    test('WHEN keyword is empty'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword(''), true);
    });
  });

  test('WHEN all fields matches keyword'
      'THEN returns true', () {
    final search = ContactPresentationSearch(
      displayName: 'matrix',
      matrixId: 'direct_chat_matrix_1',
      emails: {
        PresentationEmail(
          email: 'matrix_1@gmail.com',
          thirdPartyId: 'third_party_id',
          thirdPartyIdType: ThirdPartyIdType.email,
        ),
      },
    );
    expect(search.doesMatchKeyword('matrix'), true);
  });
}
