import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('searchAddressBooks test', () {
    test('should returns all address books when keyword is empty', () {
      final addressBooks = [
        AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
        AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
      ];

      final result = addressBooks.searchAddressBooks('');

      expect(result, addressBooks);
    });

    test('should returns matching address books when keyword is not empty', () {
      final addressBooks = [
        AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
        AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
        AddressBook(displayName: 'Charlie', mxid: '@charlie789.com'),
      ];

      final result = addressBooks.searchAddressBooks('bob');

      expect(result, [addressBooks[1]]);
    });

    test('should returns matching all address books when keyword is a', () {
      final addressBooks = [
        AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
        AddressBook(displayName: 'Bob', mxid: '@a.bob456.com'),
      ];

      final result = addressBooks.searchAddressBooks('a');

      expect(result, addressBooks);
    });

    test('returns empty list when no matches found', () {
      final addressBooks = [
        AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
        AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
      ];

      final result = addressBooks.searchAddressBooks('charlie');

      expect(result, []);
    });

    test('should return matching address books regardless of case', () {
      final addressBooks = [
        AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
        AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
      ];

      final result = addressBooks.searchAddressBooks('ALICE');

      expect(result, [addressBooks[0]]);
    });

    test('should return matching address books with partial matches', () {
      final addressBooks = [
        AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
        AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
        AddressBook(displayName: 'Charlie', mxid: '@charlie789.com'),
      ];

      final result = addressBooks.searchAddressBooks('ali');

      expect(result, [addressBooks[0]]);
    });

    test('should handle special characters in search keyword', () {
      final addressBooks = [
        AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
        AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
        AddressBook(displayName: 'Charlie', mxid: '@charlie789.com'),
      ];

      final result = addressBooks.searchAddressBooks('@bob');

      expect(result, [addressBooks[1]]);
    });

    test('should return empty list when address book is empty', () {
      final List<AddressBook> addressBooks = [];

      final result = addressBooks.searchAddressBooks('alice');

      expect(result, []);
    });
  });

  group('combineDuplicateAddressBooks test', () {
    test('SHOULD return unique address books', () {
      final addressBooks = {
        AddressBook(
          id: 'id_1',
          addressbookId: 'addressbook_id_1',
          mxid: '@mxid_1.com',
        ),
        AddressBook(
          id: 'id_1',
          addressbookId: 'addressbook_id_1',
          mxid: '@mxid_1.com',
        ),
      };

      final expected = {
        AddressBook(
          id: 'id_1',
          addressbookId: 'addressbook_id_1',
          mxid: '@mxid_1.com',
        ),
      };

      final result = addressBooks.combineDuplicateAddressBooks();

      expect(result.length, expected.length);

      expect(result.first.id, expected.first.id);

      expect(result.first.addressbookId, expected.first.addressbookId);

      expect(result.first.mxid, expected.first.mxid);
    });

    test(
      'SHOULD return the same address books when there are no duplicates',
      () {
        final addressBooks = {
          AddressBook(
            id: 'id_1',
            addressbookId: 'addressbook_id_1',
            mxid: '@mxid_1.com',
          ),
          AddressBook(
            id: 'id_2',
            addressbookId: 'addressbook_id_2',
            mxid: '@mxid_2.com',
          ),
        };

        final expected = {
          AddressBook(
            id: 'id_1',
            addressbookId: 'addressbook_id_1',
            mxid: '@mxid_1.com',
          ),
          AddressBook(
            id: 'id_2',
            addressbookId: 'addressbook_id_2',
            mxid: '@mxid_2.com',
          ),
        };

        final result = addressBooks.combineDuplicateAddressBooks();

        expect(result.length, expected.length);
        expect(result, expected);
      },
    );

    test('SHOULD handle an empty list of address books', () {
      final addressBooks = <AddressBook>{};

      final result = addressBooks.combineDuplicateAddressBooks();

      expect(result.isEmpty, true);
    });

    test('SHOULD handle address books with null fields', () {
      final addressBooks = {
        AddressBook(id: null, addressbookId: 'addressbook_id_1', mxid: null),
        AddressBook(id: 'id_2', addressbookId: null, mxid: null),
        AddressBook(id: 'id_3', addressbookId: 'addressbook_id_3', mxid: null),
      };

      final result = addressBooks.combineDuplicateAddressBooks();

      expect(result.length, 0);
    });

    test(
      'SHOULD handle address books with same matrixId and different other fields',
      () {
        final addressBooks = {
          AddressBook(
            id: 'id_1',
            addressbookId: 'addressbook_id_1',
            mxid: 'mxid_1',
          ),
          AddressBook(
            id: null,
            addressbookId: 'addressbook_id_2',
            mxid: 'mxid_1',
          ),
          AddressBook(
            id: 'id_3',
            addressbookId: 'addressbook_id_3',
            mxid: 'mxid_1',
          ),
        };

        final expected = {
          AddressBook(
            id: 'id_3',
            addressbookId: 'addressbook_id_3',
            mxid: 'mxid_1',
          ),
        };

        final result = addressBooks.combineDuplicateAddressBooks();

        expect(result.length, expected.length);

        expect(result.first.id, expected.first.id);

        expect(result.first.addressbookId, expected.first.addressbookId);

        expect(result.first.mxid, expected.first.mxid);
      },
    );
  });
}
