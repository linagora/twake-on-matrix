import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() {
    getIt.registerSingleton(const SearchEngine());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  group('IterableAddressBookExtension', () {
    group('searchAddressBooks', () {
      final books = [
        AddressBook(displayName: 'Alice', mxid: '@alice:server.com'),
        AddressBook(displayName: 'Bob', mxid: '@bob:server.com'),
        AddressBook(displayName: 'Élodie Martin', mxid: '@elodie:server.com'),
      ];

      test(
        'searchAddressBooks should return all entries when keyword is empty',
        () {
          expect(books.searchAddressBooks('').length, 3);
        },
      );

      test('searchAddressBooks should filter contacts by displayName', () {
        final results = books.searchAddressBooks('Alice');
        expect(results.length, 1);
        expect(results.first.displayName, 'Alice');
      });

      test('searchAddressBooks should filter contacts by mxid', () {
        final results = books.searchAddressBooks('@bob');
        expect(results.length, 1);
        expect(results.first.mxid, '@bob:server.com');
      });

      test(
        'searchAddressBooks should return empty when keyword matches nothing',
        () {
          expect(books.searchAddressBooks('Charlie').length, 0);
        },
      );

      test('searchAddressBooks should match case-insensitively', () {
        expect(books.searchAddressBooks('alice').length, 1);
        expect(books.searchAddressBooks('ALICE').length, 1);
      });

      test('searchAddressBooks should match despite diacritics in entry', () {
        expect(books.searchAddressBooks('elodie').length, 1);
        expect(books.searchAddressBooks('Elodie').length, 1);
      });

      test(
        'searchAddressBooks should match by mxid when displayName is null',
        () {
          final nullName = [
            AddressBook(displayName: null, mxid: '@nullname:server.com'),
          ];
          expect(nullName.searchAddressBooks('nullname').length, 1);
          expect(nullName.searchAddressBooks('anything').length, 0);
        },
      );

      test(
        'searchAddressBooks should match by displayName when mxid is null',
        () {
          final nullMxid = [AddressBook(displayName: 'Foo', mxid: null)];
          expect(nullMxid.searchAddressBooks('Foo').length, 1);
          expect(nullMxid.searchAddressBooks('@foo').length, 0);
        },
      );
    });
  });
}
