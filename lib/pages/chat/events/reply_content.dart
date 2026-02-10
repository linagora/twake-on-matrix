import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/reply_content_style.dart';
import 'package:fluffychat/pages/chat/optional_selection_container_disabled.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/extension/event_info_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
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
    return Container(
      padding: ReplyContentStyle.replyParentContainerPadding,
      decoration: ReplyContentStyle.replyParentContainerDecoration(
        context,
        ownMessage,
      ),
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
              Center(
                child: OptionalSelectionContainerDisabled(
                  isEnabled: PlatformInfos.isWeb,
                  child: ReplyPreviewIconBuilder(event: displayEvent),
                ),
              ),
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
        event.mimeType?.getIcon(fileType: event.fileType) ??
            ImagePaths.icFileUnknown,
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
      child: BlurHash(hash: blurHashString, imageFit: BoxFit.cover),
    );
  }
}
