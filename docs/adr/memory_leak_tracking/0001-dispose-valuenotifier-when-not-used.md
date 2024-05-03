# 1. Dispose ValueNotifier when not used anymore

Date: 2024-03-05

## Status

Accepted

## Context

In our UI code, ValueNotifier is frequently used for its simplicity and robustness in rebuilding widgets. However, post-utilization management of ValueNotifier is often neglected. Proper handling of ValueNotifier is crucial for stabilizing memory usage and enhancing app performance.

## Decision

Typically, ValueNotifiers are disposed of in the `dispose()` method within widget lifecycles. However, exceptions occur in scenarios involving interactors. Some interactors continue to use ValueNotifier even after yielding a state, due to their singleton nature. Disposing of ValueNotifier immediately after widget disposal can lead to exceptions because the interactor may still be active. To address this, we propose two solutions:
1. Dispose of the ValueNotifier when the interactor's activity concludes.
2. Refrain from using ValueNotifier in conjunction with interactors.

- Tickets references:
1. TW-1650: dispose ValueNotifier when not use anymore in video player
2. About the VideoPlayer (there are still some leakings, but its not critical right now - we wait for the owner's response - (here)[https://github.com/media-kit/media-kit/issues/776])
## Consequences

Implementing these practices ensures that ValueNotifiers are properly collected by the garbage collector, eliminating memory leaks associated with their misuse. This decision fosters more reliable and efficient memory management within our applications.