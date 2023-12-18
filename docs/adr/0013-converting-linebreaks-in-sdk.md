# 13. Converting Linebreaks in SDK

Date: 2023-13-12

## Status

Accepted

## Context

In Twake Chat, we allow users to send messages with linebreaks. However, we only limit them to 2 linebreaks in a row. This is to prevent users from sending messages with too many linebreaks, which would make the chat hard to read.

## Decision

- Add a new method (syntax) to the SDK that converts more then 2 linebreaks in a row to 1 linebreak.
- Process the whole message and not line by line before sending it to the server.

```dart
class MultipleLinebreaksSyntax extends InlineSyntax {
  MultipleLinebreaksSyntax() : super(r'\n{2,}');

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Element.empty('br'));
    return true;
  }
}
```

The regex `r'\n{2,}'` matches 2 or more linebreaks in a row.  
If the regex matches, we replace the linebreaks with a `<br>` tag.

```dart

## Consequences

- The SDK will be able to convert more than 2 linebreaks in a row to 1 linebreak.