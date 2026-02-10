import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:fluffychat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatrixDioCacheInterceptor - addUriSupportsCache', () {
    late MatrixDioCacheInterceptor interceptor;
    late CacheOptions cacheOptions;

    setUp(() {
      cacheOptions = CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.request,
        hitCacheOnErrorExcept: [401, 403],
        maxStale: const Duration(days: 7),
        priority: CachePriority.normal,
        cipher: null,
        keyBuilder: CacheOptions.defaultCacheKeyBuilder,
        allowPostMethod: false,
      );
      interceptor = MatrixDioCacheInterceptor(options: cacheOptions);
    });

    test('WHEN adding a single URI '
        'THEN the URI should be added to the cache support list', () {
      // Arrange
      const uri =
          'https://matrix.example.com/_twake/v1/user_info/@user:example.com';

      // Act
      interceptor.addUriSupportsCache([uri]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 1);
      expect(interceptor.uriSupportsCacheForTesting, contains(uri));
    });

    test('WHEN adding multiple unique URIs '
        'THEN all URIs should be added to the cache support list', () {
      // Arrange
      const uri1 =
          'https://matrix.example.com/_twake/v1/user_info/@user1:example.com';
      const uri2 =
          'https://matrix.example.com/_twake/v1/user_info/@user2:example.com';
      const uri3 =
          'https://matrix.example.com/_twake/v1/user_info/@user3:example.com';

      // Act
      interceptor.addUriSupportsCache([uri1, uri2, uri3]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 3);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([uri1, uri2, uri3]),
      );
    });

    test('WHEN adding duplicate URIs in the same call '
        'THEN only unique URIs should be added', () {
      // Arrange
      const uri =
          'https://matrix.example.com/_twake/v1/user_info/@user:example.com';

      // Act
      interceptor.addUriSupportsCache([uri, uri, uri]);

      // Assert - Only one instance should be added
      expect(interceptor.uriSupportsCacheForTesting.length, 1);
      expect(interceptor.uriSupportsCacheForTesting, contains(uri));
    });

    test('WHEN adding a URI that was previously added '
        'THEN the duplicate URI should not be added again', () {
      // Arrange
      const uri =
          'https://matrix.example.com/_twake/v1/user_info/@user:example.com';

      // Act
      interceptor.addUriSupportsCache([uri]);
      interceptor.addUriSupportsCache([uri]); // Add again

      // Assert - Should still have only one instance
      expect(interceptor.uriSupportsCacheForTesting.length, 1);
      expect(interceptor.uriSupportsCacheForTesting, contains(uri));
    });

    test('WHEN adding an empty list of URIs '
        'THEN no URIs should be added and no error should occur', () {
      // Arrange
      const List<String> emptyList = [];

      // Act
      interceptor.addUriSupportsCache(emptyList);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 0);
      expect(interceptor.uriSupportsCacheForTesting, isEmpty);
    });

    test('WHEN adding URIs with different paths from same domain '
        'THEN all URIs should be added successfully', () {
      // Arrange
      const uri1 =
          'https://matrix.example.com/_twake/v1/user_info/@user:example.com';
      const uri2 = 'https://matrix.example.com/_twake/v1/addressbook';
      const uri3 = 'https://matrix.example.com/_twake/v1/recoveryWords';

      // Act
      interceptor.addUriSupportsCache([uri1, uri2, uri3]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 3);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([uri1, uri2, uri3]),
      );
    });

    test('WHEN adding URIs from different domains '
        'THEN all URIs should be added successfully', () {
      // Arrange
      const uri1 =
          'https://matrix.example.com/_twake/v1/user_info/@user:example.com';
      const uri2 = 'https://other.example.com/api/v1/users';
      const uri3 = 'https://api.third.com/resources';

      // Act
      interceptor.addUriSupportsCache([uri1, uri2, uri3]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 3);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([uri1, uri2, uri3]),
      );
    });

    test('WHEN adding URIs with special characters '
        'THEN URIs should be added successfully', () {
      // Arrange
      const uri1 =
          'https://matrix.example.com/_twake/v1/user_info/@user:example.com?param=value';
      const uri2 =
          'https://matrix.example.com/_twake/v1/user_info/@user:example.com#fragment';
      const uri3 =
          'https://matrix.example.com/_twake/v1/user_info/@user%40example.com';

      // Act
      interceptor.addUriSupportsCache([uri1, uri2, uri3]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 3);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([uri1, uri2, uri3]),
      );
    });

    test('WHEN adding very long URIs '
        'THEN URIs should be added successfully', () {
      // Arrange
      const longUri =
          'https://matrix.example.com/_twake/v1/user_info/@verylongusername'
          'withlotsofcharactersinthename:example.com?param1=value1&param2=value2'
          '&param3=value3&param4=value4';

      // Act
      interceptor.addUriSupportsCache([longUri]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 1);
      expect(interceptor.uriSupportsCacheForTesting, contains(longUri));
    });

    test('WHEN adding URIs incrementally across multiple calls '
        'THEN all unique URIs should be accumulated', () {
      // Arrange
      const uri1 = 'https://matrix.example.com/uri1';
      const uri2 = 'https://matrix.example.com/uri2';
      const uri3 = 'https://matrix.example.com/uri3';

      // Act
      interceptor.addUriSupportsCache([uri1]);
      expect(interceptor.uriSupportsCacheForTesting.length, 1);

      interceptor.addUriSupportsCache([uri2]);
      expect(interceptor.uriSupportsCacheForTesting.length, 2);

      interceptor.addUriSupportsCache([uri3]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 3);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([uri1, uri2, uri3]),
      );
    });

    test('WHEN adding a mix of new and existing URIs '
        'THEN only new URIs should be added', () {
      // Arrange
      const existingUri1 = 'https://matrix.example.com/existing1';
      const existingUri2 = 'https://matrix.example.com/existing2';
      const newUri1 = 'https://matrix.example.com/new1';
      const newUri2 = 'https://matrix.example.com/new2';

      // Act
      interceptor.addUriSupportsCache([existingUri1, existingUri2]);
      expect(interceptor.uriSupportsCacheForTesting.length, 2);

      interceptor.addUriSupportsCache([
        existingUri1,
        newUri1,
        existingUri2,
        newUri2,
      ]);

      // Assert - Should have 4 unique URIs total
      expect(interceptor.uriSupportsCacheForTesting.length, 4);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([existingUri1, existingUri2, newUri1, newUri2]),
      );
    });

    test('WHEN adding URIs with different protocols '
        'THEN all URIs should be added successfully', () {
      // Arrange
      const httpsUri = 'https://matrix.example.com/_twake/v1/user_info';
      const httpUri = 'http://matrix.example.com/_twake/v1/user_info';

      // Act
      interceptor.addUriSupportsCache([httpsUri, httpUri]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 2);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([httpsUri, httpUri]),
      );
    });

    test('WHEN adding URIs with trailing slashes vs without '
        'THEN both should be treated as unique URIs', () {
      // Arrange
      const uriWithSlash = 'https://matrix.example.com/_twake/v1/user_info/';
      const uriWithoutSlash = 'https://matrix.example.com/_twake/v1/user_info';

      // Act
      interceptor.addUriSupportsCache([uriWithSlash, uriWithoutSlash]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 2);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([uriWithSlash, uriWithoutSlash]),
      );
    });

    test('WHEN adding URIs with query parameters '
        'THEN URIs with different query parameters should be unique', () {
      // Arrange
      const uri1 = 'https://matrix.example.com/api?param1=value1';
      const uri2 = 'https://matrix.example.com/api?param1=value2';
      const uri3 = 'https://matrix.example.com/api?param2=value1';

      // Act
      interceptor.addUriSupportsCache([uri1, uri2, uri3]);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 3);
      expect(
        interceptor.uriSupportsCacheForTesting,
        containsAll([uri1, uri2, uri3]),
      );
    });

    test('WHEN adding a large number of URIs '
        'THEN all URIs should be added successfully', () {
      // Arrange
      final largeUriList = List.generate(
        100,
        (index) =>
            'https://matrix.example.com/_twake/v1/user_info/@user$index:example.com',
      );

      // Act
      interceptor.addUriSupportsCache(largeUriList);

      // Assert
      expect(interceptor.uriSupportsCacheForTesting.length, 100);
      expect(interceptor.uriSupportsCacheForTesting, containsAll(largeUriList));
    });
  });
}
