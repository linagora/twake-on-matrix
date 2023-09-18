# 8. Apply DioCacheInterceptor for caching API

Date: 2023-09-18

## Status

Accepted

## Context

- Call an API repeatedly.
- In some screens, we rebuild the whole screen so the widgets are rebuilt. => Call back an API multiple times. 
- Because HomeServer has `rate-limited`, it may be blocked if we call an API repeatedly and many times
## Decision

- Improved Performance: Caching responses can significantly improve application performance by reducing the need to fetch data from the server repeatedly.
Cached responses can be served quickly, reducing the latency for users.

- Reduced Network Usage: Caching can reduce the amount of data transferred over the network,
which can be especially important for users with limited data plans or in situations with slow or unreliable network connections.

- Offline Support: Cached responses can be used when the device is offline or when the server is unreachable.
This can provide a seamless user experience, even when there's no network connectivity.

- Load Balancing: Caching can help distribute the load on the server by reducing the number of redundant requests.
This can prevent overloading the server during peak usage times.

- Faster UI Updates: In applications with frequently changing data, caching can help speed up UI updates.
By serving cached data while fetching fresh data in the background, you can provide a more responsive user interface.

- Reduced Server Load: Caching reduces the number of requests reaching the server, which can help reduce the server's load and infrastructure costs.

- Optimized Bandwidth: Caching can help optimize bandwidth usage, especially in scenarios where clients are downloading large resources like images or files.
Cached resources can be reused without re-downloading.

- Customizable Cache Policies: Dio cache interceptors often allow you to define cache policies,
such as cache expiration times, cache size limits, and cache key strategies, giving you fine-grained control over how and what to cache.

## Consequences

- Increased Network Traffic: Without caching, your application will need to fetch data from the server every time it's requested.
This can result in increased network traffic, especially if the same data is frequently requested.

- Slower Performance: Fetching data from the server on every request can lead to slower performance,
as network latency and server processing times can introduce delays in displaying data to the user.

- Higher Server Load: Without caching, your server may experience higher loads due to the repeated requests for the same data.
This can impact the server's performance and scalability, especially during peak usage periods.

- Increased Data Usage: For mobile applications, not caching data can lead to higher data usage,
which can be costly for users with limited data plans and can also result in slower loading times for users with slower network connections.