import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_time.dart';
import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/pages/chat/events/message/reply_content_widget.dart';
import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart' hide Visibility;
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'dart:math';

class MessageContentBuilder extends StatelessWidget {
  final Event event;
  final Timeline timeline;
  final BoxConstraints availableBubbleContraints;
  final void Function(String)? scrollToEventId;
  final void Function(Event)? onSelect;
  final Event? nextEvent;
  final bool selectMode;

  const MessageContentBuilder({
    super.key,
    required this.event,
    required this.timeline,
    required this.availableBubbleContraints,
    this.onSelect,
    this.nextEvent,
    this.scrollToEventId,
    this.selectMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final displayEvent = event.getDisplayEvent(timeline);
    final noPadding = {
      MessageTypes.File,
      MessageTypes.Audio,
    }.contains(event.messageType);
    final sizeMessageBubble = _getSizeMessageBubbleWidth(
      context,
      maxWidth: availableBubbleContraints.maxWidth,
      ownMessage: event.isOwnMessage,
      hideDisplayName: event.hideDisplayName(
        nextEvent,
      ),
    );
    final stepWidth = sizeMessageBubble?.keys.first;
    final isNeedAddNewLine = sizeMessageBubble?.values.first ?? false;
    return Padding(
      padding: EdgeInsets.only(
        bottom: noPadding || event.timelineOverlayMessage ? 0 : 8,
      ),
      child: IntrinsicWidth(
        stepWidth:
            _isContainsTagName() || _isContainsCodeTag() ? null : stepWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (event.relationshipType == RelationshipTypes.reply)
              ReplyContentWidget(
                event: event,
                timeline: timeline,
                scrollToEventId: scrollToEventId,
                ownMessage: event.isOwnMessage,
              ),
            Stack(
              children: [
                MessageContent(
                  displayEvent,
                  textColor: textColor,
                  endOfBubbleWidget: Padding(
                    padding: MessageStyle.paddingTimestamp,
                    child: SelectionContainer.disabled(
                      child: MessageTime(
                        timelineOverlayMessage: event.timelineOverlayMessage,
                        event: event,
                        ownMessage: event.isOwnMessage,
                        timeline: timeline,
                        room: event.room,
                      ),
                    ),
                  ),
                  backgroundColor: event.isOwnMessage
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer
                      : Theme.of(
                          context,
                        ).colorScheme.surface,
                  onTapSelectMode: () => selectMode
                      ? onSelect!(
                          event,
                        )
                      : null,
                  onTapPreview: !selectMode ? () {} : null,
                  ownMessage: event.isOwnMessage,
                ),
                if (event.timelineOverlayMessage)
                  Positioned(
                    right: 8,
                    bottom: 4.0,
                    child: SelectionContainer.disabled(
                      child: Text.rich(
                        WidgetSpan(
                          child: MessageTime(
                            timelineOverlayMessage:
                                event.timelineOverlayMessage,
                            event: event,
                            ownMessage: event.isOwnMessage,
                            timeline: timeline,
                            room: event.room,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isNeedAddNewLine ||
                _isContainsTagName() ||
                _isContainsCodeTag())
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: SelectionContainer.disabled(
                  child: Text.rich(
                    WidgetSpan(
                      child: MessageTime(
                        timelineOverlayMessage: event.timelineOverlayMessage,
                        event: event,
                        ownMessage: event.isOwnMessage,
                        timeline: timeline,
                        room: event.room,
                      ),
                    ),
                  ),
                ),
              ),
            if (event.hasAggregatedEvents(
              timeline,
              RelationshipTypes.edit,
            ))
              Padding(
                padding: MessageStyle.paddingEditButton,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: textColor.withAlpha(
                        164,
                      ),
                      size: 14,
                    ),
                    Text(
                      ' - ${displayEvent.originServerTs.localizedTimeShort(context)}',
                      style: TextStyle(
                        color: textColor.withAlpha(
                          164,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<double?, bool>? _getSizeMessageBubbleWidth(
    BuildContext context, {
    required double maxWidth,
    bool ownMessage = false,
    bool hideDisplayName = false,
  }) {
    final isNotSupportCalcSize = {
      MessageTypes.File,
      MessageTypes.Image,
      MessageTypes.Video,
    }.contains(event.messageType);

    if (isNotSupportCalcSize || event.text.isEmpty) {
      return null;
    }

    final sizeWidthDisplayName = _paintDisplayName(
      context,
      maxWidth,
    ).width;

    final totalMessageWidth = _getWidthMessageAndTime(
      context,
      maxWidth,
    );

    if (ownMessage || hideDisplayName) {
      final Map<double, bool> result = {
        totalMessageWidth.keys.first: totalMessageWidth.values.first,
      };
      return result;
    }

    const rightSpaceDisplayName = 16.0;

    final totalDisplayNameWidth = sizeWidthDisplayName + rightSpaceDisplayName;

    final totalWidth =
        max<double>(totalDisplayNameWidth, totalMessageWidth.keys.first);

    final Map<double, bool> result = {
      totalWidth: totalMessageWidth.values.first,
    };

    return result;
  }

  TextPainter _paintDisplayName(
    BuildContext context,
    double maxWidth,
  ) {
    return TextPainter(
      textScaler: MediaQuery.of(context).textScaler,
      text: TextSpan(
        text: event.senderFromMemoryOrFallback
            .calcDisplayname()
            .shortenDisplayName(
              maxCharacters: DisplayNameWidget.maxCharactersDisplayNameBubble,
            ),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.primary,
            ),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);
  }

  TextPainter _paintMessageText(
    BuildContext context,
    double maxWidth,
  ) {
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
  }

  double _getWidthMessageTime(
    BuildContext context,
    double maxWidth,
  ) {
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
  }

  Map<double, bool> _getWidthMessageAndTime(
    BuildContext context,
    double maxWidth,
  ) {
    const spaceMessageAndTime = 4.0;
    const paddingMessage = 16.0;

    final paintedMessageText = _paintMessageText(
      context,
      maxWidth,
    );

    final sizeMessageTime = _getWidthMessageTime(
      context,
      maxWidth,
    );

    final messageTimeAndPaddingWidth = sizeMessageTime + spaceMessageAndTime;

    final messageTextWidth = paintedMessageText.width;

    double totalMessageWidth = messageTextWidth + paddingMessage;

    bool isNeedAddNewLine = false;

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

    if (lastLineWidth < messageTextWidth) {
      final lastLineToRightBoundarySpace = messageTextWidth - lastLineWidth;
      if (lastLineToRightBoundarySpace >= messageTimeAndPaddingWidth) {
        final messageWithTimeWidth = messageTextWidth + paddingMessage;
        if (messageWithTimeWidth < maxWidth) {
          totalMessageWidth = messageWithTimeWidth;
        } else {
          final lastLineWithTimeWidth =
              lastLineWidth + messageTimeAndPaddingWidth + paddingMessage;
          if (lastLineWithTimeWidth < maxWidth) {
            totalMessageWidth = lastLineWithTimeWidth;
          } else {
            isNeedAddNewLine = true;
            totalMessageWidth = maxWidth;
          }
        }
      } else {
        final lastLineWithTimeWidth =
            lastLineWidth + messageTimeAndPaddingWidth + paddingMessage;
        if (lastLineWithTimeWidth < maxWidth) {
          totalMessageWidth = lastLineWithTimeWidth;
        } else {
          isNeedAddNewLine = true;
          totalMessageWidth = maxWidth;
        }
      }
    } else {
      final lastLineWithTimeWidth =
          lastLineWidth + messageTimeAndPaddingWidth + paddingMessage;
      if (lastLineWithTimeWidth < maxWidth) {
        totalMessageWidth = lastLineWithTimeWidth;
      } else {
        isNeedAddNewLine = true;
        totalMessageWidth = maxWidth;
      }
    }

    final Map<double, bool> result = {
      totalMessageWidth: isNeedAddNewLine,
    };
    return result;
  }

  bool _isContainsTagName() {
    const matrixToScheme = "https://matrix.to/#/";
    const matrixScheme = "matrix:";
    final formattedText = event.formattedText;

    if (formattedText.isNotEmpty && formattedText.isContainsATag()) {
      final List<String> listHrefs = formattedText.extractAllHrefs();
      for (final href in listHrefs) {
        final hrefLower = href.toLowerCase();
        if (hrefLower.startsWith(matrixToScheme) ||
            hrefLower.startsWith(matrixScheme)) {
          var isPill = true;
          var identifier = href;
          if (hrefLower.startsWith(matrixToScheme)) {
            final urlPart =
                href.substring(matrixToScheme.length).split('?').first;
            try {
              identifier = Uri.decodeComponent(urlPart);
            } catch (_) {
              identifier = urlPart;
            }
            isPill =
                RegExp(r'^[@#!+][^:]+:[^\/]+$').firstMatch(identifier) != null;
          } else {
            final match = RegExp(r'^matrix:(r|roomid|u)\/([^\/]+)$')
                .firstMatch(hrefLower.split('?').first.split('#').first);
            isPill = match != null && match.group(2) != null;
            if (isPill) {
              final sigil = {
                'r': '#',
                'roomid': '!',
                'u': '@',
              }[match.group(1)];
              if (sigil == null) {
                isPill = false;
              } else {
                identifier = sigil + match.group(2)!;
              }
            }
          }
          if (isPill) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isContainsCodeTag() {
    final formattedText = event.formattedText;
    final codeTagRegex = RegExp(r'<code[^>]*>.*<\/code>');
    return codeTagRegex.hasMatch(formattedText);
  }
}
