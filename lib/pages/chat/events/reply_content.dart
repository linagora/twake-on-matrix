import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/pages/chat/events/reply_content_style.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/markdown_fix.dart';
import 'package:twake_chat/pages/chat/optional_selection_container_disabled.dart';
import 'package:twake_chat/utils/extension/event_info_extension.dart';
import 'package:twake_chat/utils/extension/mime_type_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/widgets/blur_hash_background.dart';

import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix/matrix.dart';

import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'html_message.dart';

class ReplyContent extends StatelessWidget {
  final Event replyEvent;
  final Timeline? timeline;

  /// Set above a reply: draws the "Reply to" caption and the quoted bubble,
  /// aligned to this physical side (end is right). Null draws the preview of
  /// the composer.
  final CrossAxisAlignment? quoteAlignment;

  /// How far the message bubble covers the bottom of the quoted bubble.
  final double quoteOverlap;

  /// The quoted message is not loaded: the caption names nobody.
  final bool quoteSenderUnknown;

  const ReplyContent(
    this.replyEvent, {
    super.key,
    this.timeline,
    this.quoteAlignment,
    this.quoteOverlap = 0,
    this.quoteSenderUnknown = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget replyBody;
    final timeline = this.timeline;
    final displayEvent = timeline != null
        ? replyEvent.getDisplayEventWithoutEditEvent(timeline)
        : replyEvent;
    if (AppConfig.renderHtml &&
        [
          EventTypes.Message,
          EventTypes.Encrypted,
        ].contains(displayEvent.type) &&
        [
          MessageTypes.Text,
          MessageTypes.Notice,
          MessageTypes.Emote,
        ].contains(displayEvent.messageType) &&
        !displayEvent.redacted &&
        displayEvent.content['format'] == 'org.matrix.custom.html' &&
        displayEvent.content['formatted_body'] is String) {
      String html = fixDoubleEncodedAutolinks(
        fixDoubleEncodedCodeBlocks(
          displayEvent.content['formatted_body'] as String? ?? '',
        ),
        source: displayEvent.body,
      );
      if (displayEvent.messageType == MessageTypes.Emote) {
        html = '* $html';
      }
      replyBody = HtmlMessage(
        html: html,
        defaultTextStyle: ReplyContentStyle.replyBodyTextStyle(context),
        maxLines: 1,
        room: displayEvent.room,
        emoteSize: ReplyContentStyle.fontSizeDisplayContent * 1.5,
      );
    } else if (displayEvent.isAFile) {
      replyBody = Text(
        displayEvent.filename,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: ReplyContentStyle.replyBodyTextStyle(context),
      );
    } else {
      replyBody = Text(
        displayEvent.calcLocalizedBodyFallback(
          MatrixLocals(L10n.of(context)!),
          withSenderNamePrefix: false,
          hideReply: true,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: ReplyContentStyle.replyBodyTextStyle(context),
      );
    }
    final user = displayEvent.getUser();
    final quoteAlignment = this.quoteAlignment;
    if (quoteAlignment != null) {
      return _buildQuote(context, displayEvent, replyBody, quoteAlignment);
    }
    return Container(
      padding: ReplyContentStyle.replyParentContainerPadding,
      decoration: ReplyContentStyle.replyParentContainerDecoration(context),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              constraints: const BoxConstraints(
                minHeight: ReplyContentStyle.replyContentSize,
              ),
              width: ReplyContentStyle.prefixBarWidth,
              margin: const EdgeInsets.symmetric(
                vertical: ReplyContentStyle.prefixBarVerticalPadding,
              ),
              decoration: ReplyContentStyle.prefixBarDecoration(context),
            ),
            const SizedBox(width: ReplyContentStyle.contentSpacing),
            if (displayEvent.hasAttachment)
              Center(child: _previewIcon(displayEvent)),
            const SizedBox(width: ReplyContentStyle.contentSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (user != null)
                    Text(
                      user.calcDisplayname(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ReplyContentStyle.displayNameTextStyle(context),
                    ),
                  if (displayEvent.getUser() == null)
                    FutureBuilder<User?>(
                      future: displayEvent.fetchSenderUser(),
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data?.calcDisplayname() ?? displayEvent.senderFromMemoryOrFallback.calcDisplayname()}:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ReplyContentStyle.displayNameTextStyle(
                            context,
                          ),
                        );
                      },
                    ),
                  Expanded(child: replyBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewIcon(Event event) => OptionalSelectionContainerDisabled(
    isEnabled: PlatformInfos.isDesktop,
    child: ReplyPreviewIconBuilder(event: event),
  );

  Widget _buildQuote(
    BuildContext context,
    Event event,
    Widget body,
    CrossAxisAlignment alignment,
  ) {
    final user = event.getUser();
    final l10n = L10n.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      crossAxisAlignment: alignment,
      children: [
        Padding(
          padding: ReplyContentStyle.quoteCaptionPadding,
          child: FutureBuilder<User?>(
            future: user == null && !quoteSenderUnknown
                ? event.fetchSenderUser()
                : null,
            builder: (context, snapshot) {
              final style = ReplyContentStyle.quoteCaptionTextStyle(context);
              final name =
                  (user ?? snapshot.data ?? event.senderFromMemoryOrFallback)
                      .calcDisplayname();
              return Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: ReplyContentStyle.contentSpacing,
                        ),
                        child: Icon(
                          Icons.reply,
                          size: ReplyContentStyle.quoteCaptionIconSize,
                          color: style?.color,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: quoteSenderUnknown
                          ? l10n.reply
                          : l10n.replyToName(name),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              );
            },
          ),
        ),
        Container(
          padding: ReplyContentStyle.quoteBubblePadding.add(
            EdgeInsets.only(bottom: quoteOverlap),
          ),
          decoration: ReplyContentStyle.quoteBubbleDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.hasAttachment) ...[
                _previewIcon(event),
                const SizedBox(width: ReplyContentStyle.contentSpacing),
              ],
              Flexible(child: body),
            ],
          ),
        ),
      ],
    );
  }
}

class ReplyPreviewIconBuilder extends StatelessWidget {
  final Event event;

  const ReplyPreviewIconBuilder({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    if (event.messageType == MessageTypes.Video &&
        !event.isVideoAvailable &&
        event.mimeType != null) {
      return SvgPicture.asset(
        event.mimeType!.getIcon(fileType: event.fileType),
        width: ReplyContentStyle.replyContentSize,
        height: ReplyContentStyle.replyContentSize,
      );
    }
    if (event.isAFile) {
      return SvgPicture.asset(
        event.mimeType.getIcon(fileType: event.fileType),
        width: ReplyContentStyle.replyContentSize,
        height: ReplyContentStyle.replyContentSize,
      );
    }
    if (event.messageType == MessageTypes.Audio) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: ReplyContentStyle.previewedImageBorderRadius,
      child: MxcImage(
        key: ValueKey(event.eventId),
        noResize: true,
        event: event,
        width: ReplyContentStyle.replyContentSize,
        height: ReplyContentStyle.replyContentSize,
        isThumbnail: true,
        fit: BoxFit.cover,
        enableHeroAnimation: false,
        placeholder: (context) {
          return BlurHashPlaceHolder(event: event);
        },
      ),
    );
  }
}

class BlurHashPlaceHolder extends StatelessWidget {
  final Event event;

  const BlurHashPlaceHolder({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final String blurHashString =
        event.blurHash ?? AppConfig.defaultImageBlurHash;
    return SizedBox(
      width: ReplyContentStyle.replyContentSize,
      height: ReplyContentStyle.replyContentSize,
      child: BlurHashBackground(hash: blurHashString, fit: BoxFit.cover),
    );
  }
}
