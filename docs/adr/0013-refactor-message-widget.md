# 13. refactor message widget

Date: 2023-06-12

## Status

Accepted

## Context

The Message widget requires refactoring as it currently spans approximately 1000 lines of code,
making it challenging to read due to Dart formatting issues and its reliance on a large controller.
This widget is intended for reuse in various contexts, such as threads and pinned messages.

## Decision

- Eliminate the dependency on the chat controller entirely in the Message widget.
- Optimize optional parameters, aiming for minimal usage and preferring child classes when
  appropriate.
- If the file exceeds 300 lines of code, create a child widget and relocate it to a separate file.
- For complex logic, introduce mixins or stateful widgets.
- Transfer utility methods to extensions or other classes to facilitate reuse.

## Consequences

The Message class is now under 300 lines of code and no longer relies on the controller. Child
widgets have been moved to separate files for improved reusability.