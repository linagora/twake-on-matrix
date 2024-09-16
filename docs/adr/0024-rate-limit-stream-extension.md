# 23. Implement Real-time Avatar Updates in Chat List

Date: 2024-08-20

## Status

Accepted

## Context

Currently, when a user changes their avatar or a group avatar is updated, the chat list items do not reflect these changes in real-time. On the web platform, users must reload the page to see the updated avatars. This leads to an inconsistent user experience and delays in displaying the most current information.

## Decision

We will implement a new function called `rateLimitWithSyncUpdate` to complement our existing `rateLimit` function. This new function will:

1. Maintain the rate-limiting functionality of the original `rateLimit` function.
2. Capture and process `syncUpdate` events received from the server.
3. Use the `syncUpdate` events to identify which rooms or private chats have new avatars.
4. Trigger real-time updates to the relevant chat list items without requiring a page reload.

## Consequences

### Positive

- Improved user experience with real-time avatar updates in the chat list.
- Reduced need for manual page reloads to see updated avatars.
- More consistent information display across the application.

### Negative

- Increased complexity in the client-side code to handle real-time updates.
- Potential for increased network traffic due to more frequent updates.