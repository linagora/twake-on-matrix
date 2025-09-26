import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';

// Mock Client class
class MockClient extends Mock implements Client {}

void main() {
  group('isContainsExternal test', () {
    // Helper to create PresentationContact
    PresentationContact makeContact({
      ContactType? type,
      String? matrixId,
    }) {
      return PresentationContact(
        type: type,
        matrixId: matrixId,
        displayName: '',
        emails: const {},
        phoneNumbers: const {},
        id: '',
        status: null,
      );
    }

    test('returns true if type is external', () {
      final contact =
          makeContact(type: ContactType.external, matrixId: '@user:domain.com');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns false if type is local and domains match', () {
      final contact = makeContact(matrixId: '@user:domain.com');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isFalse);
    });

    test('returns true if type is local and domains do not match', () {
      final contact = makeContact(matrixId: '@user:other.com');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns true if type is external and domains do not match', () {
      final contact =
          makeContact(type: ContactType.external, matrixId: '@user:other.com');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns true if type is external and matrixId is null', () {
      final contact = makeContact(type: ContactType.external, matrixId: null);
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns true if type is external and userID is null', () {
      final contact =
          makeContact(type: ContactType.external, matrixId: '@user:domain.com');
      final client = MockClient();
      when(client.userID).thenReturn(null);
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns false if type is local, matrixId is null, userID is null',
        () {
      final contact = makeContact(matrixId: null);
      final client = MockClient();
      when(client.userID).thenReturn(null);
      expect(contact.isContainsExternal(client), isFalse);
    });

    test(
        'returns true if type is local, matrixId is empty, userID matches empty',
        () {
      final contact = makeContact(matrixId: '');
      final client = MockClient();
      when(client.userID).thenReturn('');
      expect(contact.isContainsExternal(client), isTrue);
    });

    test(
        'returns false if type is local, matrixId is empty, userID is not empty',
        () {
      final contact = makeContact(matrixId: '');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isFalse);
    });

    test('returns true if type is external, matrixId is empty', () {
      final contact = makeContact(type: ContactType.external, matrixId: '');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns true if type is external, userID is empty', () {
      final contact =
          makeContact(type: ContactType.external, matrixId: '@user:domain.com');
      final client = MockClient();
      when(client.userID).thenReturn('');
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns false if type is local, matrixId is null, userID is not null',
        () {
      final contact = makeContact(matrixId: null);
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isFalse);
    });

    test('returns false if type is local, matrixId is not null, userID is null',
        () {
      final contact = makeContact(matrixId: '@user:domain.com');
      final client = MockClient();
      when(client.userID).thenReturn(null);
      expect(contact.isContainsExternal(client), isFalse);
    });

    test('returns true if type is external, matrixId and userID are null', () {
      final contact = makeContact(type: ContactType.external, matrixId: null);
      final client = MockClient();
      when(client.userID).thenReturn(null);
      expect(contact.isContainsExternal(client), isTrue);
    });

    test('returns true if type is external, matrixId and userID are empty', () {
      final contact = makeContact(type: ContactType.external, matrixId: '');
      final client = MockClient();
      when(client.userID).thenReturn('');
      expect(contact.isContainsExternal(client), isFalse);
    });

    test('returns false if type is local, matrixId and userID are empty', () {
      final contact = makeContact(matrixId: '');
      final client = MockClient();
      when(client.userID).thenReturn('');
      expect(contact.isContainsExternal(client), isFalse);
    });

    test(
        'returns false if type is local, matrixId is whitespace, userID is whitespace',
        () {
      final contact = makeContact(matrixId: '   ');
      final client = MockClient();
      when(client.userID).thenReturn('   ');
      expect(
        contact.isContainsExternal(client),
        isFalse,
      );
    });

    test('returns true if type is external, matrixId is whitespace', () {
      final contact = makeContact(type: ContactType.external, matrixId: '   ');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isFalse);
    });

    test('returns false if type is local, matrixId is invalid format', () {
      final contact = makeContact(matrixId: 'invalid');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isFalse);
    });

    test('returns true if type is external, matrixId is invalid format', () {
      final contact =
          makeContact(type: ContactType.external, matrixId: 'invalid');
      final client = MockClient();
      when(client.userID).thenReturn('@me:domain.com');
      expect(contact.isContainsExternal(client), isTrue);
    });
  });
}
