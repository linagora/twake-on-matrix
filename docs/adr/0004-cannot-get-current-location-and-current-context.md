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
- Cannot anymore use router.location to determine where am I in the application and there are certain scenarios 
where I cannot provide a context to GoRouterState.of(context).location, deep link or firebase messages that 
will pop or push some other routes from or to the navigation stack depending on the current location and state.
```

## Decision

- I recommend for guys need read and understand about `go_router` and I found a similar issue raised by the community. Follow it it's really good.
- [#12983](https://github.com/flutter/flutter/issues/129833) 
- I think it's current workaround for this issue. Wait for the next version of `go_router` to support this issue.

1. I use `GoRouter` inside `BackgroundPush` service to get current location and current context.

2. Func get current `location` and get `activeRoomID`

```
String? get roomId {
  return currentContext != null
    ? GoRouterState.of(currentContext!).pathParameters['roomid']
    : '';
}
```

3. Func get current `BuildContext` with `GlobalKey<NavigatorState>` from `GoRouterDelegate` inside `GoRouter` class

```
BuildContext? get currentContext => router?.routerDelegate.navigatorKey.currentState?.context;
```

## Consequences

1. User click on Notification, it not go to correct screen and no action
2. Block func click on Notification
