# 4. Better way to get the current location and current context

Date: 2023-08-08


## Status

- Issue: [#418](https://github.com/linagora/twake-on-matrix/issues/418)

## Context

```
 Can't get `activeRoomId`
 Can't go to new screen when in any state or screen position without context
```

## Root cause

1. Can't get current `location`
2. Can't get current `BuildContext`
```
* Reason: 
1. We rely on the location to verify if a roomid exists, but the BackgroundPush class lacks a context. 
Consequently, obtaining the current location based on context is not possible within this class.

2. When a notification is received in the foreground, background, or terminated states, and the user taps on the notification, the app opens. 
However, it doesn't navigate to the correct screen according to the roomid, resulting in the error message "No GoRouter found in context". 
This is because the current context cannot be accessed within that class at that point in time.
```

## Decision

- I recommend for guys need read and understand about `go_router` and I found a similar issue raised by the community. Follow it it's really good.
- [#12983](https://github.com/flutter/flutter/issues/129833) 
- I think it's current workaround for this issue. Wait for the next version of `go_router` to support this issue.

1. I use `GoRouter` inside `BackgroundPush` service to get current location and current context.

2. Func get current `location` and get `activeRoomID`

```
String? get roomId {
    return routerDelegate?.currentConfiguration.pathParameters['roomid'];
}
```

3. Func get current `BuildContext` with `GlobalKey<NavigatorState>` from `GoRouterDelegate` inside `GoRouter` class

```
BuildContext? get currentContext => routerDelegate?.navigatorKey.currentContext;
```

## Consequences
1. Can check current location for `roomid` exists.
2. User click on notification (foreground, background, or terminated states), navigator to correct screen according to `roomid`
