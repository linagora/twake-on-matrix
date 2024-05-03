# 3. Handling Stream Subscriptions Without Nullifying Variables Post-Cancellation

Date: 2024-03-05

## Status

Accepted

## Context

The `cancel()` method for StreamSubscriptions is asynchronous. A common mistake is to set the variable holding the StreamSubscription to null immediately after calling `cancel()`. Doing so can render the cancellation ineffective, as the nullification may lead to the garbage collector prematurely collecting the subscription before the cancellation has completed.

## Decision

We will revise our approach to handling cancellations of StreamSubscriptions. Instead of nullifying the variable immediately, we will retain the reference until the cancellation has fully processed. This ensures the `cancel()` operation can complete effectively. Where possible, it is advisable to await the completion of `cancel()` to ensure proper resource management.

Ticket References:
1. TW-1650: remove the streamSubcription, listener in chat controller when not used any more
2. TW-1650: must await on cancel before remove item in list

## Consequences

By adopting this practice, we prevent potential memory leaks and ensure that StreamSubscriptions are properly disposed of. This adjustment in handling ensures more robust and reliable resource management within our applications.
