# 21. Chat message bubbles width

Date: 2024-04-16

## Status

Accepted

## Issue:
[#1666](https://github.com/linagora/twake-on-matrix/issues/1666)

## Context

* We introduced a non-visible timeline at the end of the message body within the `TextSpan` to create a blank space for the visible timeline. However, we did not adjust the non-visible timeline to match the scale of the visible one, leading to an overlap with the text.
* By incorporating a `Widget` at the end of a `TextSpan`, the size of the last line of the message body decreases when the system font size is altered.
* In the process of rendering message bubble, we only computed the width of the plain message body and compared it with the width of display name, using the maximum value for bubble step width. This approach is insufficient as it only considers plain text.

## Decision

* Eliminate the non-visible timeline that follows the message body.
* Re-compute the message body's width by taking into account both the plain text, padding and timeline:

  * Calculating width of plain text: (reduce `maxWidth` by left padding of message `8.0`)
    ```dart
    const double leftMessagePadding = 8.0;
    final double messageMaxWidth = maxWidth - leftMessagePadding;
    return TextPainter(
      textScaler: MediaQuery.of(context).textScaler,
      text: TextSpan(
        text: event.calcLocalizedBodyFallback(
          MatrixLocals(L10n.of(context)!),
          hideReply: true,
          plaintextBody: true,
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: messageMaxWidth);
    ```
  * Calculating the width of the visible timeline, taking into account the pin and seen icon:
    ```dart
    final painTimeText = TextPainter(
      textScaler: MediaQuery.of(context).textScaler,
      text: TextSpan(
        text: DateFormat("HH:mm").format(event.originServerTs),
        style: Theme.of(context).textTheme.bodySmall?.merge(
              TextStyle(
                color: event.timelineOverlayMessage
                    ? Colors.white
                    : LinagoraRefColors.material().tertiary[30],
                letterSpacing: 0.4,
              ),
            ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);

    const pushpinIconSize = MessageStyle.pushpinIconSize;
    const paddingAllPushpin = MessageStyle.paddingAllPushpin;
    const paddingToTimeSpacing = 4.0;
    final seenByRowIconSize = MessageTimeStyle.seenByRowIconSize;
    final paddingTimeAndIcon = MessageTimeStyle.paddingTimeAndIcon;

    double totalWidth = painTimeText.width;

    if (event.isPinned) {
      totalWidth += paddingTimeAndIcon +
          pushpinIconSize +
          paddingAllPushpin +
          paddingToTimeSpacing;
    }

    if (event.isOwnMessage) {
      totalWidth += paddingTimeAndIcon + seenByRowIconSize;
    }

    return totalWidth;
    ```

  * To calculate the total message body width:
    * Use the following logic:
      * If message body contains tag name then create a new line for the timeline.
      * If message body contains special HTML tags: [`b`, `strong`, `tt`, `h[1-6]`, `code`, `pre`, `blockquote`, `i`, `em`] then create new line for the timeline
      * If the last line has sufficient space for the timeline, then the total width equals the sum of the message width and padding.
      * Otherwise, add the width of the timeline to the last line width:
        * If the sum of the last line width and timeline width is less than the maximum width, then the total width equals this sum.
        * If not, set the total width to the maximum width and create a new line for the timeline.
    * Calculating last line width
      ```dart
        final TextRange lastLineRange = paintedMessageText.getLineBoundary(
          paintedMessageText.getPositionForOffset(
            Offset(
              paintedMessageText.size.width,
              paintedMessageText.size.height,
            ),
          ),
        );
        final List<TextBox> lastLineBoxes = paintedMessageText.getBoxesForSelection(
          TextSelection(
            baseOffset: lastLineRange.start,
            extentOffset: lastLineRange.end,
          ),
        );
        final lastLineWidth = lastLineBoxes.last.right;
      ```
    * Calculating total width:
      ```dart
      if (lastLineWidth < messageTextWidth &&
        messageTextWidth - lastLineWidth >= messageTimeAndPaddingWidth &&
        messageTextWidth + paddingMessage < maxWidth) {
        totalMessageWidth = messageTextWidth + paddingMessage;
        isNeedAddNewLine = false;
      } else {
        totalMessageWidth = _calculateTotalMessageWidth(
          lastLineWidth,
          messageTimeAndPaddingWidth,
          paddingMessage,
          maxWidth,
        );

        isNeedAddNewLine = _checkNeedAddNewLine(totalMessageWidth, maxWidth);
      }
      ```
      ```dart
      double _calculateTotalMessageWidth(
        double lastLineWidth,
        double messageTimeAndPaddingWidth,
        double paddingMessage,
        double maxWidth,
      ) {
        final lastLineWithTimeWidth =
            lastLineWidth + messageTimeAndPaddingWidth + paddingMessage;

        if (lastLineWithTimeWidth < maxWidth) {
          return lastLineWithTimeWidth;
        } else {
          return maxWidth;
        }
      }

      bool _checkNeedAddNewLine(double totalMessageWidth, double maxWidth) {
        return totalMessageWidth == maxWidth;
      }
      ```

## Consequences

* Timeline will not overlap the message body