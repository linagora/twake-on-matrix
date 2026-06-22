import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/pages/chat/events/message_content_style.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/chat/upload_file_ui_state.dart';
import 'package:fluffychat/presentation/model/file/display_image_info.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/extension/image_size_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:fluffychat/widgets/mixins/upload_file_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class SendingVideoWidget extends StatefulWidget {
  final Event event;

  final DisplayImageInfo displayImageInfo;

  final double? bubbleWidth;

  const SendingVideoWidget({
    super.key,
    required this.event,
    required this.displayImageInfo,
    this.bubbleWidth,
  });

  @override
  State<SendingVideoWidget> createState() => _SendingVideoWidgetState();
}

class _SendingVideoWidgetState extends State<SendingVideoWidget>
    with PlayVideoActionMixin, UploadFileMixin {
  @override
  Event get event => widget.event;

  late DisplayImageInfo _displayImageInfo;
  Uint8List? _thumbnailBytes;

  @override
  void initState() {
    super.initState();
    _displayImageInfo = widget.displayImageInfo;
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final thumbnail = await widget.event.getPlaceholderMatrixImageFile(
      getIt.get<UploadManager>(),
    );
    if (thumbnail == null || !mounted) return;

    final codec = await ui.instantiateImageCodec(thumbnail.bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final realSize = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    if (!mounted) return;

    setState(() {
      _thumbnailBytes = thumbnail.bytes;
      _displayImageInfo = realSize.getDisplayImageInfo(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    final imageWidth = _displayImageInfo.size.width;
    final imageHeight = _displayImageInfo.size.height;
    final maxWidth =
        MessageContentStyle.combinedBubbleImageWidthWithBubbleMaxWidget(
          bubbleImageWidget: imageWidth,
          bubbleMaxWidth: widget.bubbleWidth ?? 0,
        );
    final bubbleHeight = MessageContentStyle.videoBubbleHeight(imageHeight);

    return ClipRRect(
      borderRadius: MessageContentStyle.borderRadiusBubble,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: MessageStyle.mediaContentWidth(
              context: context,
              event: event,
              calculatedWidth: maxWidth,
            ),
            height: bubbleHeight,
            child: const BlurHash(hash: MessageContentStyle.defaultBlurHash),
          ),
          if (_thumbnailBytes != null)
            Image.memory(
              _thumbnailBytes!,
              width: MessageContentStyle.imageBubbleWidth(imageWidth),
              height: bubbleHeight,
              cacheWidth: context.getCacheSize(
                MessageContentStyle.imageBubbleWidth(imageWidth),
              ),
              cacheHeight: context.getCacheSize(bubbleHeight),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ...switch (event.status) {
            EventStatus.error => [
              IconButton(
                onPressed: () {
                  uploadManager.retryUpload(event);
                },
                icon: Icon(Icons.refresh, color: sysColor.primary, size: 24),
                padding: const EdgeInsets.all(4),
                style: IconButton.styleFrom(
                  backgroundColor: sysColor.onPrimary,
                  shape: const CircleBorder(),
                ),
              ),
            ],
            _ => [
              Container(
                width: MessageContentStyle.videoCenterButtonSize,
                height: MessageContentStyle.videoCenterButtonSize,
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.close,
                  color: LinagoraRefColors.material().primary[100],
                  size: MessageContentStyle.iconInsideVideoButtonSize,
                ),
              ),
              ValueListenableBuilder(
                valueListenable: uploadFileStateNotifier,
                builder: (context, state, child) {
                  int? receive, total;
                  double? progress;
                  if (state is UploadingFileUIState) {
                    receive = state.receive;
                    total = state.total;
                  }
                  if (receive != null && total != null && total > 0) {
                    progress = receive / total;
                  }
                  return InkWell(
                    onTap: () {
                      if (state is UploadFileSuccessUIState) {
                        return;
                      }
                      uploadManager.cancelUpload(event);
                    },
                    child: SizedBox(
                      width: MessageContentStyle.videoCenterButtonSize,
                      height: MessageContentStyle.videoCenterButtonSize,
                      child: CircularProgressIndicator(
                        strokeWidth: MessageContentStyle.strokeVideoWidth,
                        color: LinagoraRefColors.material().primary[100],
                        value: progress,
                      ),
                    ),
                  );
                },
              ),
            ],
          },
        ],
      ),
    );
  }
}

enum SendingVideoStatus { sending, sent, error }
