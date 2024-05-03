# 2. Cancel the stream subscription when not listen to its anymore

Date: 2024-03-05

## Status

Accepted

## Context

Our application extensively utilizes Streams for data handling. Given that some of these Streams are singleton and others are not, managing StreamSubscriptions is crucial. For instance, each Timeline object initiates three StreamSubscriptions. Without proper cancellation of these subscriptions, memory leaks occur.

## Decision

Specifically, within the `getTimeline()` method, Timeline objects are generated primarily for their callbacks, leading to the neglect of the actual objects. This oversight results in the leakage of three StreamSubscriptions per Timeline. Notably, during the initialization of the chat screen, `getTimeline()` is invoked multiple times, significantly increasing the risk of memory leaks. The resolved approach is to actively manage Timeline objects and ensure all associated StreamSubscriptions are canceled when they are no longer needed.

- Tickets references:
1. TW-1650: cancel StreamSubscription of timeline when not used anymore

## Consequences

By implementing this strategy, we substantially free up memory resources. Additionally, since some StreamSubscriptions are linked to substantial objects, managing these subscriptions effectively also releases these heavy objects from memory, enhancing overall application performance.
