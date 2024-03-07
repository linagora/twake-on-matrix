# 18. Show in chat of media functionality

Date: 2024-03-07

## Status

Accepted

## Context

- We aim to support the `show in chat` feature for media (photos and videos), addressing navigation complexities across different devices and screen sizes. The feature operates smoothly within the chat screen, but challenges arise when implementing it for chat detail screens in group chats or profile info screens in direct chats. Specifically, navigating back to the chat screen varies: desktop screens require a single action, while tablet and mobile screens need two actions.

## Consequences

- To address the complexity of closing the right column (which displays chat details, profile info, or search pages) on the web platform, a direct use of the `pop()` method is ineffective. Instead, the closeRightColumn function must be employed. However, this introduces a cumbersome process where child widgets within the right column need to inherit and trigger this function from their parent widgets, leading to convoluted code patterns.

To streamline this process, we propose a solution: when a child widget needs to close the right column, it should initiate a `pop` action with a specific result which are `MediaViewerPopupResultEnum.closeRightColumnFlag`. This action signals the parent widget, which is responsible for managing the navigation (via the `Navigator.push()` method), to handle the closure of the right column with the `closeRightColumn` function. This approach simplifies the interaction by removing the need for child widgets to directly manage or even be aware of the `closeRightColumn` method, effectively preventing "callback hell" and ensuring a more maintainable codebase.