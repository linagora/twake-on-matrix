# 5. Matrix SDK receipts not working properly

Date: 2023-09-07

## Status

- Issue: [#418](https://github.com/linagora/twake-on-matrix/issues/347)

## Context

```
Event.receipts() doesn't take into account private rooms/direct chats
```

## Root cause

There are differents maps for `Event.receipts() - event.dart(L323)` : global, mainThread and byThread
```
* Reason: 
1. Global : Receipts for every events, no specific thread
2. MainThread : Receipt for the "main" thread, which is the global timeline without any thread events
3. ByThread : Receipts inside threads


`Event.receipts()` is using the global map, which is not updated when a new event is received.

I realized that the global map is not updated when a new event is received, so the receipts are not updated.
Otherwise, the mainThread map is updated with good and latest informations.

```

## Decision

1. Use `MainThread` map to check if it contains the events informations.
2. If it doesn't we use the `Global` map to get the receipts informations.

## Consequences

1. Since we use the global map only if the mainThread map doesn't contain the receipts informations, there is no side effect and it will work as before.
2. If the mainThread and global maps don't contain the receipts informations, we will not be able to display the receipts informations.