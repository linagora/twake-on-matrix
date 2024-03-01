# 17. Remove `setState` for reply message

Date: 2024-03-01

## Status

Accepted

## Context

- Change from `bool replyEvent` to `ValueNotifier replyEventNotifier`.
- When click on reply button, we will update `replyEventNotifier` and show the reply message.
- Remove `setState` for reply func.

## Consequences

- We're make sure for first time click on reply button, it's work well.
- We are limited to 1 use of `setState` for responding to events.
- We're migrating `Chat` to phase out funcs that use setState.
In addition to the reply message, we will continue to migrate other functions