# 20. Keyboard is disappeared then appeared if we send message in a chat which found from search

Date: 2024-03-12

## Status

Accepted

- Issue: [#1545](https://github.com/linagora/twake-on-matrix/issues/1545)

## Context

- In TextField use onTapOutside to hide the keyboard but don't know exactly which screen the keyboard is enabled on.
Therefore, when opening the keyboard on screen A and then switching to screen B, TextField A is still listening onTapOutside. 
So Keyboard is disappeared then appears

## Decision
- Check exactly screen the keyboard is enabled in `dismissKeyboard` function.

```dart
void dismissKeyboard(BuildContext context) {
  if (ModalRoute.of(context)?.isCurrent == true) {
    if (FocusManager.instance.primaryFocus?.hasFocus == true) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}

```
  
## Consequences

- The keyboard will not disappear and then reappear when switching screens.