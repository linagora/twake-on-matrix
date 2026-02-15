// test/data/cache/database/cache_database_factory_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/cache/database/cache_database_factory.dart';
import 'package:fluffychat/data/cache/database/cache_database_mobile.dart';
import 'package:fluffychat/data/cache/database/cache_database_web.dart';

void main() {
  group('CacheDatabaseFactory', () {
    test('creates correct implementation for platform', () {
      final database = CacheDatabaseFactory.create();

      if (kIsWeb) {
        expect(database, isA<CacheDatabaseWeb>());
      } else {
        expect(database, isA<CacheDatabaseMobile>());
      }
    });

    test('multiple create calls return new instances', () {
      final database1 = CacheDatabaseFactory.create();
      final database2 = CacheDatabaseFactory.create();

      expect(identical(database1, database2), false);
    });
  });
}
