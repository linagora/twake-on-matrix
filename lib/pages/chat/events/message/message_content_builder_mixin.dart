import 'dart:math';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_time_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/pages/chat/events/message/display_name_widget.dart';
import 'package:fluffychat/presentation/model/chat/events/message/message_metrics.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

mixin MessageContentBuilderMixin {
  MessageMetrics? getSizeMessageBubbleWidth(
    BuildContext context, {
    required Event event,
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
      event,
      maxWidth,
    ).width;

    final messageMetrics = _getMessageMetrics(
      context,
      event,
      maxWidth,
    );

    if (ownMessage || hideDisplayName) {
      return MessageMetrics(
        totalMessageWidth: messageMetrics.totalMessageWidth,
        isNeedAddNewLine: messageMetrics.isNeedAddNewLine,
      );
    }

    const rightSpaceDisplayName = 16.0;

    final totalDisplayNameWidth = sizeWidthDisplayName + rightSpaceDisplayName;

    final totalWidth = max<double>(
      totalDisplayNameWidth,
      messageMetrics.totalMessageWidth,
    );

    return MessageMetrics(
      totalMessageWidth: totalWidth,
      isNeedAddNewLine: messageMetrics.isNeedAddNewLine,
    );
  }

  TextPainter _paintDisplayName(
    BuildContext context,
    Event event,
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
    Event event,
    double maxWidth,
  ) {
    final double messageMaxWidth = maxWidth - AppConfig.messagePadding;
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
    Event event,
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

  MessageMetrics _getMessageMetrics(
    BuildContext context,
    Event event,
    double maxWidth,
  ) {
    const spaceMessageAndTime = 4.0;
    const paddingMessage = AppConfig.messagePadding;

    final paintedMessageText = _paintMessageText(
      context,
      event,
      maxWidth,
    );
    final sizeMessageTime = _getWidthMessageTime(
      context,
      event,
      maxWidth,
    );
    final messageTimeAndPaddingWidth = sizeMessageTime + spaceMessageAndTime;
    final messageTextWidth = paintedMessageText.width;
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

    double totalMessageWidth = messageTextWidth + paddingMessage;
    bool isNeedAddNewLine;

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

    final metrics = MessageMetrics(
      totalMessageWidth: totalMessageWidth,
      isNeedAddNewLine: isNeedAddNewLine,
    );

    return metrics;
  }

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

  bool isContainsTagName(Event event) {
    const matrixToScheme = "https://matrix.to/#/";
    const matrixScheme = "matrix:";

    final formattedText = event.formattedText;

    if (formattedText.isEmpty || !formattedText.isContainsATag()) {
      return false;
    }

    final List<String> listHrefs = formattedText.extractAllHrefs();

    for (final href in listHrefs) {
      final hrefLower = href.toLowerCase();

      if (!hrefLower.startsWith(matrixToScheme) &&
          !hrefLower.startsWith(matrixScheme)) continue;

      var isPill = true;

      if (hrefLower.startsWith(matrixToScheme)) {
        isPill = _handleMatrixToSchemeTagName(href, matrixToScheme);
      } else {
        isPill = _handleMatrixSchemeTagName(hrefLower);
      }

      if (isPill) {
        return true;
      }
    }

    return false;
  }

  bool _handleMatrixToSchemeTagName(String href, String matrixToScheme) {
    final urlPart = href.substring(matrixToScheme.length).split('?').first;
    var identifier = '';
    try {
      identifier = Uri.decodeComponent(urlPart);
    } catch (_) {
      identifier = urlPart;
    }
    return RegExp(r'^[@#!+][^:]+:[^\/]+$').firstMatch(identifier) != null;
  }

  bool _handleMatrixSchemeTagName(String hrefLower) {
    final match = RegExp(r'^matrix:(r|roomid|u)\/([^\/]+)$')
        .firstMatch(hrefLower.split('?').first.split('#').first);
    if (match == null || match.group(2) == null) {
      return false;
    }

    final sigil = {
      'r': '#',
      'roomid': '!',
      'u': '@',
    }[match.group(1)];

    return sigil != null;
  }

  bool isContainsSpecialHTMLTag(Event event) {
    final formattedText = event.formattedText;
    final specialTags = [
      'b',
      'strong',
      'tt',
      'h[1-6]',
      'code',
      'pre',
      'blockquote',
      'i',
      'em',
    ];
    final specialTagsPattern = specialTags.join('|');
    final specialTagRegex = RegExp(
      '<($specialTagsPattern)[^>]*>.*</($specialTagsPattern)>|<hr[^>]*>',
      multiLine: true,
      dotAll: true,
    );
    return specialTagRegex.hasMatch(formattedText);
  }
}
