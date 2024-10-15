import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/extension/presentation_search_extension.dart';

void main() {
  group('doesMatchKeyword test with Display name', () {
    test(
        'WHEN displayName is null'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: null,
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test(
        'WHEN displayName does not match keyword'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'hi',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test(
        'WHEN displayName matches keyword'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('matrix_u'), true);
    });

    test(
        'WHEN keyword is empty'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword(''), true);
    });
  });

  group('doesMatchKeyword test with email', () {
    test(
        'WHEN email is null'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        displayName: null,
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test(
        'WHEN email does not match keyword'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test(
        'WHEN email matches keyword'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'matrix_user@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('matrix_user'), true);
    });

    test(
        'WHEN keyword is empty'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword(''), true);
    });
  });

  group('doesMatchKeyword test with matrixId', () {
    test(
        'WHEN matrixId is null'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        displayName: 'matrix_user',
        email: 'email!@gmail.com',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test(
        'WHEN matrixId does not match keyword'
        'THEN returns false', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('keyword'), false);
    });

    test(
        'WHEN matrixId matches keyword'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword('matrix_'), true);
    });

    test(
        'WHEN keyword is empty'
        'THEN returns true', () {
      const search = ContactPresentationSearch(
        matrixId: 'matrix_id_1',
        email: 'email1@gmail.com',
        displayName: 'matrix_user',
      );
      expect(search.doesMatchKeyword(''), true);
    });
  });

  test(
      'WHEN all fields matches keyword'
      'THEN returns true', () {
    const search = ContactPresentationSearch(
      displayName: 'matrix',
      matrixId: 'direct_chat_matrix_1',
      email: 'matrix@gmail.com',
    );
    expect(search.doesMatchKeyword('matrix'), true);
  });
}
