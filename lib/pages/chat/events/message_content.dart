import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/chat/events/call_invite_content.dart';
import 'package:fluffychat/pages/chat/events/encrypted_content.dart';
import 'package:fluffychat/pages/chat/events/formatted_text_widget.dart';
import 'package:fluffychat/pages/chat/events/images_builder/message_content_image_builder.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/pages/chat/events/message_download_content_web.dart';
import 'package:fluffychat/pages/chat/events/message_upload_content.dart';
import 'package:fluffychat/pages/chat/events/message_video_download_content.dart';
import 'package:fluffychat/pages/chat/events/message_video_download_content_web.dart';
import 'package:fluffychat/pages/chat/events/message_video_upload_content.dart';
import 'package:fluffychat/pages/chat/events/sending_video_widget.dart';
import 'package:fluffychat/pages/chat/events/unknown_content.dart';
import 'package:fluffychat/pages/chat/optional_selection_container_disabled.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/extension/event_info_extension.dart';
import 'package:fluffychat/utils/extension/image_size_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/download_file_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/file_widget/message_file_tile_style.dart';
import 'package:fluffychat/widgets/mixins/handle_download_and_preview_file_mixin.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart' hide Visibility;

import 'audio_message/audio_player_widget.dart';
import 'cute_events.dart';
import 'map_bubble.dart';
import 'message_download_content.dart';
import 'sticker.dart';

class MessageContent extends StatelessWidget
    with HandleDownloadAndPreviewFileMixin {
  final Event event;
  final Color textColor;
  final Widget endOfBubbleWidget;
  final void Function()? onTapPreview;
  final void Function()? onTapSelectMode;
  final bool ownMessage;
  final Timeline timeline;
  final double? textWidth;

  const MessageContent(
    this.event, {
    super.key,
    required this.textColor,
    required this.endOfBubbleWidget,
    this.onTapPreview,
    this.onTapSelectMode,
    required this.ownMessage,
    required this.timeline,
    this.textWidth,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = AppConfig.messageFontSize * AppConfig.fontSizeFactor;
    switch (event.type) {
      case EventTypes.Encrypted:
        return EncryptedContent(event: event);
      case EventTypes.Message:
      case EventTypes.Sticker:
        switch (event.messageType) {
          case MessageTypes.Image:
            if (event.isCaptionModeOrReply()) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: MessageImageBuilder(
                      event: event,
                      onTapPreview: onTapPreview,
                      onTapSelectMode: onTapSelectMode,
                      maxWidth: MessageStyle.mediaContentWidth(
                        context: context,
                        event: event,
                        calculatedWidth: textWidth ?? 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (event.isBodyDiffersFromFilename())
                    SizedBox(
                      width: MessageStyle.messageBubbleWidthMediaCaption(
                        event: event,
                        context: context,
                        textWidth: textWidth,
                      ),
                      child: TwakeLinkPreview(
                        key: ValueKey('TwakeLinkPreview%${event.eventId}%'),
                        event: event,
                        localizedBody: event.body,
                        ownMessage: ownMessage,
                        fontSize: fontSize,
                        linkStyle: MessageContentStyle.linkStyleMessageContent(
                          context,
                        ),
                        richTextStyle: event.getMessageTextStyle(context),
                        isCaption: event.isCaptionModeOrReply(),
                      ),
                    ),
                ],
              );
            }
            return OptionalSelectionContainerDisabled(
              isEnabled: PlatformInfos.isWeb,
              child: MessageImageBuilder(
                event: event,
                onTapPreview: onTapPreview,
                onTapSelectMode: onTapSelectMode,
              ),
            );
          case MessageTypes.Sticker:
            if (event.redacted) continue textmessage;
            return OptionalSelectionContainerDisabled(
              isEnabled: PlatformInfos.isWeb,
              child: Sticker(event),
            );
          case CuteEventContent.eventType:
            return CuteContent(event);
          case MessageTypes.Audio:
            if (PlatformInfos.isMobile ||
                    PlatformInfos.isMacOS ||
                    PlatformInfos.isWeb
                // Disabled until https://github.com/bleonard252/just_audio_mpv/issues/3
                // is fixed
                //   || PlatformInfos.isLinux
                ) {
              return OptionalSelectionContainerDisabled(
                isEnabled: PlatformInfos.isWeb,
                child: AudioPlayerWidget(
                  event,
                  color: textColor,
                  timeline: timeline,
                ),
              );
            }
            return OptionalSelectionContainerDisabled(
              isEnabled: PlatformInfos.isWeb,
              child: MessageDownloadContent(
                event,
              ),
            );

          case MessageTypes.Video:
            if (event.isCaptionModeOrReply()) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.isVideoAvailable) ...[
                    OptionalSelectionContainerDisabled(
                      isEnabled: PlatformInfos.isWeb,
                      child: Align(
                        alignment: Alignment.center,
                        child: _MessageVideoBuilder(
                          event: event,
                          onFileTapped: (event) => onFileTapped(
                            context: context,
                            event: event,
                          ),
                          textWidth: textWidth,
                        ),
                      ),
                    ),
                  ] else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!PlatformInfos.isWeb) ...[
                          Align(
                            alignment: Alignment.center,
                            child: MessageDownloadContent(
                              event,
                            ),
                          ),
                        ] else ...[
                          OptionalSelectionContainerDisabled(
                            isEnabled: PlatformInfos.isWeb,
                            child: Align(
                              alignment: Alignment.center,
                              child: MessageDownloadContentWeb(
                                event,
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: MessageContentStyle.endOfBubbleWidgetPadding,
                          child: OptionalSelectionContainerDisabled(
                            isEnabled: PlatformInfos.isWeb,
                            child: Text.rich(
                              WidgetSpan(
                                child: endOfBubbleWidget,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  if (event.isBodyDiffersFromFilename())
                    SizedBox(
                      width: MessageStyle.messageBubbleWidthVideoCaption(
                        event: event,
                        context: context,
                        textWidth: textWidth,
                      ),
                      child: TwakeLinkPreview(
                        key: ValueKey('TwakeLinkPreview%${event.eventId}%'),
                        event: event,
                        localizedBody: event.body,
                        ownMessage: ownMessage,
                        fontSize: fontSize,
                        linkStyle: MessageContentStyle.linkStyleMessageContent(
                          context,
                        ),
                        richTextStyle: event.getMessageTextStyle(context),
                        isCaption: event.isCaptionModeOrReply(),
                      ),
                    ),
                ],
              );
            }
            if (event.isVideoAvailable) {
              return OptionalSelectionContainerDisabled(
                isEnabled: PlatformInfos.isWeb,
                child: _MessageVideoBuilder(
                  event: event,
                  onFileTapped: (event) => onFileTapped(
                    context: context,
                    event: event,
                  ),
                ),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!PlatformInfos.isWeb) ...[
                    MessageDownloadContent(
                      event,
                    ),
                  ] else ...[
                    OptionalSelectionContainerDisabled(
                      isEnabled: PlatformInfos.isWeb,
                      child: MessageDownloadContentWeb(
                        event,
                      ),
                    ),
                  ],
                  Padding(
                    padding: MessageContentStyle.endOfBubbleWidgetPadding,
                    child: OptionalSelectionContainerDisabled(
                      isEnabled: PlatformInfos.isWeb,
                      child: Text.rich(
                        WidgetSpan(
                          child: endOfBubbleWidget,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

          case MessageTypes.File:
            return Column(
              crossAxisAlignment: event.isCaptionModeOrReply()
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!PlatformInfos.isWeb) ...[
                  if (event.isSending()) ...[
                    MessageUploadingContent(
                      event: event,
                      style: const MessageFileTileStyle(),
                    ),
                  ] else
                    MessageDownloadContent(
                      event,
                    ),
                ] else ...[
                  if (event.isSending()) ...[
                    OptionalSelectionContainerDisabled(
                      isEnabled:
                          PlatformInfos.isWeb && !event.isCaptionModeOrReply(),
                      child: MessageUploadingContent(
                        event: event,
                        style: const MessageFileTileStyle(),
                      ),
                    ),
                  ] else
                    OptionalSelectionContainerDisabled(
                      isEnabled:
                          PlatformInfos.isWeb && !event.isCaptionModeOrReply(),
                      child: MessageDownloadContentWeb(
                        event,
                      ),
                    ),
                ],
                if (!event.isCaptionModeOrReply())
                  Padding(
                    padding: MessageContentStyle.endOfBubbleWidgetPadding,
                    child: OptionalSelectionContainerDisabled(
                      isEnabled: PlatformInfos.isWeb,
                      child: Text.rich(
                        WidgetSpan(
                          child: endOfBubbleWidget,
                        ),
                      ),
                    ),
                  ),
              ],
            );

          case MessageTypes.Text:
          case MessageTypes.Notice:
          case MessageTypes.Emote:
            final containedLink = event.text.getFirstValidUrl() ?? '';
            if (AppConfig.renderHtml &&
                !event.redacted &&
                event.isRichMessage &&
                containedLink.isEmpty) {
              return Padding(
                padding: MessageContentStyle.emojiPadding,
                child: FormattedTextWidget(
                  event: event,
                  linkStyle:
                      MessageContentStyle.linkStyleMessageContent(context),
                  fontSize: fontSize,
                ),
              );
            }
            // else we fall through to the normal message rendering
            continue textmessage;
          case MessageTypes.BadEncrypted:
          case EventTypes.Encrypted:
            return EncryptedContent(event: event);
          case MessageTypes.Location:
            final geoUri =
                Uri.tryParse(event.content.tryGet<String>('geo_uri')!);
            if (geoUri != null && geoUri.scheme == 'geo') {
              final latlong = geoUri.path
                  .split(';')
                  .first
                  .split(',')
                  .map((s) => double.tryParse(s))
                  .toList();
              if (latlong.length == 2 &&
                  latlong.first != null &&
                  latlong.last != null) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MapBubble(
                      latitude: latlong.first!,
                      longitude: latlong.last!,
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      icon: Icon(Icons.location_on_outlined, color: textColor),
                      onPressed: UrlLauncher(context, url: geoUri.toString())
                          .launchUrl,
                      label: Text(
                        L10n.of(context)!.openInMaps,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                );
              }
            }
            continue textmessage;
          case MessageTypes.None:
          textmessage:
          default:
            return FutureBuilder<String>(
              future: event.calcLocalizedBody(
                MatrixLocals(L10n.of(context)!),
                hideReply: true,
              ),
              builder: (context, snapshot) {
                final localizedBody = snapshot.data ??
                    event.calcLocalizedBodyFallback(
                      MatrixLocals(L10n.of(context)!),
                      hideReply: true,
                    );
                return TwakeLinkPreview(
                  key: ValueKey('TwakeLinkPreview%${event.eventId}%'),
                  event: event,
                  localizedBody: localizedBody,
                  ownMessage: ownMessage,
                  fontSize: fontSize,
                  linkStyle:
                      MessageContentStyle.linkStyleMessageContent(context),
                  richTextStyle: event.getMessageTextStyle(context),
                );
              },
            );
        }
      case EventTypes.CallInvite:
        return OptionalSelectionContainerDisabled(
          isEnabled: PlatformInfos.isWeb,
          child: CallInviteContent(event: event),
        );
      default:
        return OptionalSelectionContainerDisabled(
          isEnabled: PlatformInfos.isWeb,
          child: UnknownContent(event: event),
        );
    }
  }
}

class _MessageVideoBuilder extends StatelessWidget {
  final Event event;
  final double? textWidth;

  final void Function(Event event) onFileTapped;

  const _MessageVideoBuilder({
    required this.event,
    required this.onFileTapped,
    this.textWidth,
  });

  @override
  Widget build(BuildContext context) {
    final matrixFile = event.getMatrixFile();

    DisplayImageInfo? displayImageInfo =
        event.getOriginalResolution()?.getDisplayImageInfo(context);

    if (isSendingVideo(matrixFile)) {
      final file = matrixFile as MatrixVideoFile;
      displayImageInfo = Size(
        file.width?.toDouble() ?? MessageContentStyle.imageWidth(context),
        file.height?.toDouble() ?? MessageContentStyle.imageHeight(context),
      ).getDisplayImageInfo(context);
      return SendingVideoWidget(
        key: ValueKey(event.eventId),
        event: event,
        matrixFile: matrixFile,
        displayImageInfo: displayImageInfo,
        bubbleWidth: textWidth,
      );
    }

    displayImageInfo ??= DisplayImageInfo(
      size: Size(
        MessageContentStyle.imageWidth(context),
        MessageContentStyle.imageHeight(context),
      ),
      hasBlur: true,
    );

    if (PlatformInfos.isWeb) {
      if (event.isSending()) {
        return MessageVideoUploadContentWeb(
          event: event,
          width: displayImageInfo.size.width,
          height: displayImageInfo.size.height,
          bubbleWidth: textWidth,
        );
      }
      return MessageVideoDownloadContentWeb(
        event: event,
        width: displayImageInfo.size.width,
        height: displayImageInfo.size.height,
        bubbleWidth: textWidth,
      );
    }
    return MessageVideoDownloadContent(
      event: event,
      width: displayImageInfo.size.width,
      height: displayImageInfo.size.height,
      bubbleWidth: textWidth,
    );
  }

  bool isSendingVideo(MatrixFile? matrixFile) {
    return matrixFile is MatrixVideoFile;
  }
}
