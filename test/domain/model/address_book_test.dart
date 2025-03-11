import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'searchAddressBooks test',
    () {
      test('should returns all address books when keyword is empty', () {
        final addressBooks = [
          AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
          AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
        ];

        final result = addressBooks.searchAddressBooks('');

        expect(result, addressBooks);
      });

      test('should returns matching address books when keyword is not empty',
          () {
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
    },
  );
}
