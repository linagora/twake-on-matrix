import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/reply_content_style.dart';
import 'package:fluffychat/utils/extension/event_info_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'html_message.dart';

class ReplyContent extends StatelessWidget {
  final Event replyEvent;
  final bool ownMessage;
  final Timeline? timeline;

  const ReplyContent(
    this.replyEvent, {
    this.ownMessage = false,
    super.key,
    this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    Widget replyBody;
    final timeline = this.timeline;
    final displayEvent =
        timeline != null ? replyEvent.getDisplayEvent(timeline) : replyEvent;
    if (AppConfig.renderHtml &&
        [EventTypes.Message, EventTypes.Encrypted]
            .contains(displayEvent.type) &&
        [MessageTypes.Text, MessageTypes.Notice, MessageTypes.Emote]
            .contains(displayEvent.messageType) &&
        !displayEvent.redacted &&
        displayEvent.content['format'] == 'org.matrix.custom.html' &&
        displayEvent.content['formatted_body'] is String) {
      String? html = (displayEvent.content['formatted_body'] as String?);
      if (displayEvent.messageType == MessageTypes.Emote) {
        html = '* $html';
      }
      replyBody = HtmlMessage(
        html: html!,
        defaultTextStyle: ReplyContentStyle.replyBodyTextStyle(context),
        maxLines: 1,
        room: displayEvent.room,
        emoteSize: ReplyContentStyle.fontSizeDisplayContent * 1.5,
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
    return Container(
      padding: ReplyContentStyle.replyParentContainerPadding,
      decoration:
          ReplyContentStyle.replyParentContainerDecoration(context, ownMessage),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ReplyContentStyle.prefixBarVerticalPadding,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: ReplyContentStyle.replyContentSize,
                ),
                width: ReplyContentStyle.prefixBarWidth,
                decoration: ReplyContentStyle.prefixBarDecoration(context),
              ),
            ),
            const SizedBox(width: ReplyContentStyle.contentSpacing),
            if (displayEvent.hasAttachment)
              Center(
                child: ReplyPreviewIconBuilder(
                  event: displayEvent,
                ),
              ),
            const SizedBox(
              width: ReplyContentStyle.contentSpacing,
            ),
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
                          style:
                              ReplyContentStyle.displayNameTextStyle(context),
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
}

class ReplyPreviewIconBuilder extends StatelessWidget {
  final Event event;

  const ReplyPreviewIconBuilder({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    if (event.messageType == MessageTypes.Video &&
        !event.isVideoAvailable &&
        event.mimeType != null) {
      return SvgPicture.asset(
        event.mimeType!.getIcon(
          fileType: event.fileType,
        ),
        width: ReplyContentStyle.replyContentSize,
        height: ReplyContentStyle.replyContentSize,
      );
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
        placeholder: (context) {
          return BlurHashPlaceHolder(
            event: event,
          );
        },
      ),
    );
  }
}

class BlurHashPlaceHolder extends StatelessWidget {
  final Event event;

  const BlurHashPlaceHolder({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final String blurHashString =
        event.blurHash ?? AppConfig.defaultImageBlurHash;
    return SizedBox(
      width: ReplyContentStyle.replyContentSize,
      height: ReplyContentStyle.replyContentSize,
      child: BlurHash(
        hash: blurHashString,
        imageFit: BoxFit.cover,
      ),
    );
  }
}
