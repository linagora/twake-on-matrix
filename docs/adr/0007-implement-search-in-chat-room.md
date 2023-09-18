# 7. Implementing Search Functionality in Chat Room

Date: 2023-09-11

## Status

Accepted

## Context

- The server does not support search functionality through the API.
- All messages are encrypted within the body.
- The Hive database serves as a key-value storage and does not support search operations.

## Decision

- Utilize Timeline.requestHistory to retrieve previous messages (limited to 100 messages per request).
- Employ Dart for finding the index of the first matching message.
- When the user presses next/previous, search for the index of the next matching message.

## Consequences

- Performance will be affected as searches need to be conducted in RAM.
- Particularly in cases where no matching message is found, a complete scan of messages will be necessary.
- Currently, there is a maximum limit of 1000 most recent messages, older messages will not be retrievable.