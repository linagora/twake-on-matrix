# 14. Find to last read a message

Date: 2023-05-2

## Status

Accepted

## Context

The "Get Server Config" API retrieves all configuration information from the backend to the client, currently limited to parameters like media max size. However, a challenge arises as configurations may vary between accounts based on subscription levels or differ across servers.

## Decision

To enhance efficiency and reduce unnecessary server load when sending media like images, videos, and documents, we've introduced a caching mechanism for server configuration requests to /_matrix/media/v3/config. This cache intercepts and stores configuration data, significantly cutting down on redundant requests. To ensure the cache remains effective and current across different user sessions and server changes, we key the cached data using a combination of accessToken and requestUri. This method ensures that the cache is automatically updated for new sessions or when switching accounts, maintaining optimal performance and resource utilization.
```
CacheOptions _getMemCacheOptionsForEachUserLoggedIn() {
    return CacheOptions(
      store: getIt.get<MemCacheStore>(),
      policy: CachePolicy.forceCache,
      hitCacheOnErrorExcept: [404],
      maxStale: const Duration(days: 1),
      keyBuilder: (request) {
        final String accessToken = request.headers['Authorization'];
        final hashedAccessToken = sha256.convert(accessToken.codeUnits);
        Logs().d(
          'DioCacheOption::getMemCacheOptionsForEachClient() key - ${request.uri}$hashedAccessToken',
        );
        return '${request.uri}$hashedAccessToken';
      },
    );
  }
```

## Docs

https://spec.matrix.org/v1.8/client-server-api/#get_matrixmediav3config
https://pub.dev/packages/dio_cache_interceptor